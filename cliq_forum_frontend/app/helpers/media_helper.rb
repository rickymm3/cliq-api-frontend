module MediaHelper
  def extract_first_video_url(content)
    return nil if content.blank?
    
    # YouTube (Standard + Short) regex
    youtube_regex = /(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/
    
    match = content.match(youtube_regex)
    match ? match[0] : nil
  end

  def render_video_embed(url)
    return nil if url.blank?

    youtube_regex = /(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/
    match = url.match(youtube_regex)

    if match
      youtube_id = match[1]
      return content_tag(:div, class: "ratio ratio-16x9 mb-3 rounded overflow-hidden shadow-sm") do
        content_tag(:iframe, "", 
          src: "https://www.youtube.com/embed/#{youtube_id}", 
          allowfullscreen: true,
          allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
          style: "border:0;"
        )
      end
    end
    
    nil # Return nil if not a supported video URL
  end
  
  # Scans content for video links and replaces them with embeds
  def auto_embed_content(content)
    return "" if content.blank?
    
    # We use a placeholder to avoid messing up already embedded iframes if any
    # Simple strategy: Find plain text URLs on their own line or wrapped in <p> tags
    
    processed_content = content.gsub(%r{(<p>)?\s*(https?://(?:www\.)?(?:youtube\.com|youtu\.be)/\S+)\s*(</p>)?}) do |match|
      # $2 is the URL
      url = $2
      embed = render_video_embed(url)
      embed || match # Return embed or original if not valid
    end
    
    sanitize processed_content, tags: %w(div iframe p a strong em b i u h1 h2 h3 h4 h5 h6 ul ol li blockquote code pre table thead tbody tr th td span br img), attributes: %w(src href class style width height allow allowfullscreen target)
  end
end
