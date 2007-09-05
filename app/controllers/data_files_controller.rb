class DataFilesController < ApplicationController

  def index
    @data_files = DataFile.find(:all)
  end

  def show_warnings
    @data_files = DataFile.find(:all).select{ |f| !f.log.blank? }.sort_by(&:name).group_by(&:saved)
  end
end