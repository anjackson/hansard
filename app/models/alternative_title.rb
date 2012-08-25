class AlternativeTitle < ActiveRecord::Base
  
  belongs_to :person 
  acts_as_life_period
  
  def degree_and_title
   "#{degree} #{title}"
  end

end