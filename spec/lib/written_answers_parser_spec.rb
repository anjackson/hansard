require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::WrittenAnswersParser, " when run against 'spec/data/writtenanswers_example.xml'" do

  before(:all) do
    file = 'writtenanswers_example.xml'
    @sitting_part_id = 1
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

    @first_contribution  = @first_body.contributions[0]
    @second_contribution = @first_body.contributions[1]
    @third_contribution  = @first_body.contributions[2]

  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should create groups for the sitting" do
    @sitting.groups.size.should > 0
  end

  it "should correctly set the title for the first group of questions" do
    @first_group.title.should == 'AGRICULTURE, FISHERIES AND FOOD'
  end

  it "should create the right number of sections for the first group of questions" do
    @first_group.sections.size.should == 5
  end

  it "should correctly set the title for the first question" do
    @first_section.title.should == 'Food Storage'
  end

  it "should create a body section belonging to the first question section" do
    @first_section.sections.size.should == 1
    @first_body.should be_an_instance_of(WrittenAnswersBody)
  end

  it "should create three member contributions for the first body section" do
    @first_body.contributions.size.should == 3
  end

  it "should set the xml_id correctly on each contribution for the first body section" do
    @first_contribution.xml_id.should == "S6CV0089P0-04896"
    @second_contribution.xml_id.should == "S6CV0089P0-04897"
    @third_contribution.xml_id.should == "S6CV0089P0-04898"
  end

  it "should create the first contribution as a procedural contribution" do
    @first_contribution.should be_an_instance_of(ProceduralContribution)
  end

  it "should create the second contribution as a member contribution" do
    @second_contribution.should be_an_instance_of(WrittenMemberContribution)
  end

  it "should set the member correctly on the member contribution" do
    @second_contribution.member.should == 'Mr. Gummer'
  end

  it "should create the third contribution as a procedural contribution" do
    @third_contribution.should be_an_instance_of(ProceduralContribution)
  end

  it "should set the text correctly for the first contribution" do
    @first_contribution.text.should == "Mr. Canavan asked the Minister of Agriculture, Fisheries and Food what is his latest available information on the amount of surplus food stored <i>(a)</i> in the United Kingdom and <i>(b)</i> in the European Economic Community and the costs of storage."
  end

  it "should set the text correctly for the second contribution" do
    @second_contribution.text.should == ": A note setting out the volume of United Kingdom and Community intervention stocks, including those of foodstuffs, on the latest available dates is deposited in the Library of the House and is updated monthly."
  end

  it "should set the text correctly for the third contribution" do
    @third_contribution.text.should == "The storage, handling and related costs of United Kingdom intervention products (including barley and feedwheat) in 1984 were &#x00A3;46&#x00B7;4 million. We have no figures for storage costs incurred by other member states."
  end

  it_should_behave_like "All sittings or written answers"
  
end