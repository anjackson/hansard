require File.dirname(__FILE__) + '/../spec_helper'

describe SittingsHelper, ' when getting section occurrences' do 

  before do
    @section = mock_model(Section)
    @section.stub!(:month)
    Section.stub!(:find_by_title_in_interval).and_return([@section])
  end
  
  it 'should group the sections by month when the resolution is year' do
    @section.should_receive(:month).and_return(1)
    section_occurrences("test", Time.now, Time.now, :year) do |label, sections|
      label.should == "January"
    end
  end
  
  it 'should group the sections by date when the resolution is month' do
    @section.should_receive(:date).and_return(Date.new(2006, 6, 5))
    section_occurrences("test", Time.now, Time.now, :month) do |label, sections|
      label.should == "5 Jun"
    end
  end
  
  it 'should group the sections by year when the resolution is not month or year ' do
    @section.should_receive(:year).and_return(1884)
    section_occurrences("test", Time.now, Time.now, nil) do |label, sections|
      label.should == '1884'
    end
  end
    
end

describe SittingsHelper, ' when getting frequent section links' do
  
  before do
    @section = mock_model(Section)
    @section.stub!(:first_member)
    stub!(:section_url).and_return("http://test.url")
  end
  
  it 'should group the sections by the first member to speak' do
    @section.should_receive(:first_member)
    frequent_section_links([@section])
  end
  
  it 'should give the member as "[No speaker]" when the first member is nil' do 
    @section.should_receive(:first_member)
    frequent_section_links([@section]).should match(/[No speaker]/)
  end
  
  it 'should give comma-separated numbered links to each section for a member' do
    expected = '[<a href=\"http://test.url\">1<\/a>, <a href="http://test.url">2</a>]'
    frequent_section_links([@section, @section]).should match(/#{expected}/)
  end
  
end

describe SittingsHelper, ' when returning links for the timeline intervals' do

  it 'should generate a link to show the sittings for the decade if the resolution is century' do
    link = '<a href="/sittings/1920s">1920s</a>'
    link_for("1920s", :century, [1,0], {}).should match(/#{link}/)
  end
  
  it 'should delegate to the timeline plugin code otherwise' do 
    should_receive(:timeline_link_for).with("1921", nil, [1,0], {})
    link_for("1921", nil, [1,0], {})
  end

end