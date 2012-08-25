require File.dirname(__FILE__) + '/../../spec_helper'

describe '_member_contribution partial' do

  before do
    @contribution_text = ': What assessment he has made of the responses to the pensions Green Paper received to date. [68005]'
    @contribution = mock_model(MemberContribution, :null_object => true,
                                                   :member_name => 'Mr. David Borrow',
                                                   :text => @contribution_text,
                                                   :xml_id => nil,
                                                   :anchor_id => 'anchor',
                                                   :question_no => nil,
                                                   :prefix => nil,
                                                   :procedural_note => nil,
                                                   :member_suffix => nil,
                                                   :commons_membership => nil)
    @controller.template.stub!(:contribution).and_return(@contribution)
    assigns[:marker_options] = {}
  end

  it 'should show member contribution in div.member_contribution, blockquote.contribution_text and p elements' do
    render :partial => 'sections/member_contribution.haml', :object => @contribution
    response.should have_tag('div.member_contribution') do
      with_tag('blockquote.contribution_text') do
        with_tag('p.first-para', @contribution_text.sub(':','').strip )
      end
    end
  end

  it 'should show a question number of "22" within a span with class "question_no" when given a question number of "22."' do
    @contribution.stub!(:question_no).and_return('22')
    render :partial => 'sections/member_contribution.haml', :object => @contribution
    response.should have_tag('span.question_no', :text => '22')
  end

  it 'should show member written contribution containing multiple paragraphs in div.member_contribution, blockquote.contribution_text and p elements' do
    first_paragraph_text = 'A note setting out the volume of United Kingdom and Community'
    second_paragraph_text = 'The storage, handling and related costs of United Kingdom intervention'
    text = %Q[<p id="S6CV0089P0-04897">#{first_paragraph_text}</p>] +
        %Q[<p id="S6CV0089P0-04898">The storage, handling and related costs of United Kingdom intervention </p>]
    @contribution.stub!(:text).and_return text
    @contribution.stub!(:is_a?).with(WrittenMemberContribution).and_return true
    @contribution.stub!(:person).and_return Person.new
    render :partial => 'sections/member_contribution.haml', :object => @contribution
    response.should have_tag('div.member_contribution') do
      with_tag('blockquote.contribution_text') do
        with_tag('p.first-para', first_paragraph_text )
        with_tag('p#S6CV0089P0-04897', first_paragraph_text )
        with_tag('p#S6CV0089P0-04898', second_paragraph_text )
      end
    end
  end
end
