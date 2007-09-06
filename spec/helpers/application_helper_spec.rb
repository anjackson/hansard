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

  it 'should replace quote element with span with class' do
    format_contribution('a <quote>quote</quote> from').should ==
        '<p>a <span class="quote">quote</span> from</p>'
  end

  it 'should replace col element with h4 and anchor' do
    format_contribution('a <col>123</col> text',['zzz']).should ==
        "<p>a </p></zzz><h4 class='sidenote'>Col. 123</h4><a name='column_123'><zzz><p> text</p>"
  end

  it 'should replace image element with an image with appropriate markup' do
    format_contribution('a <image src="S6CV0089P0I0021"/> text',['zzz']).should ==
        "<p>a </p></zzz><h4 class='sidenote'><img src='/images/dummypage.jpg' alt='Image: S6CV0089P0I0021' title='Image: S6CV0089P0I0021'/></h4><zzz><p> text</p>"
  end

  it 'should replace lb element with close and open paragraph' do
    format_contribution('a <lb></lb> break').should ==
        '<p>a </p><p> break</p>'
  end

  it 'should leave italics element unchanged' do
    format_contribution('a <i>real</i> change').should ==
        '<p>a <i>real</i> change</p>'
  end

  it 'should leave subscript element unchanged' do
    format_contribution('a <sub>real</sub> change').should ==
        '<p>a <sub>real</sub> change</p>'
  end

  it 'should correctly handle image element in italics element' do
    format_contribution('a <i>really <image src="S6CV0089P0I0021"/> powerful</i> change',['zzz']).should ==
        "<p>a <i>really </i></p></zzz><h4 class='sidenote'>Image S6CV0089P0I0021</h4><zzz><p><i> powerful</i> change</p>"
  end

  it 'should correctly handle column element in subscript element' do
    format_contribution('a <sub>really <col>123</col> powerful</sub> change',['zzz']).should ==
        "<p>a <sub>really </sub></p></zzz><h4 class='sidenote'>Col. 123</h4><a name='column_123'><zzz><p><sub> powerful</sub> change</p>"
  end
end

describe ApplicationHelper, " when returning the date-based urls" do
  
  it "should return a url in the format /commons/1985/dec/06 for a sitting" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_url(sitting).should == '/commons/1985/dec/06'
  end
  
  it "should return a url in the format /commons/source/1985/dec/06.xml for a sitting source" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_source_url(sitting).should == '/commons/source/1985/dec/06.xml'
  end

  it "should return a url in the format /commons/1985/dec/06.xml for a sitting in xml" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_xml_url(sitting).should == '/commons/1985/dec/06.xml'
  end
  
  it "should return a url in the format /indices/1985/dec/06/1986/jan/07 for an index" do
    index = Index.new(:start_date => Date.new(1985, 12, 6), 
                      :end_date => Date.new(1986, 1, 7))
    index_date_span_url(index).should == '/indices/1985/dec/06/1986/jan/07'
  end
    
end

describe ApplicationHelper, " when returning links" do
  
  it "should return a link for a sitting whose text is of the form 'House of Commons &ndash; Monday, December 16, 1985'" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16), :title => "House of Commons")
    sitting_link(sitting).should have_tag("a", :text => "House of Commons &ndash; Monday, December 16, 1985")
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
  end
  
  it "should yield in the context of a link to the sitting if a sitting can be found" do
    sitting = mock_model(Sitting)
    stub!(:sitting_date_url).and_return("http://test.url")
    HouseOfCommonsSitting.stub!(:find).and_return(sitting)
    capture_haml{
      commons_day_link(@day, ">"){ puts "moo" }
    }.should have_tag("a[href=http://test.url]", :text => "moo")
  end
  
  it "should yield in without a link if no sitting can be found" do
    HouseOfCommonsSitting.stub!(:find).and_return(nil)
    capture_haml{
      commons_day_link(@day, ">"){ puts "moo" }
    }.should == "moo\n"
  end

  it "should look for the first sitting with a date larger than the sitting date passed for direction '>'" do
    HouseOfCommonsSitting.should_receive(:find).with(:first,
                                       :conditions => ["date > ?", @day.to_date],
                                       :order => "date asc")
    commons_day_link(@day, ">"){}
  end

  it "should look for the first sitting with a date smaller than the sitting date passed for direction '<'" do
    HouseOfCommonsSitting.should_receive(:find).with(:first,
                                       :conditions => ["date < ?", @day.to_date],
                                       :order => "date desc")
    commons_day_link(@day, "<"){}
  end
  
