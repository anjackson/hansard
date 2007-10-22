require File.dirname(__FILE__) + '/../../spec_helper'

describe "_contribution partial", " in general" do

  it "should ask the contribution assigned to it for it's marker html" do
    contribution = mock_model(Contribution)
    contribution.stub!(:text).and_return("")
    @controller.template.stub!(:contribution).and_return(contribution)
    @controller.template.should_receive(:marker_html).and_return("")
    render 'sections/_contribution.haml'
  end

end

describe '_contribution partial', 'when passed table contribution' do

  before do
    @text = %Q[<table type="span">\n          <tr>\n            <td align="right"><i>Unsecured Loans</i></td>\n            <td></td>\n          </tr>\n        </table>]
    @table = mock_model(TableContribution)
    @table.should_receive(:text).and_return @text
    @table.should_receive(:markers)
    @table.should_receive(:xml_id).and_return "xml id"
    @controller.template.stub!(:contribution).and_return @table
    render 'sections/_contribution.haml'
  end

  it 'should show table text "as is" within a div with class table and id being the xml_id of the contribution' do
    response.should have_tag('div.table[id=xml id]') do
      with_tag('table') do
        with_tag('tr') do
          with_tag('td') do
            with_tag('i', 'Unsecured Loans')
          end
        end
      end
    end
  end

end

describe '_contribution partial', 'when passed quote contribution' do

  before do
    @text = ': <quote>"That Sir Antony Buck and Mr. Robert Key be discharged from the Select Committee on the Armed Forces Bill and that Mr. Tony Baldry and Mr. Nicholas Soames be added to the Committee."</quote>&#x2014;<i>(Mr. Maude.]</i>'
    @quote = mock_model(QuoteContribution)
    @quote.should_receive(:text).and_return @text
    @quote.should_receive(:markers)
    @quote.stub!(:word_count).and_return 0
    @quote.should_receive(:xml_id).and_return "xml id"
    @controller.template.stub!(:contribution).and_return @quote
    render 'sections/_contribution.haml'
  end

  it 'should show quote text in q with class quote and id being the xml_id of the contribution' do
    response.should have_tag('q.quote[id=xml id]', @text.sub(': ','').sub('<i>','').sub('</i>','').gsub('"','').sub('<quote>','').sub('</quote>','').squeeze(' '))
  end

  it 'should show italic text in italics' do
    response.should have_tag('i', '(Mr. Maude.]')
  end
end

describe '_contribution partial', 'when passed time contribution' do

  before do
    @text = '3.30 pm'

    @time = mock_model(TimeContribution)
    @time.should_receive(:markers)
    @time.should_receive(:text).and_return @text
    @time.should_receive(:timestamp).and_return Time.parse('1985-12-16T15:30:00').xmlschema
    @controller.template.stub!(:contribution).and_return @time

    render 'sections/_contribution.haml'
  end

  it 'should have div with class time' do
    response.should have_tag('div.time')
  end

  it 'should have abbr with class dtstart nested in div with class time' do
    response.should have_tag('div.time abbr.dtstart')
  end

  it 'should show time text in abbr element' do
    response.should have_tag('div.time abbr.dtstart', @text)
  end

  it 'should show timestamp in in title attribute of abbr element' do
    response.should have_tag('div.time abbr[title="1985-12-16T15:30:00+00:00"]')
  end

end


describe '_contribution partial', 'when passed procedural contribution' do

  before do
    @text = '[MADAM SPEAKER <i>in the Chair</i>]'

    @procedural = mock_model(ProceduralContribution)
    @procedural.should_receive(:markers)
    @procedural.should_receive(:text).and_return @text
    @procedural.should_receive(:xml_id).and_return "xml id"
    @controller.template.stub!(:contribution).and_return @procedural

    render 'sections/_contribution.haml'
  end

  it 'should show speaker in chair as div with class procedural' do
    response.should have_tag('div.procedural', '[MADAM SPEAKER in the Chair]')
  end
  
  it 'should show the content of the contribution in a div whose id is the xml_id of the contribution' do
    response.should have_tag('div[id=xml id]', :text => "[MADAM SPEAKER in the Chair]")
  end

end

