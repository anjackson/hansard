require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/_source_file.haml", " in general" do
  
  before do 
    source_file = mock_model(SourceFile)
    source_file.stub!(:name).and_return("source name")
    @controller.template.stub!(:source_file).and_return(source_file)
  end
  
  it "should have a link containing the source file name" do  
    render 'source_files/_source_file.haml'
    response.should have_tag("a", :text => "source name")
  end
  
end