require File.dirname(__FILE__) + '/../spec_helper'


describe SectionsHelper, " when using section_nav_links to create links for a section" do
  
  before do
    stub!(:section_url).and_return("http://www.test.url")
    stub!(:sitting_date_url).and_return("http://www.test.url")
    @section = mock_model(Section)
    @sitting = mock_model(Sitting)
    @sitting.stub!(:title).and_return("sitting title")
    @sitting.stub!(:date_text).and_return("sitting date text")
    @section.stub!(:sitting).and_return(@sitting)
    @prev = mock_model(Section)
    @prev.stub!(:linkable?)
    @prev.stub!(:title).and_return("previous section title")
    @next = mock_model(Section)
    @next.stub!(:linkable?)    
    @next.stub!(:title).and_return("next section title")
    @section.stub!(:title).and_return("section name")
    @section.stub!(:previous_linkable_section).and_return(@prev)
    @section.stub!(:next_linkable_section).and_return(@next)  
    assigns[:section] = @section
  end
   
   
  it "should have a link to the sitting showing the sitting's title and date text" do
    section_nav_links(@section).should have_tag("a.section-sitting", :text => "sitting title sitting date text")
  end
  
  it "should not have any text about the previous linkable section if there isn't one" do
    @section.stub!(:previous_linkable_section).and_return(nil)
    section_nav_links(@section).should_not have_tag("a.prev-section")
  end
  
  it "should not have any text about the next section if there isn't one" do
    @section.stub!(:next_linkable_section).and_return(nil)
    section_nav_links(@section).should_not have_tag("a.next-section")
  end
     
  it "should have a link to the previous section if there is one and it is linkable" do
    should_receive(:section_url).with(@prev).and_return("http://www.test-prev.url")      
    section_nav_links(@section).should have_tag("a.prev-section[href=http://www.test-prev.url]", :text => "previous section title")
  end
  
  it "should have a link to the next section if there is one and it is linkable" do 
    should_receive(:section_url).with(@next).and_return("http://www.test-next.url")      
    section_nav_links(@section).should have_tag("a.next-section[href=http://www.test-next.url]", :text => "next section title")
  end
  
end