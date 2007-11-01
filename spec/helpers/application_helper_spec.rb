require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper, " when formatting section title" do
  it 'should remove line break elements' do
    format_section_title('ENVIRONMENT, TRANSPORT AND THE<lb></lb>REGIONS').should ==
        'ENVIRONMENT, TRANSPORT AND THE REGIONS'
  end
end

describe ApplicationHelper, " when formatting contribution" do

  it 'should leave plain text unchanged' do
    format_contribution('text').should == '<p>text</p>'
  end

  it 'should replace quote element with q tag with class "quote"' do
    format_contribution('a <quote>quote</quote> from').should ==
        '<p>a <q class="quote">quote</q> from</p>'
  end

  it 'should replace col element with span with class "sidenote" and anchor' do
    format_contribution('a <col>123</col> text').should ==
        "<p>a <span class='sidenote'><a name='column_123' href='#column_123'>Col 123</a></span> text</p>"
  end

  it 'should replace image element with an image wrapped in a span with class "sidenote"' do

    format_contribution('a <image src="S6CV0089P0I0021"/> text').should ==
        "<p>a <span class='sidenote'>Img S6CV0089P0I0021</span> text</p>"
  end

  it 'should replace lb element with close and open paragraph' do
    format_contribution('a <lb></lb> break').should ==
        '<p>a </p><p> break</p>'
  end

  it 'should leave italics element unchanged' do
    format_contribution('a <i>real</i> change').should ==
        '<p>a <i>real</i> change</p>'
  end

  it 'should leave bold element unchanged' do
    format_contribution('a <b>real</b> change').should ==
        '<p>a <b>real</b> change</p>'
  end

  it 'should leave subscript element unchanged' do
    format_contribution('a <sub>real</sub> change').should ==
        '<p>a <sub>real</sub> change</p>'
  end

  it 'should leave superscript element unchanged' do
    format_contribution('a <sup>real</sup> change').should ==
        '<p>a <sup>real</sup> change</p>'
  end

  it ' should return quotes in a q tag with no extraneous quotemarks' do
    format_contribution('test quote :<quote>"quoted text goes here"</quote>').should == '<p>test quote <q class="quote">quoted text goes here</q></p>'
  end

  it 'should return the image name linked to the source wrapped with a span with class "sidenote"' do
    format_contribution('a <i>really <image src="S6CV0089P0I0021"/> powerful</i> change').should ==
        "<p>a <i>really <span class='sidenote'>Img S6CV0089P0I0021</span> powerful</i> change</p>"
  end

  it 'should return the column number with an anchor wrapped with a span with class "sidenote"' do
    format_contribution('a <sub>really <col>123</col> powerful</sub> change').should ==
        "<p>a <sub>really <span class='sidenote'><a name='column_123' href='#column_123'>Col 123</a></span> powerful</sub> change</p>"
  end
  
  it "should convert a member element in to a span element with class 'member'" do
    text = "1. <member>Mr. Michael Latham</member> asked the Secretary of State for Northern Ireland whether he will make a further statement on the security situation."
    expected = '<p>1. <span class="member">Mr. Michael Latham</span> asked the Secretary of State for Northern Ireland whether he will make a further statement on the security situation.</p>'

    format_contribution(text).should == expected
  end

end

describe ApplicationHelper, " when returning the date-based urls" do

  it "should return a url in the format /commons/1985/dec/06 for a house of commons sitting" do
    sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_url(sitting).should == '/commons/1985/dec/06'
  end

  it "should return a url in the format /commons/source/1985/dec/06.xml for a house of commons sitting source" do
    sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_source_url(sitting).should == '/commons/source/1985/dec/06.xml'
  end

  it "should return a url in the format /commons/1985/dec/06.xml for a sitting in xml" do
    sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_xml_url(sitting).should == '/commons/1985/dec/06.xml'
  end

  it "should return a url in the format /indices/1985/dec/06/1986/jan/07 for an index" do
    index = Index.new(:start_date => Date.new(1985, 12, 6),
                      :end_date => Date.new(1986, 1, 7))
    index_date_span_url(index).should == '/indices/1985/dec/06/1986/jan/07'
  end

end

describe ApplicationHelper, " when returning links" do

  it "should return a link for a House of Commons sitting whose text is of the form 'Monday, December 16, 1985'" do
    sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 16))
    sitting_link(sitting).should have_tag("a", :text => "Monday, December 16, 1985")
  end

  it "should return a link for an index whose text is of the form '16th December 1985 &ndash; 17th January 1986'" do
    index = Index.new(:start_date_text => "16th December 1985",
                      :end_date_text => "17th January 1986",
                      :start_date => Date.new(1985, 12, 16),
                      :end_date  => Date.new(1986, 1, 17),
                      :title => "INDEX TO THE PARLIAMENTARY DEBATES")
    index_link(index).should have_tag("a", :text => "16th December 1985 &ndash; 17th January 1986")
  end

end

describe ApplicationHelper, " when returning a display date for a sitting" do

  it "should return a date in the format 'Monday, December 16, 1985'" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16))
    sitting_display_date(sitting).should == 'Monday, December 16, 1985'
  end

