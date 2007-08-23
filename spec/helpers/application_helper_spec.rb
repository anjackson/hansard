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

  it 'should replace col element with h4' do
    format_contribution('a <col>123</col> text',['zzz']).should ==
        "<p>a </p></zzz><h4 class='sidenote'>Col. 123</h4><zzz><p> text</p>"
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
        "<p>a <sub>really </sub></p></zzz><h4 class='sidenote'>Col. 123</h4><zzz><p><sub> powerful</sub> change</p>"
  end
end

describe ApplicationHelper, ".sitting_date_url" do
  
  it "should return the url for the sitting" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16))
    sitting_date_url(sitting).should == '/commons/1985/dec/16'
  end

end

describe ApplicationHelper, ".display_date" do

  it "should return a date in the format" do
    sitting = Sitting.new(:date => Date.new(1985, 12, 16))
    sitting_display_date(sitting).should == 'Monday, December 16, 1985'
  end
  
end

