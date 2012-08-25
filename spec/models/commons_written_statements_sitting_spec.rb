require File.dirname(__FILE__) + '/../spec_helper'

describe CommonsWrittenStatementsSitting do

  it 'should have "Commons" as house' do
    CommonsWrittenStatementsSitting.house.should == 'Commons'
  end

  it 'should have "HC" as prefix to a reference' do
    CommonsWrittenStatementsSitting.hansard_reference_prefix.should == 'HC'
  end

end
