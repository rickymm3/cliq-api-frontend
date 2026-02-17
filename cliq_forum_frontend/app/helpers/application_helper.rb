module ApplicationHelper
  def clean_action_text_content(content)
    return "" if content.blank?
    
    # Remove HTML comments using regex
    # Regex explanation: <!-- followed by anything until -->
    # The 'm' modifier allows . to match newlines
    cleaned = content.gsub(/<!--.*?-->/m, '').strip
    
    sanitize(cleaned)
  end

  def icon_for_cliq(cliq_name)
    case cliq_name.downcase
    when /tech/, /code/, /dev/
      "bi-laptop"
    when /music/, /audio/
      "bi-music-note-beamed"
    when /sports/, /game/
      "bi-trophy"
    when /news/, /politics/
      "bi-newspaper"
    when /science/
      "bi-flask"
    when /art/, /design/
      "bi-palette"
    when /entertainment/, /film/, /movies/, /tv/
      "bi-film"
    when /local/, /location/, /geo/
      "bi-geo-alt-fill"
    else
      "bi-hash" # Default hashtag icon for generic topics
    end
  end
end
