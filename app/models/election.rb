class Election < ActiveRecord::Base
  
  def self.find_all_by_year(year)
    find(:all, :conditions => ['YEAR(date) = ?', year])
  end
  
  def self.find_all_by_dissolution_year(year)
    find(:all, :conditions => ['YEAR(dissolution_date) = ?', year])
  end
  
end