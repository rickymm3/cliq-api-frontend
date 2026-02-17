# frozen_string_literal: true

require "securerandom"

ActiveRecord::Base.transaction do
  puts "== Seeding (Rails #{Rails.version}) =="

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------
  def reset_pk!(table_name)
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")

    ActiveRecord::Base.connection.reset_pk_sequence!(table_name)
  rescue StandardError
    # no-op if table doesn't exist or reset not supported
  end

  def safe_delete_all(klass)
    klass.delete_all
  rescue NameError
    # model not present in this app
  end

  def slugify(text)
    base = text.to_s.parameterize
    suffix = SecureRandom.hex(3)
    [base, suffix].reject(&:empty?).join("-")
  end

  def random_time_within(days_back)
    now = Time.current
    seconds = rand(0..(days_back * 24 * 60 * 60))
    now - seconds
  end

  def build_post_copy(index, cliq_name, topic_a, topic_b)
    case index
    when 0
      title = "#{cliq_name}: Quick-start for #{topic_a}"
      body = "I wanted a fast path to get #{topic_a} feeling smooth in #{cliq_name}. I set a 30-minute baseline, tracked friction points, and kept a tiny notes log. The biggest win was simplifying #{topic_b}. If you had to pick one checkpoint, what would it be?"
    when 1
      title = "What do you use for #{topic_a} in #{cliq_name}?"
      body = "Curious what the go-to setup is for #{topic_a} here. I'm comparing a lean approach vs a deeper system and timing the results. Any tools or habits that keep #{topic_b} from drifting?"
    when 2
      title = "Two-week experiment: #{topic_a} vs #{topic_b}"
      body = "Running a short experiment in #{cliq_name} to see how #{topic_a} stacks up against #{topic_b}. I picked one metric, logged daily changes, and forced a short review every third day. Early signal: consistency beats complexity. What would you measure?"
    when 3
      title = "Mistakes I made with #{topic_a} (so you don't have to)"
      body = "I over-optimized #{topic_a} and ignored the basics. That made #{topic_b} wobble and the whole flow slowed down. Resetting to a smaller scope fixed it fast. What's the first thing you'd simplify?"
    else
      title = "Checklist share: #{topic_a} in #{cliq_name}"
      body = "I'm building a simple checklist for #{topic_a}. Right now it’s: define the goal, set a 15-minute test, log results, and review against #{topic_b}. If you have a step that always saves time, drop it in."
    end

    [title, body]
  end

  def build_reply_copy(post_title:, post_body:, topics:, stance: nil)
    keywords = Array(topics).compact
    fallback = post_title.to_s.split(/\W+/).map(&:downcase).reject { |w| w.length < 4 }.uniq
    keywords = (keywords + fallback).uniq

    k1 = keywords.sample || "that"
    k2 = (keywords - [k1]).sample || k1
    k3 = (keywords - [k1, k2]).sample || k2

    stance ||= %i[agree question suggest counterpoint anecdote].sample
    reply = case stance
            when :agree
              [
                "Agreed on #{k1}. The framing in \"#{post_title}\" matches what I have seen too.",
                "Same here. When #{k2} is steady, the rest tends to line up.",
                "This resonates. #{k1.capitalize} is the lever I keep coming back to."
              ].sample
            when :question
              [
                "When you say #{k1}, do you mean the first step or the overall approach?",
                "How are you measuring #{k2} right now? Any quick metric?",
                "What part of #{k3} feels hardest to keep consistent?"
              ].sample
            when :suggest
              [
                "Suggestion: try a tiny baseline for #{k1}, then adjust one variable each week.",
                "If #{k2} is the goal, a short checklist and a weekly review might help.",
                "One tweak that helped me was narrowing #{k3} down to a single test."
              ].sample
            when :counterpoint
              [
                "I mostly agree, but I wonder if #{k1} is less important than #{k2}.",
                "Counterpoint: #{k3} might be the real bottleneck here.",
                "This is solid, though I have seen #{k2} backfire when pushed too early."
              ].sample
            else
              [
                "This reminds me of a similar setup I tried last quarter. #{k1} made the biggest difference.",
                "I ran a similar experiment and the surprise was how much #{k2} mattered.",
                "Anecdote: when I focused on #{k3} first, everything else clicked faster."
              ].sample
            end

    body_text = post_body.to_s.gsub(/\s+/, " ").strip
    if body_text.length >= 60 && rand < 0.3
      fragment = body_text[0, 70]
      reply = "#{reply} (Reference: \"#{fragment}...\")"
    end

    reply
  end

  def topics_with_name(base_topics, name)
    name_topics = name.to_s.downcase.scan(/[a-z0-9]+/).select { |token| token.length > 2 }
    (Array(base_topics) + name_topics).uniq
  end

  def next_rank_for(parent, counters)
    counters[parent.id] += 1
  end

  def create_child_cliq!(name:, description:, parent:, topics:, sub_cliqs:, rank_counters:)
    cliq = Cliq.find_by(name: name, parent_cliq_id: parent.id)

    unless cliq
      cliq = Cliq.create!(
        name: name,
        description: description,
        parent_cliq_id: parent.id,
        rank: next_rank_for(parent, rank_counters),
        slug: slugify("#{parent.name}-#{name}")
      )
    end

    if topics && !topics.empty?
      exists_in_list = sub_cliqs.any? { |entry| entry[:cliq].id == cliq.id }
      sub_cliqs << { cliq: cliq, topics: topics } unless exists_in_list
    end
    cliq
  end

  # ---------------------------------------------------------------------------
  # Clear data (order matters)
  # ---------------------------------------------------------------------------
  puts "Clearing existing data..."

  begin
    ActionText::RichText.where(record_type: ["Post", "Reply"]).delete_all
  rescue StandardError => e
    puts "Note: ActionText cleanup skipped or failed: #{e.message}"
  end

  safe_delete_all(PostSignal)
  safe_delete_all(PostInteraction)
  safe_delete_all(DirectMessage)
  safe_delete_all(DirectMessageConversation)
  safe_delete_all(Reply)
  safe_delete_all(Post)
  safe_delete_all(Subscription)
  safe_delete_all(ModeratorRole)
  safe_delete_all(FollowedUser)
  safe_delete_all(Notification)
  safe_delete_all(Report)
  safe_delete_all(JwtDenylist)
  safe_delete_all(Cliq)
  safe_delete_all(User)

  %w[
    action_text_rich_texts
    post_signals post_interactions direct_messages direct_message_conversations replies posts
    subscriptions moderator_roles followed_users notifications reports jwt_denylists
    cliqs users
  ].each { |t| reset_pk!(t) }

  # ---------------------------------------------------------------------------
  # Users
  # ---------------------------------------------------------------------------
  puts "Creating users..."

  first_names = %w[
    Avery Blake Casey Devon Ellis Frankie Gray Harley Indie Jalen
    Jules Kai Lane Marley Nico Oakley Parker Quinn Reese Rowan
    Sage Sawyer Shay Tate Tyler Wren Zuri
  ]
  last_names = %w[
    Adler Banks Carter Dawson Ellis Foster Gray Hayes Ivers
    Jensen Keller Lang Mercer Nolan Oakley Pierce Quinn Reed
    Sawyer Taylor Underwood Vale Wilder York
  ]

  users = Array.new(24) do |index|
    first = first_names.sample
    last = last_names.sample
    email = "#{first.downcase}.#{last.downcase}#{index + 1}@cliq.test"

    User.create!(
      email: email,
      password: "password123!",
      password_confirmation: "password123!"
    )
  end

  # ---------------------------------------------------------------------------
  # Cliqs
  # ---------------------------------------------------------------------------
  puts "Creating cliqs..."

  master_root = Cliq.create!(
    name: "Cliq",
    description: "The hub for all cliqs.",
    parent_cliq_id: nil,
    rank: 0,
    slug: "root"
  )

  main_cliqs_data = [
    { name: "Entertainment", description: "Movies, shows, music, and fandom." },
    { name: "Gaming", description: "Video games, tabletop, and design." },
    { name: "Sci/Tech", description: "Science, software, and emerging tech." },
    { name: "Politics", description: "Policy, civics, and current events." },
    { name: "Life", description: "Home, wellness, and personal systems." }
  ]

  main_cliqs = main_cliqs_data.each_with_index.map do |cliq_data, index|
    Cliq.create!(
      name: cliq_data[:name],
      description: cliq_data[:description],
      parent_cliq_id: master_root.id,
      rank: index + 1,
      slug: slugify(cliq_data[:name])
    )
  end

  main_by_name = main_cliqs.index_by(&:name)
  sub_cliqs = []
  rank_counters = Hash.new(0)

  entertainment = main_by_name.fetch("Entertainment")
  gaming = main_by_name.fetch("Gaming")
  sci_tech = main_by_name.fetch("Sci/Tech")
  politics = main_by_name.fetch("Politics")
  life = main_by_name.fetch("Life")

  entertainment_categories = [
    {
      name: "Anime",
      description: "Series, seasons, studios, and fandom.",
      topics: %w[episodes seasons studios genres],
      children: [
        "Shonen", "Seinen", "Shojo", "Josei", "Isekai", "Mecha",
        "Sports", "Slice of Life", "Fantasy", "Sci-Fi", "Romance",
        "Horror", "Comedy", "Mystery", "Historical", "OVA", "Movies", "Seasonal"
      ]
    },
    {
      name: "Manga",
      description: "Serialization, art styles, and volumes.",
      topics: %w[chapters volumes art panels],
      children: [
        "Shonen", "Seinen", "Shojo", "Josei", "Web Manga", "One-Shots",
        "Slice of Life", "Romance", "Sports", "Fantasy", "Sci-Fi",
        "Horror", "Mystery", "Historical"
      ]
    },
    {
      name: "Live Action",
      description: "Adaptations, casting, and production.",
      topics: %w[adaptations casting production remakes],
      children: [
        "Adaptations", "Casting", "Showrunners", "Production",
        "Remakes", "Cinematography", "Practical Effects", "Stunts"
      ]
    },
    {
      name: "Movies",
      description: "Theatrical releases and film culture.",
      topics: %w[cinema releases trailers reviews],
      children: [
        "Action", "Drama", "Comedy", "Horror", "Thriller", "Sci-Fi",
        "Fantasy", "Animation", "Documentary", "Indie", "International",
        "Classic", "Family"
      ]
    },
    {
      name: "TV Series",
      description: "Seasons, showrunners, and streaming drops.",
      topics: %w[episodes seasons showrunners streaming],
      children: [
        "Drama", "Comedy", "Sci-Fi", "Reality", "Limited Series",
        "Crime", "Fantasy", "Sitcoms", "Animation", "International"
      ]
    },
    {
      name: "Animation",
      description: "Styles, studios, and technique.",
      topics: %w[animation studios style shorts],
      children: [
        "Western Animation", "Adult Animation", "Family Animation", "Shorts",
        "Stop Motion", "CGI", "Traditional", "Experimental"
      ]
    },
    {
      name: "Comics",
      description: "Issues, arcs, and creators.",
      topics: %w[issues arcs writers artists],
      children: [
        "Marvel", "DC", "Indie", "Graphic Novels", "Webcomics",
        "Manga", "Collected Editions", "Creator-Owned"
      ]
    },
    {
      name: "Genres",
      description: "Themes, tone, and pacing.",
      topics: %w[action drama comedy horror],
      children: [
        "Action", "Adventure", "Comedy", "Drama", "Horror", "Thriller",
        "Mystery", "Romance", "Sci-Fi", "Fantasy", "Historical", "Crime",
        "Noir", "Western", "Animation", "Family", "Slice of Life",
        "Coming of Age", "Sports", "Musical", "Documentary", "Biopic",
        "Satire", "Psychological"
      ]
    },
    {
      name: "Studios",
      description: "Production houses and creative teams.",
      topics: %w[studios production animation],
      children: [
        "Studio Ghibli", "MAPPA", "Toei Animation", "Bones", "Wit Studio",
        "Ufotable", "Pixar", "Disney", "DreamWorks", "A24",
        "Warner Bros", "Universal", "Paramount", "Sony Pictures", "Netflix Studios",
        "HBO", "BBC", "Amazon Studios", "Lionsgate", "Annapurna"
      ]
    },
    {
      name: "Streaming",
      description: "Platforms, originals, and weekly drops.",
      topics: %w[platforms originals releases],
      children: [
        "Netflix", "Hulu", "Disney Plus", "Max", "Prime Video",
        "Apple TV Plus", "Crunchyroll", "Paramount Plus",
        "Peacock", "YouTube", "Tubi", "Pluto TV"
      ]
    },
    {
      name: "Awards",
      description: "Ceremonies, nominations, and wins.",
      topics: %w[awards nominations ceremonies],
      children: [
        "Oscars", "Emmys", "Golden Globes", "BAFTA", "SAG Awards",
        "Critics Choice", "Anime Awards", "Grammy",
        "Cannes", "Sundance", "Venice", "Toronto Film Fest"
      ]
    },
    {
      name: "Soundtracks",
      description: "Scores, themes, and composers.",
      topics: %w[scores ost composers],
      children: [
        "Scores", "Original Songs", "Opening Themes", "Ending Themes",
        "Composers", "Vinyl Releases", "Live Performances", "Playlists"
      ]
    },
    {
      name: "Fandom",
      description: "Communities, theories, and creations.",
      topics: %w[cosplay conventions fanart],
      children: [
        "Cosplay", "Conventions", "Fan Art", "Fan Fiction",
        "Theories", "Memes", "Collectors", "Online Communities"
      ]
    },
    {
      name: "Franchises",
      description: "Universes, timelines, and canon.",
      topics: %w[universes canon timelines],
      children: []
    }
  ]

  entertainment_nodes = {}
  entertainment_categories.each do |category|
    parent = create_child_cliq!(
      name: category[:name],
      description: category[:description],
      parent: entertainment,
      topics: category[:topics],
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    entertainment_nodes[category[:name]] = parent

    Array(category[:children]).each do |child_name|
      create_child_cliq!(
        name: child_name,
        description: "#{child_name} discussions within #{category[:name]}.",
        parent: parent,
        topics: topics_with_name(category[:topics], child_name),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end
  end

  franchise_topics = %w[characters arcs lore theories]
  franchise_anime_topics = %w[episodes seasons animation studios]
  franchise_manga_topics = %w[chapters volumes art panels]
  franchise_live_action_topics = %w[casting adaptation episodes production]
  franchise_movie_topics = %w[trailers boxoffice reviews]

  anime_parent = entertainment_nodes.fetch("Anime")
  manga_parent = entertainment_nodes.fetch("Manga")
  live_action_parent = entertainment_nodes.fetch("Live Action")
  movies_parent = entertainment_nodes.fetch("Movies")
  tv_parent = entertainment_nodes.fetch("TV Series")
  franchises_parent = entertainment_nodes.fetch("Franchises")

  anime_franchises = [
    "One Piece", "Naruto", "Bleach", "Dragon Ball", "Attack on Titan",
    "My Hero Academia", "Demon Slayer", "Jujutsu Kaisen", "Fullmetal Alchemist",
    "Hunter x Hunter", "One Punch Man", "JoJo's Bizarre Adventure",
    "Death Note", "Haikyuu", "Sailor Moon", "Neon Genesis Evangelion",
    "Cowboy Bebop", "Spy x Family", "Chainsaw Man", "Black Clover",
    "Fairy Tail", "Tokyo Ghoul", "Code Geass", "Mob Psycho 100",
    "Steins Gate", "The Promised Neverland", "Dr. Stone", "Re Zero",
    "Vinland Saga", "Blue Lock"
  ]

  general_franchises = [
    "Marvel", "Star Wars", "Harry Potter", "Lord of the Rings",
    "Star Trek", "James Bond", "DC Comics", "Spider-Man",
    "Batman", "Mission Impossible", "Fast and Furious",
    "Jurassic Park", "The Matrix", "Transformers",
    "The Witcher", "Game of Thrones", "The Walking Dead",
    "Stranger Things", "Avatar", "The Hobbit"
  ]

  anime_franchises.each do |franchise|
    franchise_root = create_child_cliq!(
      name: franchise,
      description: "All things #{franchise}.",
      parent: entertainment,
      topics: topics_with_name(franchise_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )

    %w[Anime Manga Live Action Movies Characters Arcs Theories].each do |child_name|
      child_topics = case child_name
                     when "Anime" then franchise_anime_topics
                     when "Manga" then franchise_manga_topics
                     when "Live Action" then franchise_live_action_topics
                     when "Movies" then franchise_movie_topics
                     else franchise_topics
                     end

      create_child_cliq!(
        name: child_name,
        description: "#{franchise} #{child_name} discussions.",
        parent: franchise_root,
        topics: topics_with_name(child_topics, franchise),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end

    create_child_cliq!(
      name: franchise,
      description: "#{franchise} anime focus.",
      parent: anime_parent,
      topics: topics_with_name(franchise_anime_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    create_child_cliq!(
      name: franchise,
      description: "#{franchise} manga focus.",
      parent: manga_parent,
      topics: topics_with_name(franchise_manga_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    create_child_cliq!(
      name: franchise,
      description: "#{franchise} live action focus.",
      parent: live_action_parent,
      topics: topics_with_name(franchise_live_action_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    create_child_cliq!(
      name: franchise,
      description: "#{franchise} franchise hub.",
      parent: franchises_parent,
      topics: topics_with_name(franchise_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  general_franchises.each do |franchise|
    franchise_root = create_child_cliq!(
      name: franchise,
      description: "All things #{franchise}.",
      parent: entertainment,
      topics: topics_with_name(franchise_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )

    %w[Movies TV Series Characters Arcs Theories].each do |child_name|
      child_topics = case child_name
                     when "Movies" then franchise_movie_topics
                     when "TV Series" then %w[episodes seasons streaming]
                     else franchise_topics
                     end

      create_child_cliq!(
        name: child_name,
        description: "#{franchise} #{child_name} discussions.",
        parent: franchise_root,
        topics: topics_with_name(child_topics, franchise),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end

    create_child_cliq!(
      name: franchise,
      description: "#{franchise} movie focus.",
      parent: movies_parent,
      topics: topics_with_name(franchise_movie_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    create_child_cliq!(
      name: franchise,
      description: "#{franchise} TV focus.",
      parent: tv_parent,
      topics: topics_with_name(%w[episodes seasons streaming], franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    create_child_cliq!(
      name: franchise,
      description: "#{franchise} franchise hub.",
      parent: franchises_parent,
      topics: topics_with_name(franchise_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  # ---------------------------------------------------------------------------
  # Gaming cliqs (expanded)
  # ---------------------------------------------------------------------------
  gaming_categories = [
    {
      name: "Platforms",
      description: "Where you play.",
      topics: %w[platforms hardware performance releases],
      children: [
        "PC", "PlayStation", "Xbox", "Nintendo", "Switch", "Steam Deck",
        "Mobile", "VR", "Cloud Gaming", "Retro"
      ]
    },
    {
      name: "Genres",
      description: "Styles, mechanics, and pacing.",
      topics: %w[genres mechanics pacing],
      children: [
        "RPG", "JRPG", "Action", "Adventure", "Shooter", "Tactical",
        "Strategy", "Simulation", "Sandbox", "Platformer", "Roguelike",
        "Roguelite", "Metroidvania", "Puzzle", "Horror", "Survival",
        "Sports", "Racing", "Fighting", "MOBA", "MMO", "Co-op",
        "Battle Royale", "Card Games", "Rhythm", "City Builder"
      ]
    },
    {
      name: "Multiplayer",
      description: "Matchmaking, coordination, and metas.",
      topics: %w[ranked matchmaking coordination meta],
      children: [
        "Ranked", "Casual", "Co-op", "Competitive", "LFG",
        "Clans & Guilds", "Tournaments", "Crossplay"
      ]
    },
    {
      name: "Esports",
      description: "Teams, events, and analysis.",
      topics: %w[teams tournaments meta strategy],
      children: [
        "League of Legends", "Valorant", "CS2", "Dota 2",
        "Overwatch", "Rocket League", "Fortnite", "Apex Legends",
        "PUBG", "Call of Duty", "Rainbow Six", "Fighting Games",
        "Smash", "StarCraft"
      ]
    },
    {
      name: "Hardware & Gear",
      description: "PC parts, peripherals, and setups.",
      topics: %w[hardware peripherals setups latency],
      children: [
        "GPUs", "CPUs", "Monitors", "Controllers", "Keyboards",
        "Mice", "Headsets", "Streaming Gear", "Ergonomics",
        "Networking", "Storage"
      ]
    },
    {
      name: "Game Design",
      description: "Systems, balance, and player experience.",
      topics: %w[systems balance progression ux],
      children: [
        "Level Design", "Combat Systems", "Progression",
        "Economy Design", "Narrative Design", "UX & UI",
        "Difficulty", "Onboarding", "Accessibility"
      ]
    },
    {
      name: "Indie Scene",
      description: "Small teams, big ideas.",
      topics: %w[indie discovery showcases],
      children: [
        "Hidden Gems", "Early Access", "Game Jams",
        "Itch.io", "Steam Next Fest", "Kickstarter"
      ]
    },
    {
      name: "Mods & Community",
      description: "Custom content and community tools.",
      topics: %w[mods community tools],
      children: [
        "Modding Tools", "Skins", "Map Editors", "Servers",
        "Roleplay", "Custom Rulesets"
      ]
    },
    {
      name: "Speedrunning",
      description: "Routes, splits, and records.",
      topics: %w[routes splits records],
      children: [
        "Any%", "100%", "Glitchless", "Randomizers",
        "Time Trials", "ILs"
      ]
    },
    {
      name: "Streaming & Content",
      description: "Creators, clips, and highlights.",
      topics: %w[streaming creators highlights],
      children: [
        "Twitch", "YouTube", "Highlights", "Co-streams",
        "VOD Reviews", "Clips & Memes"
      ]
    }
  ]

  gaming_nodes = {}
  gaming_categories.each do |category|
    parent = create_child_cliq!(
      name: category[:name],
      description: category[:description],
      parent: gaming,
      topics: category[:topics],
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    gaming_nodes[category[:name]] = parent

    Array(category[:children]).each do |child_name|
      create_child_cliq!(
        name: child_name,
        description: "#{child_name} discussions within #{category[:name]}.",
        parent: parent,
        topics: topics_with_name(category[:topics], child_name),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end
  end

  franchise_topics = %w[meta builds patches balance]
  franchise_action_topics = %w[combat movement aiming]
  franchise_story_topics = %w[story characters lore]

  gaming_franchises = [
    "The Legend of Zelda", "Mario", "Pokemon", "Final Fantasy",
    "Elden Ring", "Dark Souls", "Sekiro", "Bloodborne",
    "Call of Duty", "Battlefield", "Halo", "Destiny",
    "World of Warcraft", "Diablo", "Path of Exile",
    "The Witcher", "Cyberpunk 2077", "Baldur's Gate",
    "Mass Effect", "Dragon Age", "Assassin's Creed",
    "Far Cry", "Grand Theft Auto", "Red Dead Redemption",
    "The Elder Scrolls", "Fallout", "Resident Evil",
    "Silent Hill", "Metal Gear", "Monster Hunter",
    "Street Fighter", "Tekken", "Mortal Kombat",
    "Super Smash Bros", "Overwatch", "Valorant",
    "Apex Legends", "Fortnite", "Rocket League",
    "Minecraft", "Roblox", "Stardew Valley",
    "Hades", "Hollow Knight", "Celeste", "Terraria",
    "Among Us", "Splatoon", "Animal Crossing",
    "Kingdom Hearts", "Persona", "Fire Emblem",
    "Genshin Impact", "Honkai Star Rail"
  ]

  genres_parent = gaming_nodes.fetch("Genres")
  platforms_parent = gaming_nodes.fetch("Platforms")
  multiplayer_parent = gaming_nodes.fetch("Multiplayer")
  esports_parent = gaming_nodes.fetch("Esports")
  design_parent = gaming_nodes.fetch("Game Design")

  gaming_franchises.each do |franchise|
    franchise_root = create_child_cliq!(
      name: franchise,
      description: "All things #{franchise}.",
      parent: gaming,
      topics: topics_with_name(franchise_topics, franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )

    %w[Guides Builds Story Competitive Updates].each do |child_name|
      child_topics = case child_name
                     when "Guides" then franchise_topics
                     when "Builds" then %w[builds loadouts stats]
                     when "Story" then franchise_story_topics
                     when "Competitive" then %w[ranked tournaments meta]
                     else %w[patches balance events]
                     end

      create_child_cliq!(
        name: child_name,
        description: "#{franchise} #{child_name} discussions.",
        parent: franchise_root,
        topics: topics_with_name(child_topics, franchise),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end

    create_child_cliq!(
      name: franchise,
      description: "#{franchise} competitive focus.",
      parent: multiplayer_parent,
      topics: topics_with_name(%w[ranked coordination meta], franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )

    create_child_cliq!(
      name: franchise,
      description: "#{franchise} design discussion.",
      parent: design_parent,
      topics: topics_with_name(%w[systems balance pacing], franchise),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  %w[RPG JRPG Shooter Strategy Simulation].each do |genre|
    create_child_cliq!(
      name: genre,
      description: "#{genre} game discussions.",
      parent: genres_parent,
      topics: topics_with_name(%w[mechanics progression], genre),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  %w[PC PlayStation Xbox Nintendo Switch Mobile].each do |platform|
    create_child_cliq!(
      name: platform,
      description: "#{platform} focused games and news.",
      parent: platforms_parent,
      topics: topics_with_name(%w[releases performance], platform),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  %w[Valorant CS2 League\ of\ Legends Dota\ 2 Overwatch Fortnite].each do |title|
    create_child_cliq!(
      name: title,
      description: "#{title} esports discussion.",
      parent: esports_parent,
      topics: topics_with_name(%w[tournaments teams meta], title),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  # ---------------------------------------------------------------------------
  # Sci/Tech cliqs (expanded)
  # ---------------------------------------------------------------------------
  sci_tech_categories = [
    {
      name: "AI",
      description: "Models, tools, and responsible use.",
      topics: %w[models training inference ethics],
      children: [
        "Machine Learning", "LLMs", "Computer Vision", "NLP",
        "MLOps", "Agents", "Prompting", "AI Safety", "AI Ethics",
        "Reinforcement Learning"
      ]
    },
    {
      name: "Programming",
      description: "Languages, patterns, and craft.",
      topics: %w[code patterns debugging],
      children: [
        "Web Dev", "Backend", "Frontend", "Mobile Dev",
        "APIs", "Testing", "Performance", "Architecture", "Open Source"
      ]
    },
    {
      name: "Data",
      description: "Pipelines, storage, and analytics.",
      topics: %w[data pipelines analytics],
      children: [
        "Databases", "Data Engineering", "Analytics", "Visualization",
        "Data Science", "Warehousing", "Streaming Data"
      ]
    },
    {
      name: "Cloud & DevOps",
      description: "Infrastructure, deployments, and reliability.",
      topics: %w[infra deploy reliability],
      children: [
        "AWS", "GCP", "Azure", "Docker", "Kubernetes",
        "CI/CD", "Observability", "Terraform", "Serverless"
      ]
    },
    {
      name: "Cybersecurity",
      description: "Threats, defenses, and best practices.",
      topics: %w[security threats defense],
      children: [
        "AppSec", "Network Security", "Threat Modeling",
        "Identity & Access", "Cryptography", "Incident Response",
        "Vulnerability Research", "Security Tools"
      ]
    },
    {
      name: "Hardware & IoT",
      description: "Devices, chips, and embedded systems.",
      topics: %w[hardware embedded devices],
      children: [
        "CPUs", "GPUs", "Microcontrollers", "Sensors",
        "Raspberry Pi", "Arduino", "Networking Gear", "Wearables"
      ]
    },
    {
      name: "Robotics",
      description: "Automation, control, and mechatronics.",
      topics: %w[robotics control automation],
      children: [
        "Drones", "Automation", "Control Systems",
        "Computer Vision", "Motion Planning", "Robotic Arms"
      ]
    },
    {
      name: "Space",
      description: "Missions, astronomy, and exploration.",
      topics: %w[space missions astronomy],
      children: [
        "Launch Vehicles", "Satellites", "Astronomy",
        "Planetary Science", "Astrophysics", "Telescopes",
        "Space Agencies", "Space Policy"
      ]
    },
    {
      name: "Science",
      description: "Research, methods, and discoveries.",
      topics: %w[research methods experiments],
      children: [
        "Physics", "Chemistry", "Biology", "Neuroscience",
        "Earth Science", "Climate", "Mathematics"
      ]
    },
    {
      name: "Product & UX",
      description: "Human-centered tech and delivery.",
      topics: %w[product ux research],
      children: [
        "Design Systems", "User Research", "Prototyping",
        "Accessibility", "Growth", "Analytics"
      ]
    },
    {
      name: "Networking",
      description: "Protocols, latency, and infrastructure.",
      topics: %w[networking protocols latency],
      children: [
        "TCP/IP", "DNS", "CDNs", "Routing",
        "Wi-Fi", "5G", "Network Monitoring"
      ]
    }
  ]

  sci_tech_nodes = {}
  sci_tech_categories.each do |category|
    parent = create_child_cliq!(
      name: category[:name],
      description: category[:description],
      parent: sci_tech,
      topics: category[:topics],
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    sci_tech_nodes[category[:name]] = parent

    Array(category[:children]).each do |child_name|
      create_child_cliq!(
        name: child_name,
        description: "#{child_name} discussions within #{category[:name]}.",
        parent: parent,
        topics: topics_with_name(category[:topics], child_name),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end
  end

  programming_parent = sci_tech_nodes.fetch("Programming")
  %w[Ruby Python JavaScript TypeScript Go Rust Java C# C++ Swift Kotlin PHP SQL].each do |lang|
    create_child_cliq!(
      name: lang,
      description: "#{lang} language discussions.",
      parent: programming_parent,
      topics: topics_with_name(%w[language syntax tooling], lang),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  web_parent = sci_tech_nodes.fetch("Programming")
  %w[Web\ Dev Frontend Backend Full\ Stack APIs].each do |area|
    create_child_cliq!(
      name: area,
      description: "#{area} topics.",
      parent: web_parent,
      topics: topics_with_name(%w[web routing ui api], area),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  data_parent = sci_tech_nodes.fetch("Data")
  databases_parent = create_child_cliq!(
    name: "Databases",
    description: "Storage, indexing, and query patterns.",
    parent: data_parent,
    topics: %w[sql nosql indexing],
    sub_cliqs: sub_cliqs,
    rank_counters: rank_counters
  )
  %w[Postgres MySQL SQLite MongoDB Redis Elasticsearch BigQuery Snowflake].each do |db|
    create_child_cliq!(
      name: db,
      description: "#{db} discussions.",
      parent: databases_parent,
      topics: topics_with_name(%w[queries indexing performance], db),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  cloud_parent = sci_tech_nodes.fetch("Cloud & DevOps")
  %w[AWS GCP Azure Docker Kubernetes Terraform Serverless].each do |platform|
    create_child_cliq!(
      name: platform,
      description: "#{platform} infrastructure topics.",
      parent: cloud_parent,
      topics: topics_with_name(%w[infra deploy reliability], platform),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  security_parent = sci_tech_nodes.fetch("Cybersecurity")
  %w[Auth JWT OAuth Pen\ Testing Bug\ Bounties].each do |area|
    create_child_cliq!(
      name: area,
      description: "#{area} security discussions.",
      parent: security_parent,
      topics: topics_with_name(%w[security threats defense], area),
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
  end

  # ---------------------------------------------------------------------------
  # Life cliqs (exactly 100 total under Life)
  # ---------------------------------------------------------------------------
  life_categories = [
    {
      name: "Home",
      topics: %w[home projects planning],
      children: [
        "Repairs", "Cleaning", "Organization", "DIY",
        "Decor", "Appliances", "Gardening", "Maintenance", "Renovations"
      ]
    },
    {
      name: "Wellness",
      topics: %w[health habits sleep],
      children: [
        "Sleep", "Mindfulness", "Stress", "Movement",
        "Strength", "Cardio", "Mobility", "Recovery", "Routine"
      ]
    },
    {
      name: "Food & Drink",
      topics: %w[recipes prep timing],
      children: [
        "Meal Prep", "Weeknight Meals", "Baking", "Grilling",
        "Nutrition", "Snacks", "Coffee", "Tea", "Hosting"
      ]
    },
    {
      name: "Money",
      topics: %w[budgeting savings goals],
      children: [
        "Budgeting", "Saving", "Investing", "Debt",
        "Insurance", "Taxes", "Side Hustles", "Big Purchases", "Planning"
      ]
    },
    {
      name: "Relationships",
      topics: %w[communication boundaries support],
      children: [
        "Friendships", "Dating", "Partnerships", "Conflict",
        "Long Distance", "Trust", "Quality Time", "Support", "Boundaries"
      ]
    },
    {
      name: "Family",
      topics: %w[parenting caregiving routines],
      children: [
        "Parenting", "Kids Activities", "Family Planning", "Caregiving",
        "Elder Care", "Family Traditions", "Schedules", "School", "Milestones"
      ]
    },
    {
      name: "Career",
      topics: %w[career growth productivity],
      children: [
        "Job Search", "Interviews", "Networking", "Career Growth",
        "Work-Life Balance", "Skills", "Leadership", "Remote Work", "Career Change"
      ]
    },
    {
      name: "Travel",
      topics: %w[planning packing logistics],
      children: [
        "Weekend Trips", "Road Trips", "International", "Packing",
        "Budget Travel", "Travel Gear", "Itineraries", "Air Travel", "Hotels"
      ]
    },
    {
      name: "Hobbies",
      topics: %w[practice learning fun],
      children: [
        "Photography", "Reading", "Writing", "Art",
        "Music", "Cooking", "Crafts", "DIY Kits", "Collecting"
      ]
    },
    {
      name: "Local",
      topics: %w[community outings events],
      children: [
        "Neighborhoods", "Restaurants", "Parks", "Events",
        "Meetups", "Volunteering", "Local News", "Transit", "Day Trips"
      ]
    }
  ]

  life_nodes = {}
  life_categories.each do |category|
    parent = create_child_cliq!(
      name: category[:name],
      description: "#{category[:name]} conversations.",
      parent: life,
      topics: category[:topics],
      sub_cliqs: sub_cliqs,
      rank_counters: rank_counters
    )
    life_nodes[category[:name]] = parent

    Array(category[:children]).each do |child_name|
      create_child_cliq!(
        name: child_name,
        description: "#{child_name} within #{category[:name]}.",
        parent: parent,
        topics: topics_with_name(category[:topics], child_name),
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end
  end

  # Light children for the remaining main cliqs (can be expanded later)
  [
    {
      parent: politics,
      entries: [
        { name: "US Politics", topics: %w[elections policy polling] },
        { name: "Global Politics", topics: %w[geopolitics diplomacy conflicts] },
        { name: "Civics", topics: %w[civics institutions law] }
      ]
    }
  ].each do |group|
    group[:entries].each do |entry|
      create_child_cliq!(
        name: entry[:name],
        description: "#{entry[:name]} conversations.",
        parent: group[:parent],
        topics: entry[:topics],
        sub_cliqs: sub_cliqs,
        rank_counters: rank_counters
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Posts (75 total: 5 per sub cliq)
  # ---------------------------------------------------------------------------
  puts "Creating posts..."

  post_count = 0
  posts = []
  sub_cliqs.each do |entry|
    cliq = entry[:cliq]
    topics = entry[:topics]

    5.times do |index|
      topic_a = topics[index % topics.length]
      topic_b = topics[(index + 1) % topics.length]
      title, body = build_post_copy(index, cliq.name, topic_a, topic_b)
      created_at = random_time_within(14)

      post = Post.create!(
        cliq: cliq,
        user: users.sample,
        title: title,
        content: body,
        created_at: created_at,
        updated_at: created_at
      )

      posts << { post: post, topics: topics }
      post_count += 1
    end
  end

  # ---------------------------------------------------------------------------
  # Replies (2-4 per post)
  # ---------------------------------------------------------------------------
  puts "Creating replies..."

  reply_count = 0
  posts.each do |entry|
    post = entry[:post]
    topics = entry[:topics]
    reply_total = rand(2..4)

    reply_total.times do
      max_seconds = [(Time.current - post.created_at).to_i, 1].max
      created_at = post.created_at + rand(1..max_seconds)
      user_pool = users - [post.user]
      reply_user = user_pool.empty? ? users.sample : user_pool.sample
      reply_text = build_reply_copy(
        post_title: post.title,
        post_body: post.content,
        topics: topics
      )

      Reply.create!(
        post: post,
        user: reply_user,
        content: reply_text,
        created_at: created_at,
        updated_at: created_at
      )

      reply_count += 1
    end
  end

  puts "Seeded #{users.size} users, #{main_cliqs.size} main cliqs, #{sub_cliqs.size} sub cliqs, #{post_count} posts, #{reply_count} replies."
end
