require File.dirname(__FILE__) + '/../spec_helper'

describe SittingsHelper, " when getting frequent section titles" do
  
  before do
    @current_date = Date.new(1966, 1, 1)
    @start_date = Date.new(1965, 1, 7)
    @end_date = Date.new(1967, 2, 14)
    stub!(:get_start_date).and_return(@start_date)
    stub!(:get_end_date).and_return(@end_date)
  end
  
  it "should get the start date for the timeline" do
    should_receive(:get_start_date).and_return(@start_date)
    frequent_section_titles(@current_date, nil)  
  end
  
  it "should get the end date for the timeline" do
    should_receive(:get_end_date).and_return(@end_date)
    frequent_section_titles(@current_date, nil)
  end
  
  it "should ask the Section model for the frequent titles in the interval between the start and end date" do
    Section.should_receive(:frequent_titles_in_interval).with(@start_date, @end_date).and_return([])
    frequent_section_titles(@current_date, nil)
  end

end
