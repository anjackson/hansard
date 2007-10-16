require File.dirname(__FILE__) + '/../../spec_helper'

describe "lords index.haml", " in general" do

  before do 
    assigns[:sittings_by_year] = []
  end
  
  it "should have the title 'Lords' in an 'h1' tag" do 
    render 'lords/index.haml', :layout => 'application'
    response.should have_tag('h1', :text => "Lords")
  end

end