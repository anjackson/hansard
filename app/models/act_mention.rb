class ActMention < ActiveRecord::Base
  
  belongs_to :act
  belongs_to :contribution
  belongs_to :section
  belongs_to :sitting
  
end