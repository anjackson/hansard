class BillMention < ActiveRecord::Base
  
  belongs_to :bill
  belongs_to :contribution
  belongs_to :section
  belongs_to :sitting
  
end