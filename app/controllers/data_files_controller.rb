class DataFilesController < ApplicationController

  def index
    @data_files = DataFile.find(:all)
  end

end