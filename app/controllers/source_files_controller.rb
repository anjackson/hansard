class SourceFilesController < ApplicationController

  def index
    @source_files = SourceFile.find(:all, :order => "name asc")
  end
  
  def show
    @source_file = SourceFile.find_by_name(params[:name])
  end
  
end