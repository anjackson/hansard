class SourceFile < ActiveRecord::Base

  has_many :data_files
  validates_uniqueness_of :name

  def self.from_file file
    name = File.basename(file, '.xml')
    SourceFile.find_or_create_by_name(name)
  end

  def self.get_error_summary
    files = SourceFile.find(:all).select {|f| !f.log.blank?}
    error_types = []
    error_types_to_files = {}

    files.each do |file|
      file.log.each_line do |error|
        if error.include? ':'
          type = error.split(':')[0]
        else
          type = error
        end

        error_types << type unless error_types.include?(type)
        error_types_to_files[type] = [] unless error_types_to_files.has_key?(type)

        unless error_types_to_files[type].include?(file.name)
          error_types_to_files[type] << file.name
        end
      end
    end

    error_types.sort! do |a, b|
      a_size = error_types_to_files[a].size
      b_size = error_types_to_files[b].size
      if a_size == b_size
        a.to_s <=> b.to_s
      elsif a_size > b_size
        -1
      elsif a_size < b_size
        1
      end
    end
    return error_types, error_types_to_files
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
        text = "\n" + text
      end
      text = self.log + text
      self.log = text
    end
  end

end