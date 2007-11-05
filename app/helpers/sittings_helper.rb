module SittingsHelper
  
  include PresentOnDateTimelineHelper
  alias_method :timeline_link_for, :link_for
   
  def link_for(interval, resolution, counts, options)
    if resolution == :century
      if counts.sum > 0
        link_to interval.to_s, {:controller => "sittings",
                                :action     => "show",
                                :decade     => interval}
      else
        interval
      end
    else 
      timeline_link_for(interval, resolution, counts, options)
    end
  end
  
  def section_occurrences(title, start_date, end_date, resolution)
    sections = Section.find_by_title_in_interval(title, start_date, end_date)
    case resolution
    when :year
      sections.group_by(&:month).sort.each do |month, sections|
        yield Date::MONTHNAMES[month], sections
      end
    when :month
      sections.group_by(&:date).sort.each do |date, sections|
        yield date.to_formatted_s(:short), sections
      end
    else
      sections.group_by(&:year).sort.each do |year, sections|
        yield year.to_s, sections
      end
    end
  end
  
  def frequent_section_links(sections)
    members = []
    sections.group_by(&:first_member).each do |member, sections|
      text = member.blank? ? "[No speaker]" : member 
      links = []
      sections.each_with_index do |section, index|
        links << link_to(index+1, section_url(section))
      end
      text += " " 
      text += "<span class='frequent-section-links'>[#{links.join(', ')}]</span>"
      members << text
    end
    return members.join(", ")
  end
  
end