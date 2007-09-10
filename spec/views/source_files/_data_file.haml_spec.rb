require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/_data_file.haml", " in general" do
  
  before do 
    @data_file = mock_model(DataFile)
    @data_file.stub!(:name).and_return("data file name")
    @data_file.stub!(:sitting)
    @data_file.stub!(:log)
    @controller.template.stub!(:data_file).and_return(@data_file)
  end
  
  def do_render
    render 'source_files/_data_file.haml'
  end
  
  it "should have a div containing the data file name" do  
    do_render
    response.should have_tag("div", :text => "data file name")
  end
  
  it "should have a link to the sitting if a sitting has been created" do
    @data_file.stub!(:sitting).and_return(mock_model(HouseOfCommonsSitting))
    @controller.template.stub!(:sitting_date_url).and_return("http://test.url")
    do_render
    response.should have_tag("a[href=http://test.url]", :text => "data file name")
  end
  
end