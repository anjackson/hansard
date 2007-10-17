module SectionsHelper
  
  def section_nav_links(section)
    the_links = ""

    # if section.sitting
      # the_links << "<p><ol>"
      # the_links << "<li><a class='sitting-contents' href='#{section_url(section.previous_linkable_section)}'>#{section.sitting.title}</a></li>"
      # the_links << "</ol></p>"
    # end

    the_links << "<p><ol>"
    the_links << "<li>&uarr; <a class='section-sitting' href='#{sitting_date_url(section.sitting)}'>#{section.sitting.title} #{section.sitting.date_text}</a></li>"
    the_links << "</ol></p>"
    
    if section.previous_linkable_section
      the_links << "<p><ol>"
      the_links << "<li>&larr; <a class='prev-section' href='#{section_url(section.previous_linkable_section)}'>#{section.previous_linkable_section.title}</a></li>"
      the_links << "</ol></p>"
    end

    if section.next_linkable_section
      the_links << "<p><ol>"
      the_links << "<li><a class='next-section' href='#{section_url(section.next_linkable_section)}'>#{section.next_linkable_section.title}</a> &rarr;</li>"
      the_links << "</ol></p>"
    end

    the_links
  end
end