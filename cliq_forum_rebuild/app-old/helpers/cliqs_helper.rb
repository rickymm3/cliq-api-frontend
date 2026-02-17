module CliqsHelper

  def get_all_parent_cliqs(cliq)
    parents = []
    current = cliq
    while current.parent_cliq
      current = current.parent_cliq
      break if current == Cliq.find_by(name: "Cliq")
      parents << current
    end
    parents.reverse # To have the direct parent first
  end

  # Trail from just after `base` down to `target`.
  def cliq_chain(target)
    (target.respond_to?(:ancestors) ? target.ancestors : []) + [target]
  end

  # Trail from just after `base` down to `target`.
  def relative_trail_cliqs(base, target)
    chain = cliq_chain(target)
    idx   = chain.index(base)
    idx ? chain[(idx + 1)..-1] : chain
  end

  # Clickable relative trail, e.g. "Taylor Swift / Tours / Upcoming"
  def relative_trail_links(base, target, separator: " / ")
    cliqs = relative_trail_cliqs(base, target)
    return "" if cliqs.blank?

    safe_join(
      cliqs.map { |c|
        link_to c.name, cliq_path(c),
          data: { turbo_frame: "_top", turbo_action: "advance" },
          class: "post-path__link"
      },
      content_tag(:span, separator, class: "post-path__sep")
    )
  end

  # => "entertainment" | "science" | "gaming" | "politics" | "umbrella"
  def cliq_theme_key(cliq)
    return "umbrella" unless cliq

    top = cliq.root_or_self            # highest non-"Cliq" ancestor (or self)
    name = top.name.to_s.downcase

    # Normalize common prefixes like "1-Science" etc.
    # strip leading digits and hyphen, and collapse spaces
    name = name.gsub(/^\d+\s*-\s*/,'').strip

    case
    when name.include?("entertainment") then "entertainment"
    when name.include?("science")       then "science"
    when name.include?("gaming")        then "gaming"
    when name.include?("politic")       then "politics"  # matches "politics"
    else "umbrella"
    end
  end
  
end
