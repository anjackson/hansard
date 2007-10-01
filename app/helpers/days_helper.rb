module DaysHelper
  
  def render_calendar(current_date, dates_with_material)
    date_next_month = find_next_day_with_material(current_date, ">>", :month)
    date_prev_month = find_next_day_with_material(current_date, "<<", :month)
    date_next_year = find_next_day_with_material(current_date, ">>", :year)
    date_prev_year = find_next_day_with_material(current_date, "<<", :year)
    calendar(:year => current_date.year, 
             :month => current_date.month, 
             :day => current_date.day, 
             :next_month => date_link(date_next_month, '&rarr;'),
             :prev_month => date_link(date_prev_month, '&larr;'),
             :next_year  => date_link(date_next_year, '&gt;&gt;'),
             :prev_year  => date_link(date_prev_year, '&lt;&lt;')
             ) do |date|
      atts = {}
      atts = { :id => "current-day", :class => "day" } if date == current_date
      if dates_with_material.include? date
        [date_link(date), atts.merge(
          :class => "day-with-material",
          :title => 'Day with material')]
      else
        [date.mday, atts.empty? ? nil : atts ]
      end
    end
  end
  
  def section_previous_and_next_links(section)
    the_links = ""
    
    if @section.previous_linkable_section
      the_links << "<p><ol>"
      the_links << "<li>&larr; Previously</li>"
      the_links << "<li><a class='prev-section' href='#{section_url(@section.previous_linkable_section)}'>#{section.previous_linkable_section.title}</a></li>"
      the_links << "</ol></p>"
    end
    
    if @section.next_linkable_section
      the_links << "<p><ol>"
      the_links << "<li>Next &rarr;</li>"
      the_links << "<li><a class='next-section' href='#{section_url(@section.next_linkable_section)}'>#{section.next_linkable_section.title}</a></li>"
      the_links << "</ol></p>"
    end
    
    the_links
  end
  
  def date_link(date, display=nil)
    display = date.mday unless display
    link_to display, url_for(:controller => "days", :action => "show", :year => date.year, :month => date.month, :day => date.mday)
  end
  
  def find_next_day_with_material(current_date, direction, unit=:month)
    no_of_months = {:month => 1, 
                   :year  => 12}
    date = current_date.send(direction.to_sym, no_of_months[unit])
    first, last = date.first_and_last_of_month
    dates_with_material = first.material_dates_upto(last)
    dates_with_material.empty? ? first : dates_with_material.first
  end
  
end