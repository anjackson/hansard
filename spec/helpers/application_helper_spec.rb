require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper, " when formatting member contribution" do

  it 'should leave plain text unchanged' do
    format_member_contribution('text').should == '<p>text</p>'
  end

  it 'should replace quote element with span with class' do
    format_member_contribution('a <quote>quote</quote> from').should ==
        '<p>a <span class="quote">quote</span> from</p>'
  end

  it 'should replace col element with h4' do
    format_member_contribution('a <col>123</col> text','zzz').should ==
        '<p>a </p></zzz><h4>Column 123</h4><zzz><p> text</p>'
  end

  it 'should replace image element with h4' do
    format_member_contribution('a <image src="S6CV0089P0I0021"/> text','zzz').should ==
        '<p>a </p></zzz><h4>Image S6CV0089P0I0021</h4><zzz><p> text</p>'
  end

  it 'should replace lb element with close and open paragraph' do
    format_member_contribution('a <lb></lb> break').should ==
        '<p>a </p><p> break</p>'
  end

  it 'should leave italics element unchanged' do
    format_member_contribution('a <i>real</i> change').should ==
        '<p>a <i>real</i> change</p>'
  end

  it 'should leave italics element unchanged' do
    format_member_contribution('a <sub>real</sub> change').should ==
        '<p>a <sub>real</sub> change</p>'
  end
end
