require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/index.haml", " in general" do
  
  it "should have an 'h1' tag" do 
    assigns[:source_files] = []
    render 'source_files/index.haml'
    response.should have_tag("h1")
  end
  
  
  it "should have an 'h1' tag with the text 'Source Files'" do 

  end
  
end