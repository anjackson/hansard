class ErrorsController < ApplicationController

  def show
    @error_types, @error_types_to_files = SourceFile.error_summary
    if @type = SourceFile.error_from_slug(params[:name])
      @title = @type
    else
      respond_with_404
    end
  end

end