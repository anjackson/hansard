class ParserRun < ActiveRecord::Base

  def self.latest
    last_run = find(:first, :order => 'created_at desc')
    last_run ? last_run.created_at.to_s(:long_ordinal) : '(not recorded)' 
  end
  
end
