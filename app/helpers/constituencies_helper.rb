module ConstituenciesHelper

  def constituency_link constituency
    link_to constituency.name, constituency_url(constituency)
  end

end