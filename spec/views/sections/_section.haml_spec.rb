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

describe "_section partial", " when passed oral answers" do

  # <oralquestions>
    # <title>Oral Answers to Questions</title>
    # <section>
  before do
    @oral_questions = mock_model(OralQuestions)
    @oral_questions_section = mock_model(OralQuestionsSection)
    @oral_questions_section.stub!(:markers)
    @title = 'Oral Answers to Questions'
    @title_for_linking = 'oral_answers_to_questions'
    sections = [@oral_questions_section]

    @oral_questions.stub!(:markers)
    @oral_questions.stub!(:title_cleaned_up)
    @oral_questions.stub!(:title).and_return(@title)
    @oral_questions.stub!(:title_for_linking).and_return(@title_for_linking)
    @oral_questions.stub!(:sections).and_return(sections)
    @oral_questions.stub!(:contributions).and_return([])

    template.expect_render(:partial => 'section', :collection => sections)

    @controller.template.stub!(:section).and_return(@oral_questions)

    render 'sections/_section.haml'
  end

  it 'should show oral answers title as h2'
  
end


describe "_section partial", " when passed an oral answers section" do

  # <section>
    # <title>SOCIAL SECURITY</title>
    # <p><i>The Secretary of State was asked</i>&#x2014;</p>
    # <section>
  before do
    @questions_section = mock_model(OralQuestionsSection)
    @question_section = mock_model(OralQuestionSection)

    @title = 'SOCIAL SECURITY'
    @title_for_linking = 'social_security'
    @text = '<i>The Secretary of State was asked</i>&#x2014;'

    @introduction = mock_model(ProceduralContribution)
    
    @introduction.stub!(:text).and_return '<p>'+@text+'</p>'
    sections = [@question_section]
    
    @questions_section.stub!(:markers)
    @questions_section.stub!(:title_cleaned_up)
    @questions_section.stub!(:title_for_linking).and_return(@title_for_linking)
    @questions_section.stub!(:introduction).and_return(@introduction)
    @questions_section.stub!(:contributions).and_return([@introduction])
    @questions_section.stub!(:sections).and_return(sections)

    template.expect_render(:partial => 'section', :collection => sections)

    @controller.template.stub!(:section).and_return(@questions_section)

    render 'sections/_section.haml'
  end

  it 'should show oral answers section title as h2'

  it 'should show oral answers section introduction as p with class "question_introduction"'
  
end

describe "_section partial", " when passed a prayers section" do

  # <section>
  #   <title>PRAYERS</title>
  #   <p>[MADAM SPEAKER <i>in the Chair</i>]</p>
  # </section>
  before do

    @prayers = mock_model(Section)
    @procedural = mock_model(ProceduralContribution)

    @title = 'PRAYERS'
    @title_for_linking = 'prayers'
    contributions = [@procedural]

    @prayers.stub!(:markers)
    @prayers.stub!(:title_cleaned_up)
    @prayers.stub!(:title_for_linking).and_return(@title_for_linking)
    @prayers.stub!(:contributions).and_return(contributions)
    @prayers.stub!(:sections).and_return([])

    template.expect_render(:partial => 'contribution', :collection => contributions)

    @controller.template.stub!(:section).and_return(@prayers)

    render 'sections/_section.haml'
  end

  it 'should show prayers title as h2'

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