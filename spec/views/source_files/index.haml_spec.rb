require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/index.haml", " in general" do
  
  it "should have an 'h1' tag with the text 'Source Files'" do 
    assigns[:source_files] = []
    render 'source_files/index.haml'
    response.should have_tag("h1", :text => "Source Files")
  end
  
end