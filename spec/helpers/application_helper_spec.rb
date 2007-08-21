require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper, " when formatting member contribution" do

  it "should leave plain text unchanged" do
    format_member_contribution('text').should == 'text'
  end

end
