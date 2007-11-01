class ParliamentSessionsController < ApplicationController

  def index
    @series = ParliamentSession.series
    @monarchs = ParliamentSession.monarchs
  end

  def series_index
    @series_number = params[:series_number]

    @sessions_grouped_by_volume_in_series =
        ParliamentSession.sessions_in_groups_by_volume_in_series(@series_number)
  end

  def monarch_index
    @monarch_name = params[:monarch_name]

    @sessions_in_groups_by_regnal_years =
        ParliamentSession.sessions_in_groups_by_regnal_years(@monarch_name)
  end

  def volume_index
    @series_number = params[:series_number]
    @volume_number = params[:volume_number]
    @commons_session = HouseOfCommonsSession.find_volume(@series_number, @volume_number)
    @lords_session = HouseOfLordsSession.find_volume(@series_number, @volume_number)
  end

  def regnal_years_index
    @monarch_name = params[:monarch_name]
    @regnal_years = params[:regnal_years]
    @commons_session = HouseOfCommonsSession.find_by_monarch_and_reign(@monarch_name, @regnal_years)
    @lords_session = HouseOfLordsSession.find_by_monarch_and_reign(@monarch_name, @regnal_years)

    if @commons_session
      @regnal_years = @commons_session.regnal_years
    elsif @lords_session
      @regnal_years = @lords_session.regnal_years
    end
  end
end
