require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper, " when formatting member contribution" do

  it 'should leave plain text unchanged' do
    format_member_contribution('text').should == 'text'
  end

  it 'should replace quote element with span with class' do
    format_member_contribution('a <quote>quote</quote> from').should ==
        'a <span class="quote">quote</span> from'
  end

end
