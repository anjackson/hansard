module SectionsHelper
  
  def section_in_place_edit(section)
    "<span class='in_place_editor_field' id='section_title_#{section.id}_in_place_editor'>
      #{section.title}
    </span>
    <script type='text/javascript'>
       //<![CDATA[
          new Ajax.InPlaceEditor('section_title_#{section.id}_in_place_editor', '#{url_for(:controller => 'sections', :action => 'set_section_title', :id => section.id)}')
       //]]>
    </script>
    </span>"
  end
  
  def section_nav_links(section)
    the_links = "<div id='navigation-by-sections'>"
    the_links << "<p id='parent-section'>Parent section<br/> <a class='section-sitting' href='#{sitting_date_url(section.sitting)}'>#{section.sitting.title} #{section.sitting.date_text}</a></p>"
    the_links << "<p id='previous-section'>Previous section<br/> <a class='previous-section' href='#{section_url(section.previous_linkable_section)}'>#{section.previous_linkable_section.title}</a></p>" if section.previous_linkable_section
    the_links << "<p id='next-section'>Next section<br/> <a class='next-section' href='#{section_url(section.next_linkable_section)}'>#{section.next_linkable_section.title}</a></p>" if section.next_linkable_section
    the_links << "</div>"
    the_links
  end
end


