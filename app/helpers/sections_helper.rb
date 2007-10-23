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
    open :table, { :id => 'navigation-by-sections' } do
      # NAVIGATION HEADER
      open :tr do
        open :td do
          puts "Parent section&mdash;<br/>"
          open :a, { :class => 'parent-section', :href => sitting_date_url(section.sitting) } do
            puts section.sitting.title << "<br/>" << section.sitting.date_text
          end
        end
      end
      
      
      open :tr do
        open :td do
          puts "Previous section&mdash;<br/>"
          if section.previous_linkable_section
          
          open :a, { :class => 'previous-section', :href => section_url(section.previous_linkable_section) } do
            puts section.previous_linkable_section.title
          end
          
        else
          puts "No previous sections for " << section.sitting.date_text
          end
        end
      end
    
    
      
      open :tr do
        open :td do
          puts "Next section&mdash;<br/>"
          
          if section.next_linkable_section
          open :a, { :class => 'next-section', :href => section_url(section.next_linkable_section) } do
            puts section.next_linkable_section.title
          end
          
        else
          puts "No remaining sections for " << section.sitting.date_text
          end
        end
      end
    end
  
  end
end


