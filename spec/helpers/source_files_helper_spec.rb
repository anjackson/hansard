require File.dirname(__FILE__) + '/../spec_helper'
include SourceFilesHelper

describe SourceFilesHelper do
  
  describe " when creating a source file error url" do
    
    it 'should ask for the normalized text of the error' do
      SourceFile.should_receive(:error_slug).with('An error').and_return('an-error')
      source_file_error_url('An error')
    end
    
  end
  
end