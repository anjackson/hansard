require File.dirname(__FILE__) + '/../spec_helper'

module SectionSpecHelper

  def create_section title, sitting, parent, model_class=Section
    section = model_class.create(:title => title, :sitting_id => sitting.id, :parent_section_id => (parent ? parent.id : nil) )
    section.parent_section = parent if parent
    section
  end

  def make_written_answers
    @answers = WrittenAnswersSitting.create
    @parent_answer = create_section 'TRANSPORT', @answers, nil
    @first_answer  = create_section 'Heavy Goods Vehicles (Public Weighbridge Facilities)', @answers, @parent_answer
    @second_answer = create_section 'Driving Licences (Overseas Recognition)', @answers, @parent_answer
    @third_answer  = create_section 'Public Boards (Appointments)', @answers, @parent_answer
    @solo_answer   = create_section 'HEALTH', @answers, nil

    @parent_answer.sections = [@first_answer, @second_answer, @third_answer]
    @answers.sections = [@parent_answer, @solo_answer]
    @answers.save!
  end

  def make_sitting_with_oral_answers
    @sitting = HouseOfCommonsSitting.create
    @debates = Debates.create(:sitting_id => @sitting.id)
    @debates.sitting = @sitting
    @sitting.debates = @debates
    @sitting.sections = [@debates]
    @sitting.save!
    @oral_questions = create_section 'ORAL QUESTIONS', @sitting, @debates, OralQuestions
    @oral_questions_section = create_section 'TRANSPORT', @sitting, @oral_questions, OralQuestionsSection
    @first_question  = create_section 'Heavy Goods Vehicles (Public Weighbridge Facilities)', @sitting, @oral_questions_section, OralQuestionSection
    @second_question = create_section 'Driving Licences (Overseas Recognition)', @sitting, @oral_questions_section, OralQuestionSection
    @third_question  = create_section 'Public Boards (Appointments)', @sitting, @oral_questions_section, OralQuestionSection

    @oral_questions_section.sections = [@first_question, @second_question, @third_question]
    @oral_questions.sections = [@oral_questions_section]
    @debates.sections = [@oral_questions]
    @sitting.save!
  end

  def make_sitting
    @sitting = HouseOfCommonsSitting.create
    @debates = Debates.create(:sitting_id => @sitting.id)
    @debates.sitting = @sitting
    @sitting.debates = @debates
    @sitting.sections = [@debates]
    @sitting.save!
    @parent = create_section 'TRANSPORT', @sitting, @debates
    @first  = create_section 'Heavy Goods Vehicles (Public Weighbridge Facilities)', @sitting, @parent
    @second = create_section 'Driving Licences (Overseas Recognition)', @sitting, @parent
    @third  = create_section 'Public Boards (Appointments)', @sitting, @parent
    @solo   = create_section 'HEALTH', @sitting, @debates

    @parent.sections = [@first, @second, @third]
    @debates.sections = [@parent, @solo]
    @sitting.save!
  end

  def destroy_sitting
    Sitting.find(:all).each {|s| s.destroy}
  end
end
