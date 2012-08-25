require File.dirname(__FILE__) + '/../spec_helper'
include ApplicationHelper
include SectionsHelper

describe SectionsHelper do

  describe "when creating breadcrumb links for a section" do
    before do
      @section = mock_model(Section, :date => Date.new(1803,12,11),
                                     :sitting_uri_component => 'sitting_type',
                                     :sitting_class => Sitting)
      @section.stub!(:parent_section).and_return nil
      stub!(:url_for_date).and_return('/1803/12/11')
      stub!(:sitting_prefix).and_return("Sitting prefix")
    end

    def call_section_breadcrumbs
      capture_haml{ section_breadcrumbs(@section, "title") }
    end

    it 'should should contain a link to the url for the section\s sitting date with an anchor to the sitting type"' do
      call_section_breadcrumbs.should have_tag('a[href=/1803/12/11#sitting_type]')
    end

    it 'should should contain a link with the rel attribute "directory up"' do
      call_section_breadcrumbs.should have_tag('a[rel=directory up]')
    end

    it 'should contain a link containing the sitting prefix of the section\s sitting' do
      call_section_breadcrumbs.should have_tag('a', :text => "Sitting prefix")
    end

  end
  
  describe "when creating navigation links for a section" do
    before do
      stub!(:section_url).and_return("http://www.test.url")
      @prev = mock_model(Section, :title => "previous section title")
      @next = mock_model(Section, :title => "next section title")
      @section = mock_model(Section, :previous_linkable_section => @prev,
                                     :next_linkable_section => @next)
    end

    def call_section_nav_links
      capture_haml{ section_navigation(@section) }
    end

    it "should not be nil" do
      call_section_nav_links.should_not be_nil
    end

    it "should not have any text about the previous linkable section if there isn't one" do
      @section.stub!(:previous_linkable_section).and_return(nil)
      call_section_nav_links.should_not have_tag("span.prev-section a")
    end

    it "should not have any text about the next linkable section if there isn't one" do
      @section.stub!(:next_linkable_section).and_return(nil)
      call_section_nav_links.should_not have_tag("span.next-section a")
    end

    it "should have a link to the previous sectionin in a div with id 'previous-section' if there is one and it is linkable" do
      @section.stub!(:previous_linkable_section).and_return(mock_model(Section, :title => 'test'))
      call_section_nav_links.should have_tag('div#previous-section a')
    end


    it "should have a link to the next section in a div with id 'next-section' if there is one and it is linkable" do
      @section.stub!(:next_linkable_section).and_return(mock_model(Section, :title => 'test'))
      call_section_nav_links.should have_tag('div#next-section a')
    end
  end

  describe "when marking up mentions for a contribution" do
    before do
      @contribution = mock_model(Contribution, :null_object => true,
                                               :mentions => [],
                                               :text => 'original the act text the bill more text')
    end

    it 'should ask for the contribution\'s mentions' do
      @contribution.should_receive(:mentions).and_return([])
      markup_mentions(@contribution)
    end

    it 'should return the contribution\'s text if there are no mentions' do
      markup_mentions(@contribution).should == 'original the act text the bill more text'
    end

    it 'should return the text with act mentions replaced by links to the act page and bill mentions replaced by links to the bill page' do
      act = Act.new; act.stub!(:slug).and_return 'act-name'
      bill = Bill.new; bill.stub!(:slug).and_return 'bill-name'

      act_mention = mock_model(ActMention, :start_position => 13, :end_position => 16, :act => act)
      bill_mention = mock_model(BillMention, :start_position => 26, :end_position => 30, :bill => bill)

      @contribution.stub!(:mentions).and_return([act_mention, bill_mention])
      expected = 'original the <a href="http://test.host/acts/act-name">act</a> text the <a href="http://test.host/bills/bill-name">bill</a> more text'
      markup_mentions(@contribution).should == expected
    end

    it 'should markup the longest of a set of mentions that start at the same point' do
      act = Act.new; act.stub!(:slug).and_return 'bill-act-name'
      bill = Bill.new; bill.stub!(:slug).and_return 'bill'
      act_mention = mock_model(ActMention, :start_position => 13,
                                           :end_position => 21,
                                           :act => act)
      bill_mention = mock_model(BillMention, :start_position => 13,
                                             :end_position => 17,
                                             :bill => bill)
      @contribution.stub!(:mentions).and_return([act_mention, bill_mention])
      @contribution.stub!(:text).and_return("original the bill act text")
      expected = 'original the <a href="http://test.host/acts/bill-act-name">bill act</a> text'
      markup_mentions(@contribution).should == expected
    end

    it 'should not markup one mention within another' do
      act = Act.new; act.stub!(:slug).and_return 'bill-act-name'
      bill = Bill.new; bill.stub!(:slug).and_return 'bill'
      act_mention = mock_model(ActMention, :start_position => 13,
                                           :end_position => 21,
                                           :act => act)
      bill_mention = mock_model(BillMention, :start_position => 17,
                                              :end_position => 20,
                                              :bill => bill)
      @contribution.stub!(:mentions).and_return([act_mention, bill_mention])
      @contribution.stub!(:text).and_return("original the act bill text")
      expected = 'original the <a href="http://test.host/acts/bill-act-name">act bill</a> text'
      markup_mentions(@contribution).should == expected
    end
  end

  describe "when formatting contribution" do

    def contribution(text)
      mock_model(Contribution, :text => text,
                               :mentions => [])
    end

    def europarl_link(text)
      params = CGI.escape("site:europa.eu #{text}")
      "<cite class=\"reference\"><a href=\"http://www.google.com/search?q=#{params}\" rel=\"ref\">#{text}</a></cite>"
    end

    def expect_formatted_text(text, expected)
      format(text).should == expected
    end

    def format(text)
      format_contribution(contribution(text))
    end

    it 'should mark up mentions in the text' do
      contribution = contribution("")
      should_receive(:markup_mentions).with(contribution).and_return('')
      format_contribution(contribution)
    end

    it 'should format the contribution text for display, passing the sitting and options' do
      contribution = contribution("test")
      sitting = mock_model(Sitting)
      options = { :test => true }
      stub!(:markup_official_report_references)
      should_receive(:format_display_text).with("test", sitting, options)
      format_contribution(contribution, sitting, options)
    end

    it 'should markup URL references' do
      contribution = contribution("text")
      resolver = mock_model(UrlResolver, :null_object => true)
      UrlResolver.should_receive(:new).and_return(resolver)
      resolver.should_receive(:markup_references).and_return('marked up')
      format_contribution(contribution).should == 'marked up'
    end

    it 'should markup official report references' do
      contribution = contribution("text")
      resolver = mock_model(ReportReferenceResolver, :null_object => true)
      ReportReferenceResolver.should_receive(:new).and_return(resolver)
      resolver.should_receive(:markup_references).and_return('marked up')
      format_contribution(contribution).should == 'marked up'
    end

    it 'should leave plain text unchanged' do
      expect_formatted_text('text', 'text')
    end

    it 'should make an EC directive reference of "80/778/EC" link to Google search "site:europa.eu 80/778/EC" with a "rel" attribute of "ref", wrapped in a "cite" tag with a class of "reference"' do
      format('EC drinking water directive 80/778/EC').should == "EC drinking water directive #{europarl_link('80/778/EC')}"
    end

    it 'should make multiple EC directive references with the format "80/778/EC" each link to Google search starting "site:europa.eu" and ending with the appropriate reference with a "rel" attribute of "ref", wrapped in a "cite" tag with a class of "reference"' do
      text = 'Five EU directives have been implemented by DTI so far in 2002: Directives 97/64/EC, 98/44/EC, 1999/42/EC, 1999/93/EC, and 2001/77/EC.'
      expected = 'Five EU directives have been implemented by DTI so far in 2002: Directives ' +
          europarl_link('97/64/EC')   + ', ' +
          europarl_link('98/44/EC')   + ', ' +
          europarl_link('1999/42/EC') + ', ' +
          europarl_link('1999/93/EC') + ', and ' +
          europarl_link('2001/77/EC') + '.'
      format(text).should == expected
    end

    it 'should replace quote element with q tag with class "quote"' do
      format('a <quote>quote</quote> from').should == 'a <q>quote</q> from'
    end

    it 'should replace b element with span tag with class "bold"' do
      format('a <b>bolded</b> word').should == 'a <span class="bold">bolded</span> word'
    end

    it 'should replace an <ob> tag with a span tag with class "obscured" and text "[...]"' do 
      format('an <ob></ob>obscured word').should == 'an <span class="obscured">[...]</span>obscured word'
    end
    
    it 'should replace u element with span tag with class "underline"' do
      format('an <u>underlined</u> word').should == 'an <span class="underline">underlined</span> word'
    end

    it 'should replace i element with span tag with class "italic"' do
      format('a <i>italicized</i> word').should == 'a <span class="italic">italicized</span> word'
    end

    it 'should replace col element with a column marker' do
      should_receive(:column_marker).with('123', nil).and_return("123_marker")
      format('a <col>123</col> text').should == "a 123_marker text"
    end

    it 'should remove a col element if asked to hide markers ' do
      stub!(:column_marker).with('123', nil).and_return("123_marker")
      text = 'a <col>123</col> text'
      format_contribution(contribution(text), nil, :hide_markers => true).should == "a text"
    end

    it 'should replace lb element with close and open paragraph' do
      format('a <lb></lb> break').should == 'a </p><p> break'
    end

    it 'should not change "sub" tags' do
      format('a <sub>real</sub> change').should == 'a <sub>real</sub> change'
    end

    it 'should not change "sup" tags' do
      format('a <sup>real</sup> change').should == 'a <sup>real</sup> change'
    end

    it 'should not change "a" tags' do
      format('a <a href="http://test.host">link</a> change').should == 'a <a href="http://test.host">link</a> change'
    end

    it ' should return quotes in a q tag' do
      format('test quote :<quote>"quoted text goes here"</quote>').should == 'test quote <q>quoted text goes here</q>'
    end

    it 'should strip a leading colon' do
      format(': The honourable member').should == 'The honourable member'
    end

    it 'should strip a leading colon preceded by a tag' do
      format('<p>: The honourable member</p>').should == "<p>The honourable member</p>"
    end

    it "should convert a member element in to a span element with class 'member'" do
      text = "1. <member>Mr. Michael Latham</member> asked the Secretary of State for Northern Ireland whether he will make a further statement on the security situation."
      expected = '1. <span class="member">Mr. Michael Latham</span> asked the Secretary of State for Northern Ireland whether he will make a further statement on the security situation.'

      format(text).should == expected
    end

    it 'should convert a memberconstituency element into a span element with class "memberconstituency"' do
      text = '<member>Mr. Ted Leadbitter</member> <memberconstituency>(The Hartlepools)</memberconstituency>'
      expected = '<span class="member">Mr. Ted Leadbitter</span> <span class="memberconstituency">(The Hartlepools)</span>'
      format(text).should == expected
    end

    it 'should format a division, by returning the table elements contained in the division' do
      tables = '<table><tr><td>Heath, David</td></tr></table><table><tr><td>Sanders, Adrian</td></tr></table>'
      text = %Q|<division>#{tables}</division>|
      format(text).should == %Q|#{tables}|
    end

    it 'should format a col in between division tables correctly' do
      table = '<table></table>'
      stub!(:column_marker).with('123', nil).and_return("123_marker")
      text = %Q|<division>#{table}<col>123</col>#{table}</division>|
      format(text).should == %Q|#{table}123_marker#{table}|
    end

    it 'should format an image in between division tables by closing the table, adding it and opening a new table' do
      stub!(:image_marker).and_return('123_marker')
      text = %Q|<division><table></table><image src="S6CV0420P1I0075"/><table></table></division>|
      format(text).should == %Q|<table></table>123_marker<table></table>|
    end
    
    it 'should remove an image when asked to hide markers' do
      stub!(:image_marker).and_return('123_marker')
      text = %Q|<division><table></table><image src="S6CV0420P1I0075"/><table></table></division>|
      format_contribution(contribution(text), nil, :hide_markers => true).should == %Q|<table></table><table></table>|
    end

    it 'should format a col in between rows in a division table by closing table and adding permalink' do
      table_start = '<table><tr><td>Heath, David</td></tr>'
      table_end = '<tr><td>Sanders, Adrian</td></tr></table>'
      stub!(:column_marker).with('124', nil).and_return("124_marker")
      text = %Q|<division>#{table_start}<col>124</col>#{table_end}</division>|
      format(text).should == %Q|#{table_start}</table>124_marker<table>#{table_end}|
    end

    it 'should format a ordered list correctly' do
      text = "In the application of this Act: \n<ol>\n<li>(<i>a</i>) Section nine shall have effect as ... and</li>\n<li>(<i>b</i>) Section eleven shall have effect as ...</li></ol>"
      format(text).should == text
    end

    it 'should format several paragraphs of member written contribution correctly' do
      first_paragraph_text = 'A note setting out the volume of United Kingdom and Community'
      text = %Q[<p id="S6CV0089P0-04897">: #{first_paragraph_text}</p>] +
          %Q[<p id="S6CV0089P0-04898">The storage, handling and related costs of United Kingdom intervention </p>]
      expected = %Q[<p id="S6CV0089P0-04897">#{first_paragraph_text}</p>] +
          %Q[<p id="S6CV0089P0-04898">The storage, handling and related costs of United Kingdom intervention </p>]
      format(text).should == expected
    end
  end


  describe "when returning marker html for a model" do
 
    before do
      Sitting.stub!(:normalized_column).and_return("24B")
      @sitting = mock_model(Sitting, :null_object => true)
      @section = mock_model(Section, :markers => nil)
    end

    it "should ask the model for it's markers" do
      @section.should_receive(:markers)
      marker_html(@section, nil, {})
    end

    it 'should return an empty string if passed an option to hide markers' do 
      @section.stub!(:markers).and_yield("column", "column number")
      stub!(:column_marker).with("column number", nil).and_return("marker")
      marker_html(@section, nil, {:hide_markers => true}).should == ''
    end
    
    it "should return a column marker tag if the model yields a column" do
      @section.stub!(:markers).and_yield("column", "column number")
      should_receive(:column_marker).with("column number", nil).and_return("")
      marker_html(@section, nil, {})
    end

  end
  
end
