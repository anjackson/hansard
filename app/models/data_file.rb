class DataFile < ActiveRecord::Base

  validates_presence_of :name
  validates_presence_of :directory

  before_validation_on_create :default_attributes

  def self.from_file file
    name = File.basename(file)
    directory = 'data' + File.dirname(file).split('data')[1]
    data_file = DataFile.find_by_name_and_directory(name, directory)
    unless data_file
      data_file = DataFile.new :name => name, :directory => directory
      data_file.save!
    end
    data_file
  end

  def add_log text, persist=true
    self.log = '' if log.nil?
    puts text
    $stdout.flush
    if persist
      text = self.log + (text + "/n")
      self.log = text
    end
  end

  protected
    def default_attributes
      self.attempted_parse = 0 unless self.attempted_parse
      self.parsed = 0 unless self.parsed
      self.attempted_save = 0 unless self.attempted_save
      self.saved = 0 unless self.saved
    end

end
