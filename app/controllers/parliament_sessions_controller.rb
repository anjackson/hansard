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

    @sessions_in_groups_by_year_of_the_reign =
        ParliamentSession.sessions_in_groups_by_year_of_the_reign(@monarch_name)
  end

  def volume_index
    @series_number = params[:series_number]
    @volume_number = params[:volume_number]
    @commons_session = HouseOfCommonsSession.find_volume(@series_number, @volume_number)
    @lords_session = HouseOfLordsSession.find_volume(@series_number, @volume_number)
  end

  def years_of_reign_index
    @monarch_name = params[:monarch_name]
    @years_of_reign = params[:years_of_reign]
    @commons_session = HouseOfCommonsSession.find_by_monarch_and_reign(@monarch_name, @years_of_reign)
    @lords_session = HouseOfLordsSession.find_by_monarch_and_reign(@monarch_name, @years_of_reign)

    if @commons_session
      @years_of_reign = @commons_session.year_of_the_reign
    elsif @lords_session
      @years_of_reign = @lords_session.year_of_the_reign
    end
  end
end