end

describe ApplicationHelper, " when creating navigation links" do

  before do 
    @sitting = mock_model(Sitting)
    @sitting.stub!(:date).and_return(Date.new(2006,3,3))
    stub!(:sitting_date_source_url)
    stub!(:sitting_date_xml_url)
    stub!(:commons_day_link).and_yield
  end
  
  it "should write 'Historic Hansard' to the page if @day is not true" do
    capture_haml{
      day_nav_links
    }.should == "Historic Hansard\n"
  end
  
  it "should write content to the page if @day is true" do
    @day = true
    capture_haml{
      day_nav_links
    }.should_not == ''
  end
  
  it "should include an 'ol' tag containing an 'li' tag containing a link to the source xml with the text 'XML source'" do
    @day = true
    should_receive(:sitting_date_source_url).and_return("http://test.url")
    capture_haml{
      day_nav_links
    }.should have_tag("ol li a[href=http://test.url]", :text => "XML source")
  end
  
  it "should include an 'ol' tag containing an 'li' tag containing a link to the generated xml with the text 'Generated XML'" do 
    @day = true
    should_receive(:sitting_date_xml_url).and_return("http://test.url")
    capture_haml{
      day_nav_links
    }.should have_tag("ol li a[href=http://test.url]", :text => "Generated XML")
  end
  
  it "should include an 'ol' tag containing an 'li' tag containing the text 'Previous day'" do 
    @day = true
    should_receive(:commons_day_link).any_number_of_times.and_yield
    capture_haml{
      day_nav_links
    }.should have_tag("ol li", :text => "Previous day")
  end
  
  it "should include an 'ol' tag containing an 'li' tag containing the text 'Next day'" do
    @day = true
    should_receive(:commons_day_link).any_number_of_times.and_yield
    capture_haml{
      day_nav_links
    }.should have_tag("ol li", :text => "Next day") 
  end
    
end

describe ApplicationHelper, " when creating links in index entries" do

  before do 
    @index = Index.new(:start_date => Date.new(2006, 5, 4), 
                      :end_date => Date.new(2006, 6, 6))
    @index_entry = IndexEntry.new(:index => @index)
    HouseOfCommonsSitting.stub!(:find_by_column_and_date_range).and_return(Sitting.new(:date => Date.new(2006,5,5)))
  end
  
  it "should replace index entries with links appropriately for the text 'Channel tunnel 758'" do
    @index_entry.text = "Channel tunnel 758"
    expected = "Channel tunnel <a href=\"/commons/2006/may/05#column_758\">758</a>"
    index_entry_links(@index_entry).should == expected
  end

  it "should replace index entries with links appropriately for the text 'Scotland 16&#x2013;7, 18, 59&#x2013;60w'" do
    @index_entry.text = "Scotland 16&#x2013;7, 18, 59&#x2013;60w"
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
    should_receive(:column_marker).with("column number", " second-sidenote").and_return("")
    marker_html(@mock_sitting, {})
  end
  
  it "should return an 'h4' tag with class 'sidenote' containing the text 'Image' and the image source for an image marker" do
    image_marker("image source").should have_tag("h4.sidenote", :text => "Image image source", :count => 1)
  end

  it "should return an 'h4' tag with class 'sidenote' containing the text 'Col' and the column number for a column marker" do
    column_marker("5").should have_tag("h4.sidenote", :text => "Col. 5", :count => 1)
  end
  
  it "should return an anchor for the column_number for a column marker" do
    column_marker("5").should have_tag("a[name=column_5]", :count => 1)
  end
  
end

