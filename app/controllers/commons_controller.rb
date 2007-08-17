class CommonsController < ApplicationController

  def show_commons_hansard
    date = UrlDate.new(params)
    if not date.is_valid_date?
      render :text => 'not valid date'
    else
      @sitting = HouseOfCommonsSitting.find_by_date(date.to_date.to_s)
    end
  end

end