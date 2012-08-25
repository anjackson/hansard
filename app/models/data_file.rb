class DataFile < ActiveRecord::Base

  belongs_to :source_file
  has_one :sitting, :foreign_key => "data_file_id"
  has_one :volume, :foreign_key => "data_file_id"

  validates_presence_of :name
  validates_presence_of :directory

  before_validation_on_create :default_attributes
  after_save :update_counter_cache
  after_destroy :update_counter_cache

  class << self
    def reload_possible?
      not(ApplicationController.is_production?)
    end

    def log_to_stdout(message)
      puts message
    end

    def from_file file
      name = File.basename(file)
      directory = 'data' + File.dirname(file).split('data').last
      data_file = DataFile.find_by_name_and_directory(name, directory)
      unless data_file
        data_file = DataFile.new :name => name, :directory => directory
        data_file.save!
      end
      data_file
    end
  end

  def reload_possible?
    (DataFile.reload_possible? && !date.nil? && !get_reload_action.nil?)
  end

  def log_exception e
    backtrace = e.backtrace.to_s
    backtrace = backtrace[0..149] if (backtrace && backtrace.size > 150)
    add_log "parsing FAILED\t" + e.to_s + "\n" + backtrace.gsub("'/","' /")
    save!
  end

  def file
    path = File.join(self.directory, name)
    File.new(path)
  end

  def hpricot_doc
    Hpricot.XML File.open(file.path)
  end

  NAME_PATTERN = regexp '(.+)\d\d\d\d_\d\d_\d\d'

  def type_of_data
    if (match = NAME_PATTERN.match name)
      match[1].gsub('_', ' ').sub('writtenanswers','written answers').sub('writtenstatements','written statements')
    else
      type_of_data = name.split('_')[0]
      type_of_data.sub('house','')
    end
  end

  def get_reload_action
    action = nil
    action = 'reload_commons_for_date' if type_of_data.include? 'housecommons'
    action = 'reload_lords_for_date' if type_of_data.include? 'houselords'
    action = 'reload_written_answers_for_date' if name.include? 'writtenanswers'
    action = 'reload_commons_for_date' if type_of_data.include? 'westminsterhall'
    action = 'reload_written_statements_for_date' if name.include? 'writtenstatements'
    action
  end

  DATE_PATTERN = regexp '\d\d\d\d_\d\d_\d\d'

  def directory_date
    if (match = DATE_PATTERN.match directory)
      Date.parse(match[0].gsub('_','-'))
    else
      nil
    end
  end

  def date_text
    if (match = DATE_PATTERN.match name)
      match[0].gsub('_', '/')
    else
      nil
    end
  end

  def date
    if date_text && date_text.size == 10
      begin
        Date.parse(date_text.gsub('/', '-'))
      rescue Exception => e
        nil
      end
    else
      nil
    end
  end

  def add_log text, persist=true
    self.log = '' if log.nil?
    DataFile.log_to_stdout(text)
    $stdout.flush
    if persist
     text = self.log + (text.sub('ruby/gems','ruby/ gems') + "\n")
     self.log = text
    end
  end

  def reset_fields
    self.attempted_parse = false
    self.parsed = false
    self.attempted_save = false
    self.saved = false
    self.log = ''
    self.save!
  end

  def stripped_name
    self.directory.split('/').last
  end

  def update_counter_cache
    return unless source_file
    return unless source_file.volume
    source_file.volume.sittings_tried_count = source_file.data_files.count( :conditions => ["name != 'header.xml'"])
    source_file.volume.save!
  end

  protected
    def default_attributes
      self.attempted_parse = 0 unless self.attempted_parse
      self.parsed = 0 unless self.parsed
      self.attempted_save = 0 unless self.attempted_save
      self.saved = 0 unless self.saved
    end

end
