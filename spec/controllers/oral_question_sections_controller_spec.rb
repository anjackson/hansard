require File.dirname(__FILE__) + '/../spec_helper'

describe OralQuestionSectionsController, "#route_for" do
  
  it "should map { :controller => 'oral_question_sections', :action => 'show', :id => 5, :format => 'xml' } to /oral_questions/5.xml" do
    route_for(:controller => "oral_question_sections", :action => "show", :id => 5, :format => "xml").should == "/oral_questions/5.xml"
  end
  
end

describe OralQuestionSectionsController, "handling GET /oral_questions/5.xml" do

  before do
    @oral_question_section = mock_model(OralQuestionSection)
    OralQuestionSection.stub!(:find).and_return(@oral_question_section)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "5"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the OralQuestionSection requested" do
    OralQuestionSection.should_receive(:find).with("5").and_return(@oral_question_section)
    do_get
  end
  
end

