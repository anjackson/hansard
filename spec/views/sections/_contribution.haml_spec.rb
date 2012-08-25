require File.dirname(__FILE__) + '/../../spec_helper'

describe "_contribution partial" do 
  
  before do
    assigns[:marker_options] = {}
    template.stub!(:marker_html).and_return('')
  end

  describe "in general" do

    it "should ask the contribution assigned to it for it's marker html" do
      template.stub!(:format_contribution)
      template.should_receive(:marker_html).and_return("")

      render :partial => 'sections/contribution.haml', :object => mock_model(Contribution)
    end
  end

  describe 'when passed table contribution' do

    before do
      @text = %Q[<table type="span">\n          <tr>\n            <td align="right"><i>Unsecured Loans</i></td>\n            <td></td>\n          </tr>\n        </table>]
      @table = mock_model(TableContribution, :null_object => true,
                                             :text => @text,
                                             :xml_id => "xml id",
                                             :anchor_id => 'anchor id')
      assigns[:marker_options] = {}
      render :partial => 'sections/contribution.haml', :object => @table
    end

    it 'should show table text "as is" within a div with class table and id being the xml_id of the contribution' do
      response.should have_tag('div.table[id=anchor id]') do
        with_tag('table') do
          with_tag('tr') do
            with_tag('td') do
              with_tag('span.italic', 'Unsecured Loans')
            end
          end
        end
      end
    end
  end

  describe 'when passed quote contribution' do

    before do
      @text = ': <quote>"That Sir Antony Buck and Mr. Robert Key be discharged from the Select Committee on the Armed Forces Bill and that Mr. Tony Baldry and Mr. Nicholas Soames be added to the Committee."</quote>&#x2014;<i>(Mr. Maude.]</i>'
      @quote = mock_model(QuoteContribution, :null_object => true,
                                             :text => @text,
                                             :xml_id => "xml id",
                                             :anchor_id => 'anchor id',
                                             :word_count => 0)
      render :partial => 'sections/contribution.haml', :object => @quote
    end

    it 'should show quote text in q with class quote and id being the anchor id of the contribution' do
      response.should have_tag('q[id=anchor id]', @text.sub(': ','').sub('<i>','').sub('</i>','').gsub('"','').sub('<quote>','').sub('</quote>','').squeeze(' '))
    end

    it 'should show italic text in italics' do
      response.should have_tag('span', '(Mr. Maude.]')
    end
  end

  describe 'when passed time contribution' do

    before do
      @text = '3.30 pm'

      @time = mock_model(TimeContribution, :null_object => true,
                                           :text => @text,
                                           :timestamp => Time.parse('1985-12-16T15:30:00').xmlschema)
      render :partial => 'sections/contribution.haml', :object => @time
    end

    it 'should have span with class time' do
      response.should have_tag('span.time')
    end

    it 'should have abbr with class dtstart nested in span with class time' do
      response.should have_tag('span.time abbr.dtstart')
    end

    it 'should show time text in abbr element' do
      response.should have_tag('span.time abbr.dtstart', @text)
    end

    it 'should show timestamp in in title attribute of abbr element' do
      response.should have_tag('span.time abbr[title="1985-12-16T15:30:00+00:00"]')
    end
  end

  describe 'when passed members contribution with question_no, member_suffix and procedural note' do

    before do
      @contribution = mock_model(MemberContribution, :null_object => true,
                                                     :member_name => 'Mr. David Borrow',
                                                     :text => ':test ',
                                                     :xml_id => nil,
                                                     :anchor_id => 'anchor id',
                                                     :prefix => nil,
                                                     :question_no => '1.',
                                                     :procedural_note => '<i>(seated and covered)</i>',
                                                     :member_suffix => 'South Ribble')
        
      render :partial => 'sections/contribution.haml', :object => @contribution
    end

    it 'should show member contribution in div with class "member_contribution"' do
      response.should have_tag('div.member_contribution') do
        with_tag('blockquote.contribution_text', /#{@contribution.text.sub(':','').strip}/)
        with_tag('span.question_no', @question_no)
        with_tag('cite.member', @member_name)
        with_tag('span.member_constituency', @member_suffix)
        with_tag('span.procedural_note', '(seated and covered)')
      end
    end

    it 'should show member name in cite with class "member"' do
      response.should have_tag('cite.member', @member_name)
    end

    it 'should show a procedural note in a span with class "procedural_note"' do
      response.should have_tag('span.procedural_note', '(seated and covered)')
    end

    it 'should show member constituency name in span with class "member_constituency"' do
      response.should have_tag('span.member_constituency', @constituency_name)
    end

    it 'should show oral question number in span with class "question_no"' do
      response.should have_tag('span.question_no', @question_no)
    end

    it 'should show contribution text in blockquote with class "contribution_text"' do
      response.should have_tag('blockquote.contribution_text', /#{@contribution.text.sub(':','').strip}/)
    end
  end

  describe 'when passed division placeholder' do
    before do
      @contribution = mock_model(DivisionPlaceholder, :null_object => true)
      @text = %Q|<division><table></table></division>|
      @contribution.stub!(:text?).and_return true
      @contribution.stub!(:text).and_return @text
      @contribution.stub!(:markers)
    end

    it 'should add division tables contained in text field' do
      template.should_receive(:format_contribution).with(@contribution, nil, {}).and_return @text
      render :partial => 'sections/contribution.haml', :object => @contribution
      response.should have_tag('table')
    end

  end

  describe 'when passed member contribution with ordered list' do

    before do
      @contribution = mock_model(MemberContribution, :null_object => true,
                                                     :member_name => 'Mr. David Borrow',
                                                     :member => nil,
                                                     :xml_id => nil,
                                                     :anchor_id => 'anchor id',
                                                     :prefix => nil,
                                                     :question_no => nil,
                                                     :procedural_note => nil,
                                                     :member_suffix => nil)
    end

    it 'should add ol element with css class name "hide_numbering" if numbering is list item text' do
      @contribution_text = ": I have to notify the House, in accordance with the Royal Assent Act 1967...<ol>\n            <li>1. Companies Act 1980.</li>\n          </ol>"
      @contribution.stub!(:text).and_return @contribution_text
      render :partial => 'sections/contribution.haml', :object => @contribution
      response.should have_tag('ol.hide_numbering')
    end

    it 'should add ol element with no css class name if numbering is not in list item text' do
      @contribution_text = ": I have to notify the House, in accordance with the Royal Assent Act 1967...<ol>\n            <li>Companies Act 1980.</li>\n          </ol>"
      @contribution.stub!(:text).and_return @contribution_text
      render :partial => 'sections/contribution.haml', :object => @contribution
      response.should have_tag('ol')
    end
  end

  describe 'when passed members contribution with member_suffix and no constituency' do

    before do
      @contribution = mock_model(MemberContribution, :null_object => true,
                                                     :member_suffix => 'South Ribble',
                                                     :constituency => nil,
                                                     :member_name => 'Mr. David Borrow',
                                                     :text => '',
                                                     :prefix => nil,
                                                     :xml_id => nil,
                                                     :anchor_id => 'anchor id',
                                                     :question_no => nil,
                                                     :procedural_note => nil)
      render :partial => 'sections/contribution.haml', :object => @contribution
    end

    it 'should show member constituency name in span with class "member_constituency"' do
      response.should have_tag('span.member_constituency',  @constituency_name)
    end
  end

  describe 'when passed members contribution with member_suffix and constituency' do

    before do
      @contribution = mock_model(MemberContribution, :null_object => true,
                                                     :member_suffix => 'South Ribble',
                                                     :member_name => 'Mr. David Borrow',
                                                     :constituency => mock_model(Constituency, :name => "Ribble"),
                                                     :text => '',
                                                     :prefix => nil,
                                                     :xml_id => nil,
                                                     :anchor_id => 'anchor id',
                                                     :question_no => nil,
                                                     :procedural_note => nil)
      template.stub!(:link_to_constituency).and_return("constituency link")
      render :partial => 'sections/contribution.haml', :object => @contribution
    end

    it 'should show a link to the constituency in a span with class "member_constituency"' do
 
      response.should have_tag('span.member_constituency',  "constituency link")
    end
  end

  describe 'when passed members contribution without member_suffix' do

    before do
      @member_name = 'Mr. David Borrow'
      @contribution = mock_model(MemberContribution, :null_object => true,
                                                     :text => '',
                                                     :xml_id => nil,
                                                     :anchor_id => 'anchor id',
                                                     :prefix => nil,
                                                     :question_no => nil,
                                                     :procedural_note => nil,
                                                     :member_name => @member_name,
                                                     :member_suffix => nil)
       template.stub!(:contribution).and_return(@contribution)
       render :partial => 'sections/contribution.haml', :object => @contribution
    end

    it 'should show member name in cite with class "member"' do
      response.should have_tag('cite.member', @member_name)
    end

    it 'should not show span with class "member_constituency"' do
      response.should_not have_tag('span.member_constituency')
    end
  end
  
end