end

describe ApplicationHelper, " when creating a link for a sitting's next or previous day" do

  before do
    @day = Date.new(1985, 12, 16)
    @sitting = mock_model(HouseOfCommonsSitting)
    @sitting.stub!(:date).and_return(@day)
  end

  it "should yield in the context of a link to the sitting if a sitting can be found" do
    stub!(:sitting_date_url).and_return("http://test.url")
    HouseOfCommonsSitting.stub!(:find).and_return(@sitting)
    result = capture_haml{ day_link(@sitting, ">"){ puts "moo" } }
    result.should have_tag("a[href=http://test.url]", :text => "moo")
  end

  it "should yield in without a link if no sitting can be found" do
    HouseOfCommonsSitting.stub!(:find).and_return(nil)
    result = capture_haml{ day_link(@sitting, ">"){ puts "moo" } }
    result.should == "moo\n"
  end

  it "should look for the first sitting with a date larger than the sitting date passed for direction '>'" do
    HouseOfCommonsSitting.should_receive(:find).with(:first,
                                       :conditions => ["date > ?", @day.to_date],
                                       :order => "date asc")
    day_link(@sitting, ">"){}
  end

  it "should look for the first sitting with a date smaller than the sitting date passed for direction '<'" do
    HouseOfCommonsSitting.should_receive(:find).with(:first,
                                       :conditions => ["date < ?", @day.to_date],
                                       :order => "date desc")
    day_link(@sitting, "<"){}
  end

end

describe ApplicationHelper, " when creating navigation links" do

  before do
    @sitting = mock_model(Sitting)
    @sitting.stub!(:date).and_return(Date.new(2006,3,3))
    url_helper_methods = [:sitting_date_source_url,
        :sitting_date_xml_url,
        :home_url,
        :sittings_url,
        :commons_url,
        :lords_url,
        :parliament_sessions_url,
        :lords_reports_url,
        :written_answers_url,
        :indices_url,
        :members_url,
        :search_url,
        :parliament_sessions_url]

    url_helper_methods.each do |url_helper_method|
      stub!(url_helper_method)
    end
    stub!(:commons_day_link).and_yield
  end

  it "should include an 'ul' tag containing an 'li' tag containing a link to the root if @day is not true" do
    @day = false
    should_receive(:home_url).and_return("http://test.url")
    result = capture_haml{ day_nav_links }
    result.should have_tag("ul li a[href=http://test.url]")
  end
  
  it "should include an 'ul' tag containing an 'li' tag containing a link to the sittings url if @day is not true" do
    should_receive(:sittings_url).and_return("http://test.url")
    result = capture_haml{ day_nav_links }
    result.should have_tag("ul li a[href=http://test.url]")
  end


  it "should include an 'ul' tag containing an 'li' tag containing a link to the writtenanswers url if @day is not true" do
    should_receive(:written_answers_url).and_return("http://test.url")
    result = capture_haml{ day_nav_links }
    result.should have_tag("ul li a[href=http://test.url]")
  end

  it "should write content to the page if @day is true" do
    @day = true
    result = capture_haml{ day_nav_links }
    result.should_not == ''
  end

  it "should include an 'ul' tag containing an 'li' tag containing the text 'Previous sitting day'" do
    @day = true
    should_receive(:commons_day_link).any_number_of_times.and_yield
    result = capture_haml{ day_nav_links }
    result.should have_tag("ul li", :text => "Previous sitting day")
  end

  it "should include an 'ul' tag containing an 'li' tag containing the text 'Next sitting day'" do
    @day = true
    should_receive(:commons_day_link).any_number_of_times.and_yield
    result = capture_haml{ day_nav_links }
    result.should have_tag("ul li", :text => "Next sitting day")
  end

end

describe ApplicationHelper, " when creating links in index entries" do

  before do
    @index = Index.new(:start_date => Date.new(2006, 5, 4),
                      :end_date => Date.new(2006, 6, 6))
    @index_entry = IndexEntry.new(:index => @index)

  end

  it "should replace index entries with links appropriately for the text 'Channel tunnel 758'" do
    @index_entry.text = "Channel tunnel 758"
    sitting = HouseOfCommonsSitting.new(:date => Date.new(2006, 5, 5))
    HouseOfCommonsSitting.stub!(:find_section_by_column_and_date_range).and_return(Section.new(:sitting => sitting))
    expected = "Channel tunnel <a href=\"/commons/2006/may/05#column_758\">758</a>"
    index_entry_links(@index_entry).should == expected
  end

  it "should replace index entries with links appropriately for the text 'Scotland 16&#x2013;7, 18, 59&#x2013;60w'" do
    @index_entry.text = "Scotland 16&#x2013;7, 18, 59&#x2013;60w"
    sitting = HouseOfCommonsSitting.new(:date => Date.new(2006, 5, 5))
    HouseOfCommonsSitting.stub!(:find_section_by_column_and_date_range).and_return(Section.new(:sitting => sitting))
    expected = "Scotland <a href=\"/commons/2006/may/05#column_16\">16</a>&#x2013;7, <a href=\"/commons/2006/may/05#column_18\">18</a>, 59&#x2013;60w"
    index_entry_links(@index_entry).should == expected
  end

