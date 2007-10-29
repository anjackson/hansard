class ParliamentSessionsController < ApplicationController

  def index
    @series = ParliamentSession.series
  end

  def series_index
    series_number = params[:series_number_series]

    @sessions_grouped_by_volume_in_series =
        ParliamentSession.sessions_in_groups_by_volume_in_series(series_number)
  end
end
