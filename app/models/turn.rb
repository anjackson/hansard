class Turn < ActiveRecord::Base
  set_primary_key :Id
  belongs_to :sitting, :foreign_key => "SittingId"
  
  def time
    @time = self.CreatedDate.strftime("%I:%M%p")
  end
  
  def name
    firstletter = self.Code.divmod(25)[0]
    secondletter = self.Code.divmod(25)[1]
    if firstletter > 7
     firstletter+=1
    end
    if secondletter > 7
     secondletter+=1
    end
    @name = (firstletter + 65).chr + (secondletter + 65).chr
  end
  
end
