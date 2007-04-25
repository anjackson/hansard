class Section < ActiveRecord::Base
  set_primary_key :Id
  belongs_to :sitting, :foreign_key => "SittingId"
  
end
