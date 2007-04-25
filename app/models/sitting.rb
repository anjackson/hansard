class Sitting < ActiveRecord::Base
  has_many :sections, :foreign_key => "SittingId"
  set_primary_key :Id
  
  def Date
    @Date = self.SatAt.strftime("%A %d %B %Y")
  end
  
end
