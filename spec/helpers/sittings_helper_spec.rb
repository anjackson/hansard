require File.dirname(__FILE__) + '/../spec_helper'

describe SittingsHelper do 
  
  before do 
    self.class.send(:include, ApplicationHelper)
    self.class.send(:include, SittingsHelper)
  end

  describe ' when returning links for the timeline intervals' do

    it 'should generate a link to show the sittings for the decade if the resolution is decade' do
      link = '<a href="/sittings/1920s">1920s</a>'
      link_for("1920s", :decade, [1,0], {}).should match(/#{link}/)
    end

    it 'should generate a link to show the commons sittings for the decade if the resolution is decade' do
      link = '<a href="/commons/1920s">1920s</a>'
      link_for("1920s", :decade, [1,0], {:sitting_type => HouseOfCommonsSitting}).should match(/#{link}/)
    end

    it 'should generate a link to show the sittings for the year if the resolution is year' do
      link = '<a href="/sittings/1921">1921</a>'
      link_for("1921", :year, [1,0], {}).should match(/#{link}/)
    end

    it 'should generate a link to show the commons sittings for the year if the resolution is year' do
      link = '<a href="/commons/1921">1921</a>'
      link_for("1921", :year, [1,0], {:sitting_type => HouseOfCommonsSitting}).should match(/#{link}/)
    end

    it 'should generate a link to show the sittings for the month if the resolution is month' do
      link = '<a href="/sittings/1921/dec">Dec</a>'
      link_for("1921_12", :month, [1,0], {}).should match(/#{link}/)
    end

    it 'should generate a link to show the commons sittings for the month if the resolution is month' do
      link = '<a href="/commons/1921/dec">Dec</a>'
      link_for("1921_12", :month, [1,0], {:sitting_type => HouseOfCommonsSitting}).should match(/#{link}/)
    end

    it 'should generate a link to show the sittings for the day if the resolution is day' do
      link = '<a href="/sittings/1921/dec/11">11</a>'
      link_for(Date.new(1921,12,11), :day, [1,0], {}).should match(/#{link}/)
    end

    it 'should generate a link to show the commons sittings for the day if the resolution is day' do
      link = '<a href="/commons/1921/dec/11">11</a>'
      link_for(Date.new(1921,12,11), :day, [1,0], {:sitting_type => HouseOfCommonsSitting}).should match(/#{link}/)
    end

  end

  describe " when generating sittings timelines" do

    it 'should create a timeline, passing the sitting type' do
      should_receive(:timeline_options).with(:day, HouseOfCommonsSitting).and_return({})
      stub!(:timeline)
      sitting_timeline(Date.new(1921,12,11), :day, HouseOfCommonsSitting)
    end

    it 'should get a timeline with top label "Sittings by decade"' do
       stub!(:timeline_options).and_return({})
       date = Date.new(1921,12,11)
       should_receive(:timeline).with(date, :decade, {:top_label => "Sittings by decade"})
       sitting_timeline(date, :decade, Sitting)
     end

  end

  describe 'when generating a link to a section a number of years ago' do 
  
    before do 
      stub!(:section_url).and_return('http://test.host')
      @section = mock_model(Section, :title_via_associations => 'test title')
    end
    
    it 'should ask for a section from the number of years ago' do 
      Sitting.should_receive(:section_from_years_ago).with(10).and_return(@section)
      link_to_section_years_ago(10)
    end
    
    it 'should return a link to the section url whose text is the section title via associations' do 
      Sitting.stub!(:section_from_years_ago).and_return(@section)
      link_to_section_years_ago(10).should have_tag('a[href=http://test.host]', :text => 'test title')
    end
    
    it 'should return an empty string if there are no sections' do 
      Sitting.stub!(:section_from_years_ago).and_return(nil)
      link_to_section_years_ago(10).should == ''
    end
    
  end
  
end