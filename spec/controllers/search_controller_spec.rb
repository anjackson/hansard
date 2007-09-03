require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do
  integrate_views

  it "should return index page" do
    get 'index'
    response.should be_success
  end
  
end
