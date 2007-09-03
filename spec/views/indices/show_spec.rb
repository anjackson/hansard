require File.dirname(__FILE__) + '/../../spec_helper'

describe "show", " in general" do

  it "have a div containing the title of the index" do
    assigns[:index] = Index.new(:title => "test title", 
                                :start_date => Date.new(2006,11,1), 
                                :end_date => Date.new(2007,1,1))
    render 'indices/show.haml'
    response.should have_tag("div", :text => "test title")
  end
  
end