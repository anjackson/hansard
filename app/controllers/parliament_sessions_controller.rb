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
end
