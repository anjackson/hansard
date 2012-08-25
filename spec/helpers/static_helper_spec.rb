require File.dirname(__FILE__) + '/../spec_helper'
include ApplicationHelper
include StaticHelper

describe StaticHelper, "when asked for an example api url" do 

  it 'should return a url with host and port' do 
    example_api_url.should == 'http://test.host/sittings/2002/apr/16'
  end
  
end