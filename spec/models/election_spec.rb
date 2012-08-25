require File.dirname(__FILE__) + '/../spec_helper'

describe Election do 
  
  describe 'when asked for elections by year' do 
  
    it 'should ask for elections whose year is the year given' do
      Election.should_receive(:find).with(:all, :conditions => ['YEAR(date) = ?', 1443])
      Election.find_all_by_year(1443)
    end
  
  end
  
  describe 'when asked for elections by dissolution year' do 
  
    it 'should ask for elections whose dissolution year is the year given' do
      Election.should_receive(:find).with(:all, :conditions => ['YEAR(dissolution_date) = ?', 1332])
      Election.find_all_by_dissolution_year(1332)
    end
    
  end
  
end