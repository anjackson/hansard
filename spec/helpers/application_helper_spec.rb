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

  it 'should replace image element with h4' do
    format_contribution('a <image src="S6CV0089P0I0021"/> text',['zzz']).should ==
        "<p>a </p></zzz><h4 class='sidenote'>Image S6CV0089P0I0021</h4><zzz><p> text</p>"
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

describe ApplicationHelper, " when returning the url for a sitting" do
  
  it "should return the url for the sitting" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 6))
    sitting_date_url(sitting).should == '/commons/1985/dec/06'
  end

end

describe ApplicationHelper, " when returning a link for a sitting" do
  
  it "should return a link whose text is of the form 'House of Commons &ndash; Monday, December 16, 1985'" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16), :title => "House of Commons")
    sitting_link(sitting).should == "<a href=\"/commons/1985/dec/16\">House of Commons &ndash; Monday, December 16, 1985</a>"
  end

end

describe ApplicationHelper, " when returning a display date for a sitting" do

  it "should return a date in the format 'Monday, December 16, 1985'" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16))
    sitting_display_date(sitting).should == 'Monday, December 16, 1985'
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

