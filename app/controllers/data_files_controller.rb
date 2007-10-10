class DataFilesController < ApplicationController

  include Hansard::ParserHelper

  def index
    @data_files = DataFile.find(:all)
  end

  def show_warnings
    @data_files = DataFile.find(:all).select{ |f| !f.log.blank? }.sort_by(&:name).group_by(&:saved)
  end

  def reload_lords_for_date
    if request.post?
      if DataFile.reload_possible?
        date = Date.parse(params['date'])
        data_file = reload_sitting_on_date(date, 'lords', HouseOfLordsSitting, Hansard::HouseLordsParser)
        @data_file = DataFile.find(data_file.id)
      else
        render :text => ''
      end
    else
      render :text => ''
    end
  end

  def reload_commmons_for_date
    if request.post?
      if DataFile.reload_possible?
        date = Date.parse(params['date'])
        data_file = reload_sitting_on_date(date, 'commons', HouseOfCommonsSitting, Hansard::HouseCommonsParser)
        @data_file = DataFile.find(data_file.id)
      else
        render :text => ''
      end
    else
      render :text => ''
    end
  end
end