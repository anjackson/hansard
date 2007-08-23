require File.dirname(__FILE__) + '/../spec_helper'


describe OralQuestionContribution, " in general" do
  
  before(:each) do
    @model = OralQuestionContribution.new
    @model.stub!(:member).and_return("test member")
    @mock_builder = mock("xml builder")  
    @mock_builder.stub!(:p)
  end
  
  it_should_behave_like "an xml-generating model"
  
end


describe OralQuestionContribution, ".to_xml" do
  
  before do
    @contribution = OralQuestionContribution.new
    @contribution.member = "test member"
  end
  
  it "should return a 'p' tag containing one member tag (and no text) if the oral question contribution has no oral question number" do
    @contribution.oral_question_no = nil
    @contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
    @contribution.to_xml.should have_tag('p member', :count => 1)
  end
  
  it "should return a 'p' tag whose text starts with the oral question contribution number if the oral question contribution has one" do
    the_oral_question_no = "1."
    @contribution.oral_question_no = the_oral_question_no
    @contribution.to_xml.should have_tag('p', :text => /^#{the_oral_question_no}/, :count => 1)
  end
   
  it_should_behave_like "a contribution"
  
end