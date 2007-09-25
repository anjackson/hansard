require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do
  before(:all) do
    file = 'housecommons_questions_not_in_oralquestions_element.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil).parse
    @sitting.save!

  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should create a member contribution for a contribution that has a member element" do
    questions_section = @sitting.sections[2]
    questions_section.title.should == 'NORTHERN IRELAND'
    section = questions_section.sections.first
    section.title.should == 'Security'

    section.contributions.first.should be_an_instance_of(ProceduralContribution)
  end

  it "should add member name for contribution that doesn't have membercontribution element" do
    questions_section = @sitting.sections[2]
    section = questions_section.sections.first

    section.contributions.first.member.should == 'Mr. Michael Latham'
  end

  it "should add question no for contribution that has a question no" do
    questions_section = @sitting.sections[2]
    section = questions_section.sections.first

    section.contributions.first.question_no.should == '1.'
  end

  it "should have contribution text that includes member element" do
    questions_section = @sitting.sections[2]
    section = questions_section.sections.first

    expected = "1. <member>Mr. Michael Latham</member> asked the Secretary of State for Northern Ireland whether he will make a further statement on the security situation."
    section.contributions.first.text.should == expected
  end

end
