require File.dirname(__FILE__) + '/../../spec_helper'

describe "/oral_question_sections/_oral_question_section.rxml" do
  include OralQuestionSectionsHelper
  
  before do
    @oral_question_section = mock_model(OralQuestionSection)
    assigns[:oral_question_section] = @oral_question_section
    @oral_question_section.stub!(:title)
  end

  it "should contain one and only one 'title' tag within a 'section' tag" do 
    render "/oral_question_sections/_oral_question_section.rxml"
    response.should have_tag("section title", :count => 1) 
  end
  
end

