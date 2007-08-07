require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1985_12_16" do
  before(:all) do
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1985,12,16)
    @sitting_date_text = 'Monday 16 December 1985'
    @sitting_title = 'House of Commons' 
    @sitting_column = '1'
    @sitting_text = %Q[<p id="S6CV0089P0-00360" align="center"><i>The House met at half-past Two o'clock</i></p>]

    @sitting = parse_hansard 's6cv0089p0/housecommons_1985_12_16.xml'
    @sitting.save!
    @oral_questions = @sitting.debates.oral_questions
    @first_questions_section = @sitting.debates.oral_questions.sections.first
    @first_question = @sitting.debates.oral_questions.sections.first.questions.first
    @first_question_contribution = @first_question.contributions.first 
  end

  after(:all) do
    Sitting.delete_all
    Section.delete_all
    Contribution.delete_all
  end

  it 'should create first section in debates' do
    section = @sitting.debates.sections.first
    section.should_not be_nil
    section.should be_an_instance_of(ProceduralSection)
  end

  it 'should set text on first section in debates' do
    @sitting.debates.sections.first.text.should == '<p id="S6CV0089P0-00361" align="center">[MR. SPEAKER <i>in the Chair</i>]</p>'
  end

  it 'should set title on first section in debates' do
    @sitting.debates.sections.first.title.should == 'PRAYERS'
  end

  it 'should set column on first section in debates' do
    @sitting.debates.sections.first.column.should == '1'
  end

  it 'should set xml id on first section in debates' do
    @sitting.debates.sections.first.xml_id.should == 'S6CV0089P0-00361'
  end

  it 'should set debates parent on first section in debates' do
    @sitting.debates.sections.first.parent_section_id.should == @sitting.debates.id
    @sitting.debates.sections.first.parent_section.should == @sitting.debates
  end

  it 'should create oral questions' do
    @oral_questions.should_not be_nil
    @oral_questions.should be_an_instance_of(OralQuestions)
  end

  it 'should set debates parent on oral questions' do
    @oral_questions.parent_section_id.should == @sitting.debates.id
    @oral_questions.parent_section.should == @sitting.debates
  end

  it 'should set title on oral questions' do
    @oral_questions.title.should == 'Oral Answers to Questions'
  end

  it 'should set first section on oral questions' do
    @first_questions_section.should_not be_nil
    @first_questions_section.should be_an_instance_of(OralQuestionsSection)
  end

  it 'should set parent on first oral questions section' do
    @first_questions_section.parent_section_id.should == @oral_questions.id
    @first_questions_section.parent_section.should == @oral_questions
  end

  it 'should set title on first oral question section' do
    @first_questions_section.title.should == 'ENERGY'
  end

  it 'should set first oral question' do
    @first_question.should_not be_nil
    @first_question.should be_an_instance_of(OralQuestionSection)
  end

  it 'should set parent section on first oral question' do
    @first_question.parent_section_id.should == @first_questions_section.id
    @first_question.parent_section.should == @first_questions_section
  end

  it 'should set title on first oral question' do
    @first_question.title.should == 'Scottish Coalfield'
  end

  it 'should set first oral question contribution' do
    @first_question_contribution.should_not be_nil
    @first_question_contribution.should be_an_instance_of(OralQuestionContribution)
  end

  it 'should set parent section on first oral question contribution' do
    @first_question_contribution.section_id.should == @first_question.id
    @first_question_contribution.section.should == @first_question
  end

  it 'should set xml_id on first oral question contribution' do
    @first_question_contribution.xml_id.should == 'S6CV0089P0-00362'
  end

  it 'should set oral question number on first oral question contribution' do
    @first_question_contribution.oral_question_no.should == '1.'
  end

  it 'should set member on first oral question contribution' do
    @first_question_contribution.member.should == 'Mr. Douglas'
  end

  it 'should set member contribution on first oral question contribution' do
    @first_question_contribution.member_contribution.should == 'asked the Secretary of State for Energy if he will make a statement on visits by Ministers in his Department to pits in the Scottish coalfield.'
  end

  it 'should set column on first oral question contribution' do
    @first_question_contribution.column.should == '1'
  end

  it_should_behave_like "All sittings"
  it_should_behave_like "All commons sittings"
end
