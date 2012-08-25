class AlternativeName < ActiveRecord::Base
  
  belongs_to :person 
  acts_as_life_period
  
  def name
    [honorific, firstname, lastname].join(' ')
  end
end