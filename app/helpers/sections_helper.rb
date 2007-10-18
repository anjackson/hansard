module SectionsHelper
  
  def section_nav_links(section)
    the_links = ""

    # if section.sitting
      # the_links << "<p><ol>"
      # the_links << "<li><a class='sitting-contents' href='#{section_url(section.previous_linkable_section)}'>#{section.sitting.title}</a></li>"
      # the_links << "</ol></p>"
    # end

    the_links << "<ol id='arrow-navigation'>"
    the_links << "<li>&uarr; Up to <a class='section-sitting' href='#{sitting_date_url(section.sitting)}'>#{section.sitting.title} #{section.sitting.date_text}</a></li>"
    
    if section.previous_linkable_section
      the_links << "<li>&larr; Back to <a class='prev-section' href='#{section_url(section.previous_linkable_section)}'>#{section.previous_linkable_section.title}</a></li>"
    end

    if section.next_linkable_section
      the_links << "<li>On to <a class='next-section' href='#{section_url(section.next_linkable_section)}'>#{section.next_linkable_section.title}</a> &rarr;</li>"
    end

    the_links << "</ol>"

    the_links
  end
end