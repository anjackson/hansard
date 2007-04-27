class Section < ActiveRecord::Base
  set_primary_key :Id
  belongs_to :sitting, :foreign_key => "SittingId"
  
  def time
    @Time = self.CreatedDate.strftime("%I:%M%p")
  end
  
  def name_without_version
    @name_without_version = self.FirstTurnCode[0,2] + "-" + self.LastTurnCode[0,2]
  end
  
end
