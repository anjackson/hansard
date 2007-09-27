class SourceFile < ActiveRecord::Base

  has_many :data_files
  validates_uniqueness_of :name

  def self.from_file file
    name = File.basename(file, '.xml')
    SourceFile.find_or_create_by_name(name)
  end

  # surely there's a better way of counting lines?
  def log_line_count
    if self.log
      self.log.split("\n").length
    else
      0
    end
  end

  def reset_log
    self.log = nil
  end

  def to_param
    name
  end

  def add_log text, persist=true
    self.log = '' if log.nil?
    puts text
    $stdout.flush
    if persist
      unless self.log.blank?
        text = "/n" + text
      end
      text = self.log + text
      self.log = text
    end
  end

end