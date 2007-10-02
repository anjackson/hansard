require File.dirname(__FILE__) + '/../../spec_helper'

describe "_section partial", " in general" do

  it "should ask the section assigned to it for it's marker html" do
    section = mock_model(Section)
    section.stub!(:title).and_return("My fake title")
    section.stub!(:title_for_linking).and_return("transport_(parking)")
    section.stub!(:title_cleaned_up).and_return("")
    section.stub!(:sections).and_return([])
    section.stub!(:contributions).and_return([])
    @controller.template.stub!(:section).and_return(section)
    @controller.template.should_receive(:marker_html).and_return("")
    render 'sections/_section.haml'
  end

  it "should show timestamps with valid datetimes in the wrapping tag"

end


describe "_section_partial", " when passed an oral questions section with contributions" do

  before do
    @oral_questions = mock_model(OralQuestionsSection)

    @oral_questions.stub!(:markers)
    @oral_questions.stub!(:title_cleaned_up)
    @oral_questions.stub!(:title_for_linking).and_return("test")
    @oral_questions.stub!(:contributions).and_return([])
    @oral_questions.stub!(:sections).and_return([])

    @controller.template.stub!(:section).and_return(@oral_questions)
  end

  def do_render
    render 'sections/_section.haml'
  end

  it "should show an introduction if there is one and when a title is present" do
    @introduction = mock("intro model")
    @oral_questions.stub!(:title).and_return("Some title")
    @introduction.stub!(:text).and_return("introduction text")
    @oral_questions.stub!(:introduction).and_return(@introduction)
    do_render
    response.should have_tag("p[class=question_introduction]", :text => "introduction text")
  end

  it "should show an introduction if there is one even when a title is present but has no text" do
    @introduction = mock("intro model")
    @oral_questions.stub!(:title).and_return("")
    @introduction.stub!(:text).and_return("introduction text")
    @oral_questions.stub!(:introduction).and_return(@introduction)
    do_render
    response.should have_tag("p[class=question_introduction]", :text => "introduction text")
  end

  it "should show the contributions when a title is present" do
    contribution = mock_model(Contribution)
    @oral_questions.stub!(:title)
    @oral_questions.stub!(:introduction)
    @oral_questions.stub!(:contributions).and_return([contribution])
    @controller.template.stub!(:render)
    @controller.template.should_receive(:render).with(:partial => 'contribution', :collection => @oral_questions.contributions)
    do_render
  end

  it "should show the contributions even when a title is present but has no text" do
    contribution = mock_model(Contribution)
    @oral_questions.stub!(:title).and_return("")
    @oral_questions.stub!(:introduction)
    @oral_questions.stub!(:contributions).and_return([contribution])
    @controller.template.stub!(:render)
    @controller.template.should_receive(:render).with(:partial => 'contribution', :collection => @oral_questions.contributions)
    do_render
  end

end