module SittingsHelper

  def turns_sparkline_tag(sitting)
    %Q[<img src="/sittings/show/#{sitting.Id}/turns_sparkline.png" class="sparkline" alt="Turns Sparkline" />]
  end

  def turns_graph_tag(sitting)
    %Q[<img src="/sittings/show/#{sitting.Id}/turns_graph.png" class="sparkline" alt="Turns Graph" />]
  end
  
  def sitting_calender(date)
  
    today = Date.today

    sittings = Sitting.sittings_by_month(date)
    
    html = calendar({:year => date.year, :month => date.month, :first_day_of_week => 1}) do |d|
      
      if today.year == date.year and today.month == date.month and today.day == d.mday
        cell_attrs = {:class => 'specialDay'}
      else
        cell_attrs = {:class => 'day'}
      end
      
      sitting = sittings.find{|sitting|sitting.SatAt.day == d.mday}
      if sitting
        cell_text = link_to d.mday, :action => 'show', :id => sitting.Id
      else
        cell_text = d.mday
      end
      [cell_text, cell_attrs]
      
    end  
    
    html
  end
  
  def multiple_sitting_calenders(date,number_of_months,columns)
  
    html = "<table>"
    previous_date = date << number_of_months
    next_date = date >> number_of_months

    number_of_months.times do |x|
     
      if (x+1).divmod(columns)[1] == 1
        html += "<tr>"
      end
      
      html += "<td>"
      html += sitting_calender(date)
      #html += date.to_s
      html += "</td>"

      if (x+1).divmod(columns)[1] == 0
        html += "</tr>"
      end

      date = date >> 1
    end
    html += "</table>"
    
    html += "<br />"
    html += link_to '< Previous', :action => 'list', :month => previous_date.month, :year => previous_date.year
    html += " "
    html += link_to 'Next >', :action => 'list', :month => next_date.month, :year => next_date.year
    
    html
  end


end
