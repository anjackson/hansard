require File.dirname(__FILE__) + '/../spec_helper'

describe Monarch, " in general" do 
  
  it 'should be able to list monarchs' do 
    Monarch.respond_to?(:list).should be_true
  end
  
  it 'should return a hash with value false for monarchs that don\'t have sessions and true for those that do' do
    Volume.stub!(:find_by_monarch).and_return(nil)
    Volume.stub!(:find_by_monarch).with('VICTORIA').and_return("volume")
    by_monarch = Monarch.volumes_by_monarch
    by_monarch.should == { "GEORGE V"     => false,
                           "GEORGE IV"    => false,
                           "ELIZABETH II" => false,
                           "EDWARD VIII"  => false,
                           "GEORGE III"   => false,
                           "GEORGE VI"    => false,
                           "VICTORIA"     => true,
                           "EDWARD VII"   => false,
                           "WILLIAM IV"   => false }
  end
  
  it 'should be able to convert the slug "elizabeth-ii" to the canonical name "ELIZABETH II"' do
    Monarch.slug_to_name('elizabeth ii').should == 'ELIZABETH II'
  end
  
  it 'should be able to convert the canonical name "ELIZABETH II" to the readable name "Elizabeth II"' do 
    Monarch.monarch_name('ELIZABETH II').should == 'Elizabeth II'
  end
  
end
