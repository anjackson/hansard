require File.dirname(__FILE__) + '/../spec_helper'

def create_sitting type
  section = Section.new(:start_column => 1292,
                        :end_column => 1292,
                        :title => "a test section")
  group = WrittenAnswersGroup.new(:sections => [section])
  sitting = type.new(:all_sections => [group],
                     :date => Date.new(1938, 7, 29))
  group.sitting = sitting
  section.sitting = sitting
  sitting.save!
  sitting
end

describe WrittenAnswersSitting do

  describe 'when asked for each section' do
    before do
      @answers = WrittenAnswersSitting.new
    end

    describe 'and has a WrittenAnswersGroup section' do
      it 'should yield body section of each section in WrittenAnswersGroup' do
        body_section = mock('body_section')
        group = mock_model(WrittenAnswersGroup, :sections=>[body_section])

        @answers.should_receive(:all_sections).and_return [group]

        @answers.each_section do |section|
          section.should == body_section
        end
      end
    end
    describe 'and has a non-WrittenAnswersGroup section' do
      it 'should yield the section' do
        section = mock('section')

        @answers.should_receive(:all_sections).and_return [section]

        @answers.each_section do |a_section|
          a_section.should == section
        end
      end
    end
  end

  describe "when finding answers sittings by column and date" do


    def expect_section sitting
      section = WrittenAnswersSitting.find_section_by_column_and_date('1292', '1938-07-29')
      section.should_not be_nil
      section.should == sitting.groups.first.sections.first
    end

    it 'should find a written answers section with no house' do
      @answers = create_sitting(WrittenAnswersSitting)
      expect_section @answers
    end

    it 'should find a lords written answers section' do
      @lords_answers = create_sitting(LordsWrittenAnswersSitting)
      expect_section @lords_answers
    end

    it 'should find lords written answers section' do
      @commons_answers = create_sitting(CommonsWrittenAnswersSitting)
      expect_section @commons_answers
    end
  end

  describe "when finding sittings in a given interval" do

    it 'should find lords written answers' do
      @lords_answers = create_sitting(LordsWrittenAnswersSitting)
      WrittenAnswersSitting.find_in_resolution(Date.new(1938, 7, 29), :year).should == [@lords_answers]
    end

    it 'should find commons written answers'  do
      @commons_answers = create_sitting(CommonsWrittenAnswersSitting)
      WrittenAnswersSitting.find_in_resolution(Date.new(1938, 7, 29), :year).should == [@commons_answers]
    end

    it 'should find written answers with no house' do
      @answers = create_sitting(WrittenAnswersSitting)
      WrittenAnswersSitting.find_in_resolution(Date.new(1938, 7, 29), :year).should == [@answers]
    end
  end

  describe '.sitting_type_name' do
    it 'should be Written Answers' do
      WrittenAnswersSitting.new.sitting_type_name.should == 'Written Answers'
    end
  end
  
  describe ' when rendering sitting as xml' do 
  
    it 'should render a title tag containing the escaped title' do 
      written_answers_sitting = WrittenAnswersSitting.new(:title => 'Test & Title', 
                                                          :date => Date.new(1812,1,1))
      written_answers_sitting.to_xml.should have_tag('title', :text => 'Test &amp; Title')
    end
    
  end

  describe ".top_level_sections" do
    it "should return the sitting's groups" do
      sitting = WrittenAnswersSitting.new
      group = WrittenAnswersGroup.new
      sitting.groups << group
      sitting.top_level_sections.should == [group]
    end
  end
end
