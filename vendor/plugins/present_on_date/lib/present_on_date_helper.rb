require 'date'

module PresentOnDateHelper

  def link_to_present_on_date item, date
    title = nil

    model = item.class

    while (title == nil) and (model != ActiveRecord::Base)
      title_helper = model.name.tableize.singularize + '_present_on_date_title'

      title = send title_helper, item, date if respond_to? title_helper

      model = model.superclass
    end

    if title == nil
      title = item.present_on_date_title
    end

    url_helper = item.present_on_date_url_helper_method

    if respond_to? url_helper
      url = send url_helper, item.present_on_date_url_parameter
      link_to title.strip, url
    else
      title
    end
  end
  
  def display_date date
    date.strftime("%d %b %Y").reverse.chomp('0').reverse
  end

end