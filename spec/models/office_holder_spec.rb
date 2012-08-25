require File.dirname(__FILE__) + '/../spec_helper'

describe OfficeHolder, " when asked for holders in an interval" do
  
  before(:all) do 
    @start_date = Date.new(1844, 1, 3)
    @end_date = Date.new(1855, 2, 3)
    @office = mock_model(Office)
  end
    
  it 'should ask for all office holders with associated people whose dates overlap the interval passed' do 
    condition_string = "(start_date <= ? or start_date is null) and (end_date >= ? or end_date is null) and office_id = ?"
    OfficeHolder.should_receive(:find).with(:all, 
                            :conditions => [condition_string, @end_date, @start_date, @office],
                            :include => [:person])
    OfficeHolder.holders_for_interval(@office, @start_date, @end_date)
  end
  
end


describe OfficeHolder, " when asked for people in office" do

  before(:all) do 
    @date = Date.new(1844, 1, 3)
    @office = mock_model(Office)
  end
  
  it 'should ask for holders in interval' do 
    OfficeHolder.should_receive(:holders_for_interval).with(@office, @date, @date).and_return([])
    OfficeHolder.people_in_office(@office, @date)
  end
  
  it 'should return the people associated with the office holders in the interval' do 
    OfficeHolder.stub!(:holders_for_interval).and_return([mock_model(OfficeHolder, :person => 'the person')])
    OfficeHolder.people_in_office(@office, @date).should == ['the person']
  end
  
  it 'should not return any nils if there are office holders without people' do 
    OfficeHolder.stub!(:holders_for_interval).and_return([mock_model(OfficeHolder, :person => nil)])
    OfficeHolder.people_in_office(@office, @date).should == []    
  end
  
end

