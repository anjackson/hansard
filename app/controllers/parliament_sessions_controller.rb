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
  end
end
