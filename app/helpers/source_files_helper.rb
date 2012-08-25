module SourceFilesHelper

  def source_file_error_url(error)
    error_url(:name => SourceFile.error_slug(error))
  end
  
end