class Section < ActiveRecord::Base
  belongs_to :sitting, :foreign_key => "SittingId"
  set_primary_key :Id

end
