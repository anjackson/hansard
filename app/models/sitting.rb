class Sitting < ActiveRecord::Base
  set_primary_key :Id
  has_many :turns, :foreign_key => "SittingId", :conditions => "IsActive = 1", :order => "CreatedDate"
  has_many :sections, :foreign_key => "SittingId", :conditions => "IsActive = 1", :order => "CreatedDate"

  
  def date
    date = self.SatAt.strftime("%A %d %B %Y")
  end
  
  def intervals(length)
    currenttime = self.original_turns.first.CreatedDate
    endtime = self.original_sections.last.CreatedDate
    
    intervals = []
    while currenttime < endtime
      intervals << currenttime
      currenttime+=length.minutes
    end
    intervals
  end
  
  def original_turns
    self.turns.select{|turn|turn.CreatedDate.midnight == self.SatAt.midnight}
  end

  def original_sections
    self.sections.select{|section|section.CreatedDate.midnight == self.SatAt.midnight}
  end

  def turns_by_interval(length)

    intervals = self.intervals(length)
    turns_by_interval = {}
    
    intervals.each do |interval|
      turns_by_interval[interval] = []
    end
    
    self.original_turns.each do |turn|
      turn_interval = intervals.find{|interval|interval+length.minutes>turn.CreatedDate}
      turns_by_interval[turn_interval] << turn
    end
    
    turns_by_interval
  end

end
