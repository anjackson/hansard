class SourceFile < ActiveRecord::Base
  

  has_many :data_files
  validates_uniqueness_of :name
  
  def self.from_file file
    name = File.basename(file, '.xml')
    SourceFile.find_or_create_by_name(name)
  end
  
  # surely there's a better way of counting lines?
  def log_line_count
    self.log.split("\n").length
  end
  
  def to_param
    name
  end
  
  def add_log text, persist=true
    self.log = '' if log.nil?
    puts text
    $stdout.flush
    if persist
      text = self.log + (text + "\n")
      self.log = text
    end
  end  
  
end