require 'fileutils'
require File.dirname(__FILE__) + '/hansard_transformer'

module Hansard
end

class Hansard::Splitter

  include Hansard::SchemaValidator

  attr_accessor :date, :source_file, :dates, :session_start_year, :session_end_year, :image_num
  attr_accessor :buffer, :index, :column_num, :lines, :directory_name, :image_string, :image_pattern
  attr_accessor :new_section
  attr_reader :outside_buffer, :outside_section_name, :outside_date, :section_name, :source_file

  SPLIT_ON = [
        'houselords',
        'housecommons',
        'writtenstatements',
        'writtenanswers',
        'westminsterhall',
        'grandcommitteereport',
        'index'
    ]

  DATE_PATTERN = regexp('date format="(\d\d\d\d-\d\d-\d\d)"\/?>(.*?)(<\/date>|$)')
  SCHEMA_PATTERN = regexp('xsi:noNamespaceSchemaLocation="(.*?)"')
  ORDERS_OF_THE_DAY = regexp('orders of the day','i')
  BUSINESS_OF_THE_HOUSE = regexp('business of the house','i')
  SESSION_PATTERN = regexp('<session>(.*?)<\/session>', 'i')

  REQUIRED_TAGS = ['frontmatter',
                   'index',
                   'titlepage',
                   'session']

  class << self
    def is_orders_of_the_day? line
      if line.include?('<title')
        ORDERS_OF_THE_DAY.match(line) ? true : false
      else
        false
      end
    end

    def is_business_of_the_house? line
      if line.include?('<title')
        BUSINESS_OF_THE_HOUSE.match(line) ? true : false
      else
        false
      end
    end
  end

  def initialize overwrite=true, verbose=true, sleep_seconds=nil
    @verbose = verbose
    @overwrite = overwrite
    @additional_lines = 0
    @sleep_seconds = sleep_seconds
    @column_pattern = /<col>(.*?)<\/col>/
  end

  def add_log text
    source_file.add_log text
  end

  def split base_path
    reset_data_path base_path
    source_files = get_source_files base_path
    source_files.collect { |file| split_the_file file }
  end

  def split_file base_path, input_file
    reset_data_path base_path
    split_the_file input_file
  end

  def reset_data_path base_path
    @files_created = []
    @data_path = File.join base_path, 'data'
    Dir.mkdir(@data_path) unless File.exists?(@data_path)
  end

  def get_source_files base_path
    source_path = File.join(base_path, 'xml')
    raise "source directory #{source_path} not found" unless File.exists? source_path
    source_files = Dir.glob(File.join(source_path,'*'))
    raise "no source files found in #{source_path}" if source_files.empty?
    source_files
  end

  def split_the_file input_file
    @additional_lines = 0
    puts input_file if @verbose
    source_file = handle_file(input_file)
    source_file.save!
    source_file
  end

  def write_to_file name, buffer, date=nil
    if @house && (name == 'writtenanswers' || name == 'writtenstatements')
      name = "#{@house}_#{name}"
    end

    name = name + '_' + date.to_s.gsub('-','_') if date
    file_name = File.join @result_path, name+'.xml'

    if @files_created.include? file_name
      part_index = 2
      while @files_created.include? file_name
        file_name = File.join @result_path, name+"_part_#{part_index}.xml"
        part_index = part_index.next
      end
    end

    File.open(file_name, 'w') do |file|
      file.write(buffer.join(''))
    end

    @files_created << file_name
  end

  def handle_section_start element, line
    if @section_name
      @outside_buffer = self.buffer
      @outside_section_name = @section_name
      @outside_date = @date
      @outside_start = @start
      self.buffer = []
    end
    @section_name = element
    @start = self.index
    self.new_section = true
    self.buffer << line
  end

  def handle_section_end line
    if section_name
      self.buffer << line
      puts @date.to_s + "\t" + @section_name + "\t" + @outside_start.to_s + '-' + self.index.to_s + "\t" + self.buffer.size.to_s  if @verbose
      write_to_file @section_name, self.buffer, @date
      self.buffer = @outside_buffer
      @section_name = @outside_section_name
      @date = @outside_date
      @outside_buffer = []
      @outside_section_name = nil
      @outside_date = nil
    elsif !outside_buffer.empty?
      @outside_buffer = outside_buffer # to make it possible to spec code
      puts @outside_date.to_s + "\t" + @outside_section_name + "\t" + @start.to_s + '-' + self.index.to_s + "\t" + @outside_buffer.size.to_s  if @verbose
      @outside_buffer << line
      write_to_file @outside_section_name, @outside_buffer, @outside_date
      @outside_buffer = []
    end
  end

  def check_for_issues line
    @inside_oralquestions = true if line.include? '<oralquestions>'
    @inside_oralquestions = false if line.include? '</oralquestions>'

    if line.include? '<division>'
      @inside_division = true

    elsif line.include? '</division>'
      @inside_division = false
    end

    if @inside_oralquestions && line.include?('<division>')
      add_log 'Division element in oralquestions'
    end
    if @inside_oralquestions && Hansard::Splitter.is_business_of_the_house?(line)
      add_log 'Business of the House title in oralquestions'
    end
    if @inside_oralquestions && Hansard::Splitter.is_orders_of_the_day?(line)
      add_log 'Orders of the Day title in oralquestions'
    end
  end

  END_AND_START_TAG_PATTERN = regexp('^<\/([^>]+)>\s*<([^>]+)>')

  def handle_line line, proxy=false
    self.index = self.index.next unless proxy

    check_for_issues line
    token_element = false

    closing_and_opening_on_same_line = false
    opening_element = nil
    closing_element = nil

    if (match = END_AND_START_TAG_PATTERN.match line)
      if SPLIT_ON.include?(match[1]) && SPLIT_ON.include?(match[2])
        closing_element = match[1]
        opening_element = match[2]
        closing_and_opening_on_same_line = true
      end
    end

    proxy_lines = []

    if closing_and_opening_on_same_line
      puts 'element closing and element opening on same line: ' + line if @verbose
      proxy_line = line.sub('</'+closing_element+'>','')
      line = line.sub('<'+opening_element+'>', '')
      proxy_lines << proxy_line
      @additional_lines = @additional_lines + 1
    end

    SPLIT_ON.each do |element|
      if line.include? '<'+element+'>'
        handle_section_start element, line
        token_element = true
        proxy_lines = add_missing_tags_to_section_start(proxy_lines)
      end

      if line.include? '</'+element+'>'
        handle_section_end line
        token_element = true
      end
    end

    if (@section_name == nil) and (token_element == false)
      @surrounding_buffer << line
    end

    if @section_name and token_element == false
      self.buffer << line
    end

    check_line(line)
    proxy_lines.each {|l| handle_line l, proxy=true}
  end

  def add_missing_tags_to_section_start(proxy_lines)
    found_image = false 
    found_column = false
    line_index = self.index
    6.times do
      found_image = true if self.image_pattern.match(self.lines[line_index])
      found_column = true if @column_pattern.match(self.lines[line_index])
      line_index += 1
    end  
    unless found_image
      proxy_image_line = "<image src=\"#{self.directory_name}I#{self.image_string}\"/>\n"
      proxy_lines << proxy_image_line
      @additional_lines += 1
    end
    unless found_column
      proxy_column_line = "<col>#{column_num}</col>\n"
      proxy_lines << proxy_column_line
      @additional_lines += 1
    end
    proxy_lines
  end
  
  def check_line(line)
    check_for_schema(line) unless source_file.schema
    check_for_required_tags(line)
    check_for_date(line)
    check_for_image(line)
    check_for_column(line)
    check_for_session(line)
  end
  
  def clear_directory path
    if File.exists? path
      if @overwrite
        Dir.glob(File.join(path,'*.xml')).each do |file|
          File.delete file
        end
      end
    else
      Dir.mkdir path
    end
  end

  REQUIRED_START_TAG_PATTERNS = REQUIRED_TAGS.inject([]) {|list, tag| list << [tag, regexp("<#{tag}>")]; list}
  REQUIRED_END_TAG_PATTERNS = REQUIRED_TAGS.inject([]) {|list, tag| list << [tag, regexp("<\/#{tag}>")]; list}

  def check_for_required_tag patterns, line, hash
    patterns.each do |tag_pattern|
      if tag_pattern[1].match line
        hash[tag_pattern[0]] = true
      end
    end
  end

  def check_for_required_tags line
    check_for_required_tag REQUIRED_START_TAG_PATTERNS, line, @required_tags
    check_for_required_tag REQUIRED_END_TAG_PATTERNS, line, @required_tag_ends
  end

  def check_for_image line
    if (match = self.image_pattern.match line)
      self.image_string = match[1]
      new_image_num = self.image_string.to_i
      if unexpected_image?(new_image_num)
        add_log "Missing image? Got: #{new_image_num}, expected #{self.image_num+1} (last image #{self.image_num})"
      end
      self.image_num = new_image_num
    end
  end

  def check_for_column line
    if (match = @column_pattern.match line)
      new_column_num = match[1].to_i
      if unexpected_column?(new_column_num)
        add_log "Missing column? Got: #{new_column_num}, expected #{@column_num+1} (last column #{@column_num})"
      end
      @column_num = new_column_num
      self.new_section = false
    end
  end
  
  def unexpected_column?(new_column_num)
    return false if self.new_section and (new_column_num == 1 or new_column_num == @column_num)
    return true if @column_num+1 != new_column_num 
    return false
  end

  
  def unexpected_image?(new_image_num)
    return false if self.new_section and (new_image_num == self.image_num)
    return true if self.image_num+1 != new_image_num
    return false
  end
  
  def check_for_session line
    if (match = SESSION_PATTERN.match line)
      session = match[1]
      session_years_patt = /^(\d\d\d\d)(&#x2013;(\d?\d?\d\d))?\.?$/
      session_years = session_years_patt.match session
      if session_years
        self.session_start_year = session_years[1]
        self.session_end_year = (session_years[3] or session_years[1])
        if self.session_end_year.size == 2
          self.session_end_year = (self.session_start_year[0...2] + self.session_end_year).to_i
        end
        self.session_start_year = session_start_year.to_i
        self.session_end_year = session_end_year.to_i
      else
        add_log "Badly formatted session tag: #{session}"
      end
    end
  end

  def log_bad_date_format text, suggested_date=nil
    message = "Bad date format: #{text}"
    message += " Suggested date: #{suggested_date}" if suggested_date
    add_log(message)
  end

  def handle_minutes_date_string(match, minutes_date, tag_date, previous_date)
    date_string = "#{tag_date.year} #{minutes_date[1]} #{minutes_date[2]}"
    compare_tag_date_with_parsed_date(match, tag_date, date_string, previous_date)
  end

  def handle_basic_date_string(match, new_date_text, tag_date, previous_date)
    date_string = new_date_text.gsub(/\.|,/, '')
    date_string = date_string.gsub(/(\d)\s+(th|st)\s/, '\1\2 ')
    compare_tag_date_with_parsed_date(match, tag_date, date_string, previous_date)
  end

  def handle_answers_date_string(match, answers_date, tag_date, previous_date)
    day = answers_date[1]
    month = (answers_date[2].blank? ? answers_date[3] : answers_date[2])
    year = answers_date[4]
    date_string = "#{year} #{month} #{day}"
    compare_tag_date_with_parsed_date(match, tag_date, date_string, previous_date)
  end

  def compare_tag_date_with_parsed_date(match, tag_date, date_string, previous_date)
    parsed_date = nil
    begin
      parsed_date = parse_date(date_string)
      day_string = Date::DAYNAMES[parsed_date.wday]
      if parsed_date != tag_date and /#{day_string}/.match(date_string) && parsed_date < LAST_DATE
        log_bad_date_format match[0], parsed_date
        parsed_date
      else
        tag_date
      end
    rescue
      log_bad_date_format match[0]
      tag_date
    end
  end

  def parse_date date_string
    parsed_date = Date.parse(date_string)
    if parsed_date && (parsed_date > LAST_DATE) && previous_date
      parsed_date = Date.new(previous_date.year, parsed_date.month, parsed_date.day)
    end
    parsed_date
  end

  FROM_MINUTES = regexp('From Minutes of ([^ ]*) (\d+)')
  ANSWERS_DATES = regexp('The following answers were received between ?(?:[^ ]*) (\d+) ?([^ ]*) and .*? ([^ ]+) (\d+)<\/date>')

  def check_for_date line
    if (match = DATE_PATTERN.match line)
      tag_date_string = match[1]
      tag_date = Date.parse(tag_date_string)

      new_date_text = match[2]
      @date = if (minutes_date = FROM_MINUTES.match(line))
          handle_minutes_date_string(match, minutes_date, tag_date, @previous_date)
        elsif (answers_date = ANSWERS_DATES.match(line))
          handle_answers_date_string(match, answers_date, tag_date, @previous_date)
        else
          handle_basic_date_string(match, new_date_text, tag_date, @previous_date)
        end

      @previous_date = @date
      self.dates << @date
      @date = @date.to_s
      @first_date = @date unless @first_date
    end
  end

  def check_for_schema line
    if (match = SCHEMA_PATTERN.match line)
      @source_file.schema = match[1]
    end
  end

  def result_file_path input_file
    size_in_mb = (File.size(input_file)/ 1048576.0)
    mb = ((size_in_mb*100).round/100.0).to_s
    house_string = @house || 'both'
    if @first_date
      first_part = @first_date.to_s.gsub('-','_')
    else
      first_part = 'index'
    end
    result_path = File.join(@data_path, first_part +'_'+house_string)+'_'+mb+'mb'
  end

  def move_final_result directory_name, input_file
    result_path = result_file_path(input_file)
    Dir.mkdir result_path unless File.exists?(result_path)
    result_directory = File.join(result_path, directory_name)
    FileUtils.remove_dir result_directory, true
    FileUtils.mv @result_path, result_directory
    @source_file.result_directory = result_directory
    @source_file
  end

  def handle_file input_file
    @directory_name = input_file.split(File::SEPARATOR).last.chomp('.xml')
    @result_path = File.join @data_path, @directory_name
    @source_file = SourceFile.from_file(input_file)
    @source_file.reset_log
    @image_pattern = /image src="#{@directory_name}I(\d\d\d\d)"\//
    self.image_num = 0
    @column_num = 0
    process_file input_file, @directory_name
  end

  def validate_schema
    if source_file.schema
      error = validate_against_schema(source_file.schema, source_file.name)
      if error.blank?
        source_file.xsd_validated = true
      else
        source_file.xsd_validated = false
        add_log 'Schema validation failed: ' + error
      end
    end
  end

  def initialize_attributes input_file
    self.index = 0
    @surrounding_buffer = []
    self.buffer = []
    @outside_buffer = []
    @section_name = nil
    @date = nil
    self.dates = []
    @session_start_year = nil
    @session_end_year = nil
    @first_date = nil
    @previous_date = nil
    @required_tags = {}
    @required_tag_ends = {}
    @inside_oralquestions = false
    @house = house(input_file)
  end

  def is_historic_hansard? input_file
    file_name = input_file.split(File::SEPARATOR).last
    (!file_name[/^(S)\d/].nil?)
  end

  def process_file input_file, directory_name
    clear_directory @result_path
    initialize_attributes input_file

    if is_historic_hansard?(input_file)
      @lines = File.new(input_file).readlines
      @lines.each { |line| handle_line line }
      
      REQUIRED_TAGS.each do |tag|
        add_log("Missing #{tag} tag") unless @required_tags[tag]
        add_log("Broken #{tag} tag") if (@required_tags[tag] and not @required_tag_ends[tag])
      end

      @source_file.start_date = @first_date
      check_unlikely_dates
      puts 'header ' + @surrounding_buffer.size.to_s  if @verbose
      write_to_file 'header', @surrounding_buffer
      check_line_count_correct input_file
      move_final_result directory_name, input_file

    else
      Dir.rmdir(@result_path)
      transformer = Hansard::Transformer.new(input_file, @data_path)
      transformer.transform
      @source_file.result_directory = transformer.result_path
      @first_date = transformer.date
    end

    @source_file
  end

  def check_unlikely_dates
    self.dates = dates.sort
    dates.each_cons(2) do |first_date, second_date|
      if second_date - first_date > 90
        add_log("Large gap between dates: #{first_date} and #{second_date}")
      end
    end
    return unless session_start_year and session_end_year
    dates.each do |date|
      unless date.year <= session_end_year and date.year >= session_start_year
        add_log("Date not in session years: #{date}")
      end
    end
  end

  def house input_file
    house_letter = File.basename(input_file).at(2)
    return 'lords' if house_letter ==  'L'
    return 'commons' if house_letter == 'C'
    return nil
  end

  def check_line_count_correct input_file
    total_lines = 0
    Dir.glob(File.join(@result_path,'*.xml')).each do |result|
      result_lines = 0
      File.open(result).each_line {|line| result_lines += 1}
      total_lines += result_lines
    end
    puts "total\t" + total_lines.to_s  if @verbose
    input_lines = @additional_lines
    File.open(input_file).each_line {|line| input_lines += 1}
    puts "original\t" + input_lines.to_s  if @verbose

    check_for_line_mismatch(input_lines, total_lines)
  end

  def check_for_line_mismatch input_lines, total_lines
    if total_lines != input_lines
      source_file.add_log("Line count: expected #{input_lines} but got #{total_lines}")
    end
  end

end
