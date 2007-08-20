require File.dirname(__FILE__) + '/../../spec_helper'

describe "_section partial", "when passed oral answers" do

  # <oralquestions>
    # <title>Oral Answers to Questions</title>
    # <section>
  before do
    @oral_questions = mock_model(OralQuestions)
    @oral_questions_section = mock_model(OralQuestionsSection)

    @title = 'Oral Answers to Questions'
    sections = [@oral_questions_section]

    @oral_questions.stub!(:title).and_return(@title)
    @oral_questions.stub!(:sections).and_return(sections)
    @oral_questions.stub!(:contributions).and_return([])

    template.expect_render(:partial => 'section', :collection => sections)

    @controller.template.stub!(:section).and_return(@oral_questions)

    render 'commons/_section.haml'
  end

  it 'should show oral answers title as h2' do
    response.should have_tag('h2', @title)
  end
end

describe "_section partial", "when passed an oral answers section" do

  # <section>
    # <title>SOCIAL SECURITY</title>
    # <p><i>The Secretary of State was asked</i>&#x2014;</p>
    # <section>
  before do
    @questions_section = mock_model(OralQuestionsSection)
    @question_section = mock_model(OralQuestionSection)

    @title = 'SOCIAL SECURITY'
    @text = '<i>The Secretary of State was asked</i>&#x2014;'

    @introduction = mock_model(ProceduralContribution)
    @introduction.stub!(:text).and_return '<p>'+@text+'</p>'
    sections = [@question_section]

    @questions_section.stub!(:title).and_return(@title)
    @questions_section.stub!(:introduction).and_return(@introduction)
    @questions_section.stub!(:contributions).and_return([@introduction])
    @questions_section.stub!(:sections).and_return(sections)

    template.expect_render(:partial => 'section', :collection => sections)

    @controller.template.stub!(:section).and_return(@questions_section)

    render 'commons/_section.haml'
  end

  it 'should show oral answers section title as h2' do
    response.should have_tag('h2', @title)
  end

  it 'should show oral answers section introduction as p with class "question_introduction"' do
    response.should have_tag('p.question_introduction', @text.sub('<i>','').sub('</i>',''))
  end
end

describe "_section partial", "when passed a prayers section" do

  # <section>
  #   <title>PRAYERS</title>
  #   <p>[MADAM SPEAKER <i>in the Chair</i>]</p>
  # </section>
  before do

    @prayers = mock_model(Section)
    @procedural = mock_model(ProceduralContribution)

    @title = 'PRAYERS'
    contributions = [@procedural]

    @prayers.stub!(:title).and_return(@title)
    @prayers.stub!(:contributions).and_return(contributions)
    @prayers.stub!(:sections).and_return([])

    template.expect_render(:partial => 'contribution', :collection => contributions)

    @controller.template.stub!(:section).and_return(@prayers)

    render 'commons/_section.haml'
  end

  it 'should show prayers title as h2' do
    response.should have_tag('h2', @title)
  end

end

