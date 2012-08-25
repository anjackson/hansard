require File.dirname(__FILE__) + '/../spec_helper'
include OfficesHelper

describe OfficesHelper, " when activating links in text " do
   
  it 'should transform "http://www.test.url" into a link' do
    activate_links("http://www.test.url").should have_tag("a[href=http://www.test.url]", :text => "http://www.test.url")
  end

  it 'should transform "https://www.test.url" into a link' do
    activate_links("https://www.test.url").should have_tag("a[href=https://www.test.url]", :text => "https://www.test.url")
  end

end

describe OfficesHelper, ' when giving info on a member in the merge set' do
  
  it 'should return text in the format "CHANCELLOR OF THE EXCHEQUER 26 occurrences"' do 
    office = mock("office", :name => "CHANCELLOR OF THE EXCHEQUER", :id => 5)
    Office.stub!(:find).with(5).and_return(office)
    merge_office_info(5, 26).should == "CHANCELLOR OF THE EXCHEQUER 26 occurrences"
  end

end