describe '_section partial', 'when passed members contribution with question_no, constituency and procedural note' do

  # <p>1. <member>Mr. David Borrow <memberconstituency>(South Ribble)</memberconstituency></member><membercontribution>: What assessment he has made of the responses to the pensions Green Paper received to date. [68005]</membercontribution></p>
  before do
    @contribution = mock_model(MemberContribution)

    @member = 'Mr. David Borrow'
    @member_constituency = '(South Ribble)'
    @question_no = '1.'
    @contribution_text = ': What assessment he has made of the responses to the pensions Green Paper received to date. [68005]'
    @contribution.stub!(:markers)
    @contribution.stub!(:text).and_return @contribution_text
    @contribution.stub!(:member).and_return @member
    @contribution.stub!(:member_constituency).and_return @member_constituency
    @contribution.stub!(:question_no).and_return @question_no
    @contribution.stub!(:procedural_note).and_return '<i>(seated and covered)</i>'
    @contribution.stub!(:xml_id)
    @controller.template.stub!(:contribution).and_return(@contribution)

    render 'sections/_contribution.haml'
  end

  it 'should show member contribution in p with class "member_contribution"' do
    response.should have_tag('div.member_contribution') do
      with_tag('span.question_no', @question_no)
      with_tag('cite.member', @member)
      with_tag('span.member_constituency', @member_constituency)
      with_tag('span.procedural_note', '(seated and covered):')
      with_tag('blockquote.contribution_text', @contribution_text.sub(':','').strip)
    end
  end

  it 'should show member name in cite with class "member"' do
    response.should have_tag('cite.member', @member)
  end

  it 'should show a procedural note and colon in a span with class "procedural_note"' do
    response.should have_tag('span.procedural_note', '(seated and covered):')
  end

  it 'should show member constituency name in span with class "member_constituency"' do
    response.should have_tag('span.member_constituency', @member_constituency)
  end

  it 'should show oral question number in span with class "question_no"' do
    response.should have_tag('span.question_no', @question_no)
  end

  it 'should show contribution text in blockquote with class "contribution_text"' do
    response.should have_tag('blockquote.contribution_text', @contribution_text.sub(':','').strip)
  end

end

describe '_contribution partial', 'when passed member contribution with ordered list' do

  before do
    @contribution = mock_model(MemberContribution)

    @member = 'Mr. David Borrow'
    # @member_constituency = '(South Ribble)'
    # @question_no = '1.'
    @contribution.stub!(:markers)
    @contribution.stub!(:member).and_return @member
    @contribution.stub!(:member_constituency).and_return @member_constituency
    @contribution.stub!(:question_no).and_return nil
    @contribution.stub!(:procedural_note).and_return nil
    @contribution.stub!(:xml_id)
    @controller.template.stub!(:contribution).and_return(@contribution)
  end

  it 'should add ol element with css class name "hide_numbering" if numbering is list item text' do
    @contribution_text = ": I have to notify the House, in accordance with the Royal Assent Act 1967...<ol>\n            <li>1. Companies Act 1980.</li>\n          </ol>"
    @contribution.stub!(:text).and_return @contribution_text
    render 'sections/_contribution.haml'
    response.should have_tag('ol.hide_numbering')
  end

  it 'should add ol element with no css class name if numbering is not in list item text' do
    @contribution_text = ": I have to notify the House, in accordance with the Royal Assent Act 1967...<ol>\n            <li>Companies Act 1980.</li>\n          </ol>"
    @contribution.stub!(:text).and_return @contribution_text
    render 'sections/_contribution.haml'
    response.should have_tag('ol')
  end

end

describe '_section partial', 'when passed members contribution with constituency' do

  before do
    @contribution = mock_model(MemberContribution)
    @member = 'Mr. David Borrow'
    @member_constituency = '(South Ribble)'
    @contribution_text = ': What assessment he has made of the responses to the pensions Green Paper received to date. [68005]'

    @contribution.stub!(:markers)
    @contribution.stub!(:text).and_return @contribution_text
    @contribution.stub!(:member).and_return @member
    @contribution.stub!(:member_constituency).and_return @member_constituency
    @contribution.stub!(:question_no).and_return nil
    @contribution.stub!(:procedural_note).and_return nil
    @contribution.stub!(:xml_id)
    @controller.template.stub!(:contribution).and_return(@contribution)

    render 'sections/_contribution.haml'
  end

  it 'should show member constituency name and colon in span with class "member_constituency"' do
    response.should have_tag('span.member_constituency', @member_constituency+':')
  end

end

describe '_section partial', 'when passed members contribution without constituency' do

  before do
    @contribution = mock_model(MemberContribution)
    @member = 'Mr. David Borrow'
    @member_constituency = '(South Ribble)'
    @contribution_text = ': What assessment he has made of the responses to the pensions Green Paper received to date. [68005]'

    @contribution.stub!(:markers)
    @contribution.stub!(:text).and_return @contribution_text
    @contribution.stub!(:member).and_return @member
    @contribution.stub!(:member_constituency).and_return nil
    @contribution.stub!(:question_no).and_return nil
    @contribution.stub!(:procedural_note).and_return nil
    @contribution.stub!(:xml_id)
    @controller.template.stub!(:contribution).and_return(@contribution)

    render 'sections/_contribution.haml'
  end

  it 'should show member name and colon in cite with class "member"' do
    response.should have_tag('cite.member', @member+':')
  end

  it 'should not show span with class "member_constituency"' do
    response.should_not have_tag('span.member_constituency')
  end
end
