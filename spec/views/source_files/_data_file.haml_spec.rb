require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/_data_file.haml", " in general" do
  
  before do 
    data_file = mock_model(DataFile)
    data_file.stub!(:name).and_return("data file name")
    @controller.template.stub!(:data_file).and_return(data_file)
  end
  
  it "should have a div containing the data file name" do  
    render 'source_files/_data_file.haml'
    response.should have_tag("div", :text => "data file name")
  end
  
end