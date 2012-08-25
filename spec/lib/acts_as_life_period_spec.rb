require File.dirname(__FILE__) + '/../spec_helper'

describe Acts::LifePeriod, "when " do 

  attr_accessor :start_date, :person, :end_date
  
  before do
    self.class.send(:include, Acts::LifePeriod)
    self.class.acts_as_life_period
  end
  
  describe 'when asked for its first possible date' do 

    it 'should return the start date if there is one' do 
      self.start_date = Date.new(1885, 2, 5)
      first_possible_date.should == self.start_date
    end

    it 'should return date of birth of the person if there is one' do 
      self.person = mock_model(Person, :date_of_birth => Date.new(1894, 2, 21))
      first_possible_date.should == self.person.date_of_birth
    end

    it 'should return the first date the application covers if there is not a start date' do 
      first_possible_date.should == FIRST_DATE
    end 

  end

  describe 'when asked for its last possible date'do 

    it 'should return the end date if there is one' do 
      self.end_date = Date.new(1885, 2, 5)
      last_possible_date.should == self.end_date
    end

    it 'should return date of death of the person if there is one' do 
      self.person = mock_model(Person, :date_of_death => Date.new(1894, 2, 21))
      last_possible_date.should == self.person.date_of_death
    end

    it 'should return the last date the application covers if there is not an end date or a person death date' do 
      last_possible_date.should == LAST_DATE
    end

  end
  
  
end