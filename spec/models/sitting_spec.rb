require File.dirname(__FILE__) + '/../spec_helper'

describe Sitting, ' uri_component_to_sitting_model' do
  it 'should return HouseOfCommonsSitting when passed "commons"' do
    Sitting.uri_component_to_sitting_model('commons').should == HouseOfCommonsSitting
  end

  it 'should return HouseOfLordsSitting when passed "lords"' do
    Sitting.uri_component_to_sitting_model('lords').should == HouseOfLordsSitting
  end

  it 'should return WrittenAnswersSitting when passed "written_answers"' do
    Sitting.uri_component_to_sitting_model('written_answers').should == WrittenAnswersSitting
  end
end

describe Sitting do

  before(:each) do
    @session = ParliamentSession.new
    @session.save!
    @sitting = Sitting.new :parliament_session_id => @session.id
  end

  after do
    ParliamentSession.delete_all
  end

  it "should be valid" do
    @sitting.should be_valid
  end

  it 'should be associated with parliament session' do
    @sitting.parliament_session.should == @session
  end

  it "should be able to tell if it is present on a date" do
    Sitting.respond_to?("present_on_date?").should == true
  end

end

describe Sitting, ".first_image_source" do

  it "should return the first image source " do
    sitting = Sitting.new(:start_image_src => "image2")
    sitting.first_image_source.should == "image2"
  end

  it "should return nil if the sitting has no image sources" do
    sitting = Sitting.new(:start_image_src => nil)
    sitting.first_image_source.should be_nil
  end

end

describe Sitting, ".find_in_resolution" do

  before do
    @date = Date.new(2006, 12, 18)
    @first_sitting = Sitting.new(:date => @date)
    @second_sitting = Sitting.new(:date => @date)
    @third_sitting = Sitting.new(:date => @date)
  end

  it "should return all sittings on a date if passed a date and the resolution :day" do
    Sitting.stub!(:find_all_present_on_date).and_return([@first_sitting, @second_sitting, @third_sitting])
    Sitting.find_in_resolution(@date, :day).should == [@first_sitting, @second_sitting, @third_sitting]
  end

end

describe HouseOfCommonsSitting, '.find_section_by_column_and_date' do
  it 'should return correct section' do
    date = Date.new(2006,1,1)
    sitting = HouseOfCommonsSitting.create(:date => date, :start_column => '44', :end_column => '50')
    section = Section.new(:start_column => '44', :end_column => '47')
    sitting.sections << section
    sitting.save!
    HouseOfCommonsSitting.find_section_by_column_and_date('44', date).should == section
  end

  after do
    Sitting.delete_all
    Section.delete_all
  end
end

describe Sitting, ".find_section_by_column_and_date_range" do

  before do
    @start_date = Date.new(2006,1,1)
    @end_date = Date.new(2007,1,1)
    @first_sitting = Sitting.create(:date => Date.new(2006, 6, 6), :start_column => "44")
    @first_section = Section.new(:start_column => "44")
    @first_sitting.sections << @first_section
    @second_sitting = Sitting.create(:date => Date.new(2006, 6, 6), :start_column => "55")
    @second_section = Section.new(:start_column => "55")
    @second_sitting.sections << @second_section
  end

  after do
    Sitting.delete_all
    Section.delete_all
  end

  it "should return the correct section for a column that is the start column of a sitting" do
    Sitting.find_section_by_column_and_date_range(44, @start_date, @end_date).should == @first_section
    Sitting.find_section_by_column_and_date_range(55, @start_date, @end_date).should == @second_section
  end

  it "should return the correct section for a column that is within a sitting" do
    Sitting.find_section_by_column_and_date_range(45, @start_date, @end_date).should == @first_section
    Sitting.find_section_by_column_and_date_range(56, @start_date, @end_date).should == @second_section
  end

end

