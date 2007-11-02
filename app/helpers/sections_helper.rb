module SectionsHelper

  def section_nav_links(section)
    open :table, { :id => 'navigation-by-sections' } do
          
          open :thead do
            open :th do
              puts "Sections of Hansard"
            end
          end
          
      open :tr do
        open :td do
          puts "Parent section&mdash;<br/>"
          open :a, { :class => 'parent-section', :href => sitting_date_url(section.sitting) } do
            puts [section.sitting.title.to_s, section.sitting.date_text.to_s].join(' ')
          end
        end
      end
      
      open :tr do
        open :td do
          
          if section.previous_linkable_section
          puts "Previous section&mdash;<br/>"
          open :a, { :class => 'previous-section', :href => section_url(section.previous_linkable_section) } do
            puts section.previous_linkable_section.title
          end
        else
          puts "No previous sections"
          end
        end
      end
      
      open :tr do
        open :td do
          
          if section.next_linkable_section
            puts "Next section&mdash;<br/>"
          open :a, { :class => 'next-section', :href => section_url(section.next_linkable_section) } do
            puts section.next_linkable_section.title
          end
        else
          puts "No remaining sections"
          end
        end
      end
      
      open :tfoot do
        open :td do
          open :p do
            open :a, { :class => 'to-top-of-page', :href => request.path } do
                puts "Top of page."
            end
        end
        open :p do
          puts "&copy; UK Parliament."
          
        end
        end
      end
      
    end
  end
end


