require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/index.haml", " in general" do
  
  it "should have an 'h1' tag" do 
    assigns[:source_files] = []
    render 'source_files/index.haml'
    response.should have_tag("h1")
  end
  
  #@expected_text_regex = /Source files/
  #assigns[:source_files] = []
  #render 'source_files/index.haml'
  #response.should =~ @expected_text_regex
  it "should have an 'h1' tag with the text 'Source Files'" do 

    
  end
  
end


