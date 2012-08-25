require File.dirname(__FILE__) + '/../spec_helper'

describe LordsWrittenStatementsSitting, 'the class' do

  it 'should have "Lords" as house' do
    LordsWrittenStatementsSitting.house.should == 'Lords'
  end

  it 'should have "HL" as Hansard reference prefix' do
    LordsWrittenStatementsSitting.hansard_reference_prefix.should == 'HL'
  end
  
end
