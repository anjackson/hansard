require File.dirname(__FILE__) + '/../../spec_helper'

describe "/oral_question_sections/show.rxml" do
  include OralQuestionSectionsHelper
  
  before do
    @oral_question_section = mock_model(OralQuestionSection)
    assigns[:oral_question_section] = @oral_question_section
  end


end

