class SourceFile < ActiveRecord::Base

  has_many :data_files
  validates_uniqueness_of :name
  has_one :volume

  def self.from_file file
    name = File.basename(file, '.xml')
    SourceFile.find_or_create_by_name(name)
  end

  def self.log_to_stdout(message)
    puts message
  end

  def self.error_summary
    @error_summary ||= get_error_summary
  end
  
  def self.error_slug(string)
    Acts::Slugged.normalize_text(string) 
  end
  
  def self.error_from_slug(slug)
    error_types, error_types_to_files = error_summary
    type = error_types.find{ |type| error_slug(type) == slug } 
  end
  
  def self.get_error_summary
    files = SourceFile.find(:all).select {|f| f.log? }
    error_types = []
    error_types_to_files = {}

    files.each do |file|
      file.log.each_line do |error|
        if error.include? ':'
          type = error.split(':')[0]
        else
          type = error
        end
        type.chomp!('? Got')
        type.strip!
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

  def series_house
    SourceFile.series_house(name)
  end
  
  def series_number
    SourceFile.series_number(name)
  end
  
  def volume_number 
    SourceFile.volume_number(name)
  end
  
  def part_number
    SourceFile.part_number(name)
  end
    
  def add_log text, persist=true
    self.log = '' if log.nil?
    SourceFile.log_to_stdout(text)
    $stdout.flush
    if text.size > 255
      text = text[0..255]
    end

    if persist
      text = "\n" + text if self.log?
      text = self.log + text
      self.log = text
    end
  end
  
  def missing_session_tag?
    !extract_from_log(/Missing session tag/, 0).empty?
  end
  
  def bad_session_tag
    errors = extract_from_log(/Badly formatted session tag: (.*)/, 1)
    errors.empty? ? nil : errors.first
  end
  
  def missing_columns
    extract_from_log(/Missing column\? Got: \d+, expected (\d+) \(last column \d+\)/, 1)
  end
  
  def missing_images
    extract_from_log(/Missing image\? Got: \d+, expected (\d+) \(last image \d+\)/, 1)
  end
  
  def large_gaps_between_dates
    extract_from_log(/Large gap between dates: (.* and .*)/, 1)
  end
  
  def dates_outside_session
    extract_from_log(/Date not in session years: (.*)/, 1)
  end
  
  def bad_dates
    log_pattern = /Bad date format: date format="(.*)">(.*)<\/date>/
    extract_from_log(log_pattern, 1)
  end
  
  def corrected_dates
    corrected_dates = []
    log_pattern = /(Bad date format: date format="(.*)">(.*)<\/date> Suggested date: (.*))/
    correction_logs = extract_from_log(log_pattern, 1)
    correction_logs.each do |log|
      correction_match = log_pattern.match(log)
      corrected_dates << { :extracted_date => correction_match[2],
                           :original_text  => correction_match[3],
                           :corrected_date => correction_match[4] }
    end
    corrected_dates
  end
  
  def bad_oralquestions_content
    log_pattern = /(.*) in oralquestions/
    extract_from_log(log_pattern, 1)
  end
  
  def extract_from_log(pattern, group)
    missing_tags = []
    return missing_tags unless log
    log.each_line do |problem|
      if match = pattern.match(problem)
        missing_tags << match[group]
      end
    end
    missing_tags
  end
  
  def header_data_file
    data_files.find_by_name('header.xml')
  end
  
  def self.series_house(filename)
    house_letter = filename.at(2)
    return 'lords' if house_letter ==  'L'
    return 'commons' if house_letter == 'C'
    return 'both'
  end
  
  def self.series_number(filename)
    /S(\d)/.match(filename)[1].to_i
  end
  
  def self.volume_number(filename)
    /V(\d\d\d\d)/.match(filename)[1].to_i
  end
  
  def self.part_number(filename)
    /P(\d)/.match(filename)[1].to_i
  end
  
  def self.info_from_filename(filename)
    { :house  => series_house(filename),
      :series => series_number(filename),
      :volume => volume_number(filename), 
      :part   => part_number(filename) }
  end

end