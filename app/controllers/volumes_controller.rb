class VolumesController < ApplicationController

  caches_page :index, :series_index, :monarch_index, :show

  def index
    @series = Series.find_all
    @monarchs = Monarch.list
  end

  def series_index
    @series_list = Series.find_all_by_series(params[:series])
  end

  def monarch_index
    @monarch = Monarch.slug_to_name(params[:monarch_name])
    @volumes = Volume.find_all_by_monarch(@monarch, :order => 'first_regnal_year asc, number asc, part asc')
  end

  def show
    @series = Series.find_by_series(params[:series])
    part = params[:part]
    @volumes = Volume.find_all_by_identifiers(params[:series], params[:volume_number], part)
    no_model_response "volume" and return false if @volumes.empty?
  end

end