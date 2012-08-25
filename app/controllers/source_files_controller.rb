class SourceFilesController < ApplicationController

  def index
    @source_files = SourceFile.find(:all, :order => "name asc")
    @error_types, @error_types_to_files = SourceFile.error_summary
  end

  def show
    @source_file = SourceFile.find_by_name(params[:name])
    no_model_response("source_file") and return false unless @source_file
  end

end