end

describe ApplicationHelper, " when returning marker html for a model" do

  before do
    @mock_sitting = mock_model(Sitting)
  end

  it "should ask the model for it's markers" do
    @mock_sitting.should_receive(:markers)
    marker_html(@mock_sitting, {})
  end

  it "should return an image marker tag if the model yields an image marker" do
    @mock_sitting.stub!(:markers).and_yield("image", "image source")
    should_receive(:image_marker).with("image source").and_return("")
    marker_html(@mock_sitting, {})
  end

  it "should return a column marker tag if the model yields a column" do
    @mock_sitting.stub!(:markers).and_yield("column", "column number")
    should_receive(:column_marker).with("column number").and_return("")
    marker_html(@mock_sitting, {})
  end

  it "should return a 'span' tag with class 'sidenote' with the text 'Img ' and the name of the image" do
    expected_tag_selector = "span.sidenote"
    image_marker("S5CV0750P0I0497").should have_tag(expected_tag_selector, :count => 1, :text => "Img S5CV0750P0I0497")
  end

  it "should return a 'span' tag with class 'sidenote' containing the text 'Col ' and the column number for a column marker" do
    column_marker("5").should have_tag("span.sidenote", :text => "Col 5", :count => 1)
  end

  it "should return an anchor for the column_number for a column marker" do
    column_marker("5").should have_tag("a[name=column_5]", :count => 1)
  end

end

describe ApplicationHelper, " when formatting plain text as an html list" do

  it "should replace a newline-delimited piece of text with an html unordered list" do
    html_list("line\nother line").should == "<ul><li>line</li><li>other line</li></ul>"
  end

end

describe ApplicationHelper, " when creating a section url" do

  def create_section sitting_model
    section = mock_model(Section)
    section.stub!(:sitting).and_return(sitting_model.new(:date => Date.new(1957, 6, 25)))
    section.stub!(:id_hash).and_return({
      :id    => "exports-to-israel",
      :year  => '1957',
      :month => 'jun',
      :day   => '25',
      :type  => sitting_model.uri_component})
    section
  end

  it "should create a url like /commons/1957/jun/25/exports-to-israel for a section from the commons on the day shown with the slug shown" do
    section = create_section HouseOfCommonsSitting
    section_url(section).should == "/commons/1957/jun/25/exports-to-israel"
  end

  it "should create a url like /lords/1957/jun/25/exports-to-israel for a section from the lords on the day shown with the slug shown" do
    section = create_section HouseOfLordsSitting
    section_url(section).should == "/lords/1957/jun/25/exports-to-israel"
  end

  it "should create a url like /written_answers/1957/jun/25/exports-to-israel for a section from a written answer on the day shown with the slug shown" do
    section = create_section WrittenAnswersSitting
    section_url(section).should == "/written_answers/1957/jun/25/exports-to-israel"
  end
end


describe ApplicationHelper, " when using sitting_nav_links to create links for a sitting" do

  before do
    @sitting = mock_model(Sitting)
    @sitting.stub!(:title).and_return("sitting title")  
    @sitting.stub!(:year).and_return(1928)
    @sitting.stub!(:month).and_return(2)
    @sitting.stub!(:day).and_return(11)
    stub!(:on_date_url).and_return("http://www.test-date.url")
    assigns[:sitting] = @sitting
  end

  def call_sitting_nav_links
    capture_haml{ sitting_nav_links(@sitting) }
  end
  
  it 'should return a table with id "navigation-by-sittings"' do
    call_sitting_nav_links.should have_tag("table#navigation-by-sittings")
  end
  
  it 'should have a table header "Hansard"' do
    call_sitting_nav_links.should have_tag("th", :text => 'Hansard')
  end
  
  it 'should have a link to the sitting\'s year' do 
    call_sitting_nav_links.should have_tag("a.sitting-year[href=http://www.test-date.url]", :text => '1928')
  end

  it 'should have a link to the sitting\'s month' do 
    call_sitting_nav_links.should have_tag("a.sitting-month[href=http://www.test-date.url]", :text => 'Feb 1928')
  end

  it 'should have a link to the sitting\'s day' do 
    call_sitting_nav_links.should have_tag("a.sitting-day[href=http://www.test-date.url]", :text => '11 Feb 1928')
  end
end


describe ApplicationHelper, " when using giving the title for a date at a resolution" do

  it 'should return "Sittings in 1928" given the date June 1 1928 and the resolution :year' do
    resolution_title(Date.new(1928, 6, 1), :year).should == "Sittings in 1928"
  end
  
  it 'should return "Sittings in June 1928" given the date June 1 1928 and the resolution :month' do
    resolution_title(Date.new(1928, 6, 1), :month).should == "Sittings in June 1928"
  end
  
  it 'should return "Sitting of 1 June 1928" given the date June 1 1928 and the resolution :day' do
    resolution_title(Date.new(1928, 6, 1), :day).should == "Sitting of 1 June 1928"
  end

end