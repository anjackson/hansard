require File.dirname(__FILE__) + '/../spec_helper'
include ConstituenciesHelper

describe ConstituenciesHelper, " when returning a link to a constituency" do 
  
  before do 
    @constituency = mock_model(Constituency, {:name => "Dover West"})
    stub!(:constituency_url).and_return("http://www.test.host")
  end

  it 'should return text in the form "<a href=\'http://www.test.host\'>Dover West</a> if asked for a link to a constituency' do 
    constituency_link(@constituency).should == '<a href="http://www.test.host">Dover West</a>'
  end
  
end
