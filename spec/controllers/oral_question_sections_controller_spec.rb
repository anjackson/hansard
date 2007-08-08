require File.dirname(__FILE__) + '/../spec_helper'

describe OralQuestionSectionsController, "#route_for" do
  
  it "should map { :controller => 'oral_question_sections', :action => 'show', :id => 5, :format => 'xml' } to /oral_questions/5.xml" do
    route_for(:controller => "oral_question_sections", :action => "show", :id => 5, :format => "xml").should == "/oral_questions/5.xml"
  end
  
end
