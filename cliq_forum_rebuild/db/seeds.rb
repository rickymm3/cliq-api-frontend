# frozen_string_literal: true

puts "== Comprehensive Seeding =="

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
puts "Cleaning Database..."
ActionText::RichText.delete_all rescue nil
PostVisit.delete_all rescue nil
PostDailyStat.delete_all rescue nil
Reply.delete_all rescue nil
Post.delete_all rescue nil
CliqVisit.delete_all rescue nil
CliqDailyStat.delete_all rescue nil
Cliq.delete_all rescue nil
User.delete_all rescue nil

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------
puts "Creating Users..."
users = []
20.times do |i|
  users << User.create!(
    email: "user#{i+1}@cliq.test",
    password: "password123!",
    password_confirmation: "password123!"
  )
end

# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------
def create_contentForCliq(cliq, users, count = 3)
  count.times do
    user = users.sample
    title = [
      "Thoughts on #{cliq.name}?", 
      "Best #{cliq.name} resources", 
      "Has anyone tried this in #{cliq.name}?", 
      "Quick update regarding #{cliq.name}",
      "[Guide] Getting started with #{cliq.name}"
    ].sample
    
    content = "This is a post about #{cliq.name}. It contains some interesting observations and questions for the community. What do you all think?"
    
    # Randomly make some posts contentious
    is_contentious = rand(1..20) == 1
    title = "[Contentious] #{title}" if is_contentious

    post = Post.create!(
      title: title,
      content: content,
      user: user,
      cliq: cliq,
      status: is_contentious ? 1 : 0,
      views_count: rand(10..500)
    )

    # Replies
    rand(0..5).times do
      reply_user = users.sample
      is_reply_contentious = rand(1..30) == 1
      
      Reply.create!(
        content: "Interesting point! I have some thoughts on #{cliq.name} as well. #{is_reply_contentious ? 'This reply is controversial.' : ''}",
        user: reply_user,
        post: post,
        status: is_reply_contentious ? 1 : 0
      )
    end
  end
end

# ---------------------------------------------------------------------------
# Cliq Structure
# ---------------------------------------------------------------------------
puts "Creating Cliq Hierarchy..."

# Create a Single Master Root Cliq
master_root = Cliq.create!(
  name: "Cliq",
  description: "The hub for all cliqs.",
  parent_cliq_id: nil,
  slug: "cliq"
)

# Content for Master Root
create_contentForCliq(master_root, users, 5)

categories = [
  { 
    name: "Entertainment", 
    desc: "Movies, Music, TV, and more.",
    children: [
      { name: "Movies", children: ["Action", "Horror", "Comedy", "Indie"] },
      { name: "Music", children: ["Rock", "Pop", "Jazz", "Classical"] },
      { name: "TV", children: ["Streaming", "Cable", "Reality"] },
      { name: "Books", children: ["Fiction", "Non-Fiction", "Sci-Fi"] }
    ]
  },
  { 
    name: "Life", 
    desc: "Lifestyle discussions.",
    children: [
      { name: "Food", children: ["Recipes", "Restaurants", "Healthy Eating"] },
      { name: "Travel", children: ["Destinations", "Tips", "Digital Nomad"] },
      { name: "Relationships", children: ["Dating", "Family", "Friendship"] },
      { name: "Fitness", children: ["Gym", "Running", "Yoga"] }
    ]
  },
  { 
    name: "Politics", 
    desc: "Serious discussions about governance.",
    children: [
      { name: "US Politics", children: ["Elections", "Policy", "Congress"] },
      { name: "World News", children: ["Europe", "Asia", "Americas"] },
      { name: "Local", children: ["City Hall", "Community", "Schools"] }
    ]
  },
  { 
    name: "Gaming", 
    desc: "Video games and culture.",
    children: [
      { name: "PC Master Race", children: ["Hardware", "Steam", "Mods"] },
      { name: "Console", children: ["PlayStation", "Xbox", "Nintendo"] },
      { name: "Mobile", children: ["iOS", "Android"] },
      { name: "Esports", children: ["Tournaments", "Teams"] }
    ]
  },
  { 
    name: "Sci-Tech", 
    desc: "Science and Technology.",
    children: [
      { name: "Programming", children: ["Web Dev", "AI", "Systems"] },
      { name: "Space", children: ["Mars", "Moon", "Rockets"] },
      { name: "Gadgets", children: ["Phones", "Wearables", "Home Automation"] }
    ]
  }
]

categories.each do |cat|
  puts "  Creating Main Category: #{cat[:name]}"
  # Ensure unique slug
  main_slug = cat[:name].parameterize
  main_slug += "-#{SecureRandom.hex(2)}" if Cliq.exists?(slug: main_slug)

  # These are now children of the Master Root
  main_cliq = Cliq.create!(
    name: cat[:name],
    description: cat[:desc],
    slug: main_slug,
    parent_cliq_id: master_root.id
  )
  create_contentForCliq(main_cliq, users, 2)
  
  # ... rest of children creation ...

  cat[:children].each do |child|
    child_name = child[:name]
    puts "    Creating Child Cliq: #{child_name}"
    
    child_slug = "#{cat[:name]}-#{child_name}".parameterize
    child_slug += "-#{SecureRandom.hex(2)}" if Cliq.exists?(slug: child_slug)

    child_cliq = Cliq.create!(
      name: child_name,
      description: "Sub-cliq for #{child_name}",
      slug: child_slug,
      parent_cliq_id: main_cliq.id
    )
    create_contentForCliq(child_cliq, users, 2)

    if child[:children]
      child[:children].each do |grandchild_name|
        
        gc_slug = "#{child_name}-#{grandchild_name}".parameterize
        gc_slug += "-#{SecureRandom.hex(2)}" if Cliq.exists?(slug: gc_slug)

        grandchild_cliq = Cliq.create!(
          name: grandchild_name,
          description: "Niche discussion for #{grandchild_name}",
          slug: gc_slug,
          parent_cliq_id: child_cliq.id
        )
        create_contentForCliq(grandchild_cliq, users, 2)
      end
    end
  end
end

puts "Seeding Complete!"
