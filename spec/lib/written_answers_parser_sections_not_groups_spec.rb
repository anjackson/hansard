require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::WrittenAnswersParser, " when run against 'spec/data/writtenanswers_example.xml'" do

  before(:all) do
    file = 'writtenanswers_with_sections_at_top_level.xml'
    @sitting = Hansard::WrittenAnswersParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil).parse
    @sitting.save!

    @sitting_type = WrittenAnswersSitting
    @sitting_date = Date.new(1985,12,16)
    @sitting_date_text = 'Monday 16 December 1985'
    @sitting_title = 'Written Answers to Questions'
    @sitting_start_column = '1'
    @sitting_start_image = 'S6CV0089P0I0719'
    @sitting_text = nil

    @first_group   = @sitting.groups.first
    @first_section = @first_group.sections.first
    @first_body    = @first_section.sections.first

  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should create the correct number groups for a sitting" do
    @sitting.groups.size.should == 1
  end

  it "should set the title correctly for a question group" do
    @first_group.title.should == 'AGRICULTURE, FISHERIES AND FOOD'
  end

  it "should create the correct number of sections for a question group" do
    @first_group.sections.size.should == 2
  end

  it "should set the title correctly for a question section" do
    @first_section.title.should == 'Food Storage'
  end

  it "should set model type to Section for a question section" do
    @first_section.should be_an_instance_of(Section)
  end

  it "should create a body section belonging to a question section" do
    @first_section.sections.size.should == 1
    @first_body.should be_an_instance_of(WrittenAnswersBody)
  end

  it "should have body section title equal to body's parent section title" do
    @first_body.title.should == 'Food Storage'
  end

  it_should_behave_like "All sittings or written answers"

end