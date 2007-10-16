require File.dirname(__FILE__) + '/../../spec_helper'

describe "commons index.haml", " in general" do

  before do 
    assigns[:sittings_by_year] = []
  end
  
  it "should have the title 'Commons' in an 'h1' tag" do 
    render 'commons/index.haml', :layout => 'application'
    response.should have_tag('h1', :text => "Commons")
  end

end