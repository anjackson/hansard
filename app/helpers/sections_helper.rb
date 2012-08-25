module SectionsHelper

  def section_breadcrumbs(section, title)
    haml_tag :a, { :href => "#{url_for_date(section.date)}##{section.sitting_uri_component}", :rel => "directory up"  } do
      puts sitting_prefix(section.sitting_class)
    end

    if section.parent_section && section.parent_section.title
      puts " &rarr;"
      puts link_to_section(section.parent_section)
    end

  end

  def section_navigation(section)

    if section.previous_linkable_section
      puts "<div id='previous-section'>Back to"
      haml_tag :a, { :href => section_url(section.previous_linkable_section), :rel=>"prev" } do
       puts section.previous_linkable_section.title
     end
     puts "</div>"
    end
    
    if section.next_linkable_section
      puts "<div id='next-section'>Forward to"
      haml_tag :a, { :href => section_url(section.next_linkable_section), :rel=>"next"} do
        puts section.next_linkable_section.title
      end
      puts "</div>"
    end
  end

  def marker_html(contribution, sitting, options={})
    markers = ''
    return markers if options[:hide_markers]
    contribution.markers(options) do |marker_type, marker_value|
      if marker_type == "column"
        markers += column_marker(marker_value, sitting)
      end
      if marker_type == "image"
        markers += image_marker(marker_value, sitting)
      end
    end
    markers
  end

  def markup_mention(reference, mention)
    case mention
      when ActMention
        link_to(reference, act_url(mention.act))
      when BillMention
        link_to(reference, bill_url(mention.bill))
      else
        reference
    end
  end

  def markup_mentions(contribution)
    model_mentions(contribution, :text) do |reference, mention|
      markup_mention(reference, mention)
    end
  end

  def model_mentions(model, field)
    text = model.send(field)
    return text if model.mentions.empty?
    marked_up = ''
    last_position = 0
    position_hash = model.mentions.group_by(&:start_position)
    positions = position_hash.keys.sort
    positions.each do |start_position|
      # ignore any mention within/overlapping a previous mention
      if start_position >= last_position
        mentions = position_hash[start_position]
        marked_up += text[last_position...start_position] if text[last_position...start_position]
        longest_mention = mentions.sort_by(&:end_position).last
        last_position = longest_mention.end_position
        reference = text[start_position...last_position] if text[start_position...last_position]
        marked_up += yield reference, longest_mention
      end
    end
    marked_up += text[last_position...text.size] if text[last_position...text.size]
    marked_up
  end
  
  def format_contribution contribution, sitting=nil, options={}
    text = markup_mentions(contribution)
    text = format_display_text(text, sitting, options)
    final_text = markup_official_report_references(contribution, text)
  end
  
end
