require File.dirname(__FILE__) + '/../../spec_helper'

describe "/oral_question_sections/show.rxml" do
  include OralQuestionSectionsHelper
  
  before do
    @oral_question_section = mock_model(OralQuestionSection)
    assigns[:oral_question_section] = @oral_question_section
  end
<<<<<<< .mine

  it "should render the 'oral_question_section' template once" do 
    @controller.template.should_receive(:render).and_return(nil)
    render "/oral_question_sections/show.rxml"
  end
=======
  # 
  # it "should render the 'oral_question_section' partial once" do 
  #   @controller.template.should_receive(:render).with(:partial => "oral_question_section").and_return(nil)
  #   render "/oral_question_sections/show.rxml"
  # end
>>>>>>> .r1458
  
end

