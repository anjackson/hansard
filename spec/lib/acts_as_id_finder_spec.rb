require File.dirname(__FILE__) + '/../spec_helper'

describe Acts::IdFinder, "an id_finder class when getting id attributes" do 
  
  before do
    self.class.send(:include, Acts::IdFinder)
    self.class.acts_as_id_finder
  end
  
  it 'should return column names ending with "_id"' do 
    self.class.stub!(:column_names).and_return(['attribute_one', 'attribute_id', 'id', 'mooid'])
    self.class.id_attributes.should == ['attribute_id', 'id']
  end
  
end