class OfficeHolder < ActiveRecord::Base
  belongs_to :office
  belongs_to :person
  acts_as_id_finder
  acts_as_life_period
  
  def OfficeHolder.people_in_office(office, date)
    holders = holders_for_interval(office, date, date)
    people = holders.map{ |holder| holder.person }.compact
  end
  
  def OfficeHolder.holders_for_interval(office, start_date, end_date)
    condition_string = "(start_date <= ? or start_date is null) and (end_date >= ? or end_date is null) and office_id = ?"
    holders = find(:all, 
                   :conditions => [condition_string, end_date, start_date, office], 
                   :include => [:person])  
  end
  
  def name
    person.name 
  end
  
end