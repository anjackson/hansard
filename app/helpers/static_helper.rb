module StaticHelper

  def example_date
    Date.new(2002, 4, 16)
  end
  
  def example_api_url
    "http://#{request.host_with_port}#{url_for_date(example_date)}"
  end
  
  def example_membership_url
    date_params = { :year => example_date.year,
                    :month => example_date.month, 
                    :day => example_date.day }
    memberships_url(date_params)
  end
  
end
