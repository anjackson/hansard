require File.dirname(__FILE__) + '/../spec_helper'
include PeopleHelper

describe PeopleHelper do 
  
  describe "when giving alternative name details" do 
  
    before do 
      @alternative_name = mock_model(AlternativeName, :name => 'test name')
    end
  
    it 'should ask for the dates formatted correctly for unknown dates' do 
      should_receive(:dates_or_unknown).with(@alternative_name).and_return('dates')
      alternative_name_details(@alternative_name)
    end
  
    it 'should return the name and dates formatted for unknown dates' do 
      stub!(:dates_or_unknown).and_return("dates")
      alternative_name_details(@alternative_name).should == 'test name dates'
    end
  
  end
  
  describe 'when giving birth and death dates' do 
  
    before do 
      @person = mock_model(Person, :date_of_birth => Date.new(1977, 2, 10), 
                                   :estimated_date_of_birth => false,
                                   :date_of_death => Date.new(2006, 1, 23), 
                                   :estimated_date_of_death => false)
    end
  
    it 'should give "February 10, 1977 - " for someone with only a date of birth' do 
      @person.stub!(:date_of_death).and_return(nil)
      birth_and_death_dates(@person).should == 'February 10, 1977 - '
    end
    
    it 'should give " - January 23, 2006" for someone with only a date of death' do 
      @person.stub!(:date_of_birth).and_return(nil)
      birth_and_death_dates(@person).should == ' - January 23, 2006'
    end
    
    it 'should give "February 10, 1977 - January 23, 2006" for someone with a date of birth and date of death' do 
      birth_and_death_dates(@person).should == 'February 10, 1977 - January 23, 2006'
    end
  
    it 'should give "1977 - January 23, 2006" for someone with an estimated date of birth' do 
      @person.stub!(:estimated_date_of_birth).and_return(true)
      birth_and_death_dates(@person).should == '1977 - January 23, 2006'
    end
    
    it 'should give "February 10, 1977 - 2006" for someone with an estimated date of death' do 
      @person.stub!(:estimated_date_of_death).and_return(true)
      birth_and_death_dates(@person).should == 'February 10, 1977 - 2006'
    end
    
  end
  
end