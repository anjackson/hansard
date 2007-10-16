require File.dirname(__FILE__) + '/../../spec_helper'

describe "written answers index.haml", " in general" do

  before do 
    assigns[:sittings_by_year] = []
  end
  
  it "should have the title 'Written Answers' in an 'h1' tag" do 
    render 'written_answers/index.haml', :layout => 'application'
    response.should have_tag('h1', :text => "Written Answers")
  end

end