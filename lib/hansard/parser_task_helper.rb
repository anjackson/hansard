module Hansard
end

module Hansard::ParserTaskHelper

  HEADER_PATTERN = 'header.xml'
  COMMONS_PATTERN = 'housecommons_*xml'
  LORDS_PATTERN = 'houselords_*xml'
  WRITTEN_PATTERN = 'writtenanswers_*xml'
  COMMONS_WRITTEN_PATTERN = 'commons_writtenanswers_*xml'
  LORDS_WRITTEN_PATTERN = 'lords_writtenanswers_*xml'

  WESTMINSTER_HALL_PATTERN = 'westminsterhall_*xml'
  GRAND_COMMITTEE_PATTERN = 'grandcommitteereport_*xml'

  WRITTEN_STATEMENTS_PATTERN = 'writtenstatements_*xml'
  COMMONS_WRITTEN_STATEMENTS_PATTERN = 'commons_writtenstatements_*xml'
  LORDS_WRITTEN_STATEMENTS_PATTERN = 'lords_writtenstatements_*xml'

  INDEX_PATTERN   = 'index.xml'

  def directories(pattern)
    Dir.glob(pattern).select{|f| File.directory?(f)}
  end

  def per_data_file pattern
    directories("#{File.dirname(__FILE__)}/../../data/*").each do |directory|
      directories("#{directory}/*").each do |d|
        Dir.glob(d+'/'+pattern).each do |file|
          yield d, file
        end
      end
    end
  end

  def reload_commons_on_date date
    reload_on_date(date, WESTMINSTER_HALL_PATTERN, WestminsterHallSitting, Hansard::WestminsterHallParser)
    reload_on_date(date, COMMONS_PATTERN, HouseOfCommonsSitting, Hansard::CommonsParser)
  end

  def reload_lords_on_date date
    reload_on_date(date, GRAND_COMMITTEE_PATTERN, GrandCommitteeReportSitting, Hansard::GrandCommitteeReportParser)
    reload_on_date(date, LORDS_PATTERN, HouseOfLordsSitting, Hansard::LordsParser)
  end

  def reload_written_answers_on_date date
    data_file_to_return = nil
    data_file = reload_on_date(date, WRITTEN_PATTERN, WrittenAnswersSitting, Hansard::WrittenAnswersParser)
    data_file_to_return = data_file if data_file
    data_file = reload_on_date(date, COMMONS_WRITTEN_PATTERN, CommonsWrittenAnswersSitting, Hansard::WrittenAnswersParser)
    data_file_to_return = data_file if data_file
    data_file = reload_on_date(date, LORDS_WRITTEN_PATTERN, LordsWrittenAnswersSitting, Hansard::WrittenAnswersParser)
    data_file_to_return = data_file if data_file
    data_file_to_return
  end

  def reload_written_statements_on_date date
    reload_on_date(date, WRITTEN_STATEMENTS_PATTERN, CommonsWrittenStatementsSitting, Hansard::WrittenStatementsParser)
    reload_on_date(date, COMMONS_WRITTEN_STATEMENTS_PATTERN, CommonsWrittenStatementsSitting, Hansard::WrittenStatementsParser)
    reload_on_date(date, LORDS_WRITTEN_STATEMENTS_PATTERN, LordsWrittenStatementsSitting, Hansard::WrittenStatementsParser)
  end

  def reload_on_date date, pattern, model_class, parser_type
    date_part = date.to_s.gsub('-','_')
    file_name = pattern.sub('*', date_part+'.')
    puts "finding data file " + file_name
    data_file = DataFile.find_by_name(file_name)
    data_file.reset_fields if data_file
    model = model_class.find_by_date(date)
    if model
      puts "destroying #{model_class.name} instance for #{date.to_s}"
      model.destroy
    else
      puts "destroying nothing"
    end

    if data_file
      directory = File.dirname(__FILE__) + "/../../" + data_file.directory
      xml_file_name = directory.split('/').last
      puts directory
      puts file_name
      puts xml_file_name
      source_file = SourceFile.from_file(xml_file_name)
      parse_via_data_file(directory + '/' + file_name, data_file, parser_type, source_file)
    end

    data_file
  end

  def parse_file(file, parser, source_file)
    data_file = DataFile.from_file(file)
    parse_via_data_file(file, data_file, parser, source_file)
  end

  OLD_DIVISION_HEADER = /(List of (Members who voted in )?the ?)?(AYES?|NOES|Majority|Minorit(y|ies)|Division|YES)\.?/i

  def self.old_division_header? text
    OLD_DIVISION_HEADER.match(text) ? true : false
  end

  def can_continue?
  end

  def parse_via_data_file(file, data_file, parser_class, source_file)
    unless data_file.saved?
      data_file.source_file = source_file
      data_file.log = ''
      data_file.add_log "Parsing    " + data_file.name, false
      data_file.add_log "Directory    " + data_file.directory, false
      data_file.attempted_parse = true
      begin
        begin
          try_parse file, data_file, source_file, parser_class
        rescue Hansard::DivisionParsingException => division_exception
          data_file.log_exception(division_exception)
          data_file.add_log 'Parsing without division matching'
          try_parse file, data_file, source_file, parser_class, parse_divisions=false
        end
      rescue Exception => e
        data_file.log_exception e
      end
    end
  end


  def try_parse file, data_file, source_file, parser_class, parse_divisions=true
    if [Hansard::LordsParser, 
        Hansard::CommonsParser,
        Hansard::WestminsterHallParser].include? parser_class 
      preprocessor = Hansard::DebatesPreprocessor.new
      preprocessor.clean_file(file, overwrite=true)
    end
    parser = parser_class.new(file, data_file, source_file, parse_divisions)
    result = parser.parse

    if data_file.log && data_file.log.strip == 'not creating sitting as housecommons file only contains Written Ministerial Statements'
      data_file.destroy
      return
    end
    data_file.parsed = true

    begin
      data_file.attempted_save = true
      result.data_file = data_file
      result.save!
      data_file.add_log "Saved    " + data_file.name, false
      data_file.saved = true
      data_file.save!
    rescue Exception => e
      data_file.add_log "Failed to save    " + e.to_s
      data_file.save!
    end
  end

  def base_path
    @base_path ||= File.join(File.dirname(__FILE__),'..','..')
  end

  def per_source_file total_processes, process_index
    Dir.mkdir(base_path + '/data') unless File.exists?(base_path + '/data')
    source_path = File.join base_path, 'xml'
    raise "source directory #{source_path} not found" unless File.exists? source_path
    source_files = Dir.glob(File.join(source_path,'*')).sort
    
    raise "no source files found in #{source_path}" if source_files.size == 0
    source_files.in_groups_of(total_processes) do |file_list|
      if file_list[process_index]
        yield file_list[process_index]
      end
    end
  end

  def split_file file
    name = file.split(File::SEPARATOR).last
    source_file = @splitter.split_file base_path, file
    puts 'RESULT DIR ' + source_file.result_directory if source_file.result_directory
    source_file
  end

  def load_split_files(source_file)
    load_source_files(source_file, HEADER_PATTERN,  Hansard::HeaderParser)
    load_source_files(source_file, COMMONS_PATTERN, Hansard::CommonsParser)
    load_source_files(source_file, WESTMINSTER_HALL_PATTERN, Hansard::WestminsterHallParser)
    load_source_files(source_file, LORDS_PATTERN,   Hansard::LordsParser)
    load_source_files(source_file, WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    load_source_files(source_file, COMMONS_WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    load_source_files(source_file, LORDS_WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    load_source_files(source_file, GRAND_COMMITTEE_PATTERN, Hansard::GrandCommitteeReportParser)
    load_source_files(source_file, WRITTEN_STATEMENTS_PATTERN, Hansard::WrittenStatementsParser)
    load_source_files(source_file, COMMONS_WRITTEN_STATEMENTS_PATTERN, Hansard::WrittenStatementsParser)
    load_source_files(source_file, LORDS_WRITTEN_STATEMENTS_PATTERN, Hansard::WrittenStatementsParser)
  end

  def load_source_files(source_file, pattern, parser)
    sleep_seconds = ENV['sleep'].to_i if ENV['sleep']

    Dir.glob(source_file.result_directory + "/" + pattern).each do |file|
      parse_file(file, parser, source_file)
      sleep sleep_seconds if sleep_seconds
    end
  end

  def reload_data_files(pattern, parser)
    sleep_seconds = ENV['sleep'].to_i if ENV['sleep']

    per_data_file(pattern) do |directory, file|
      source_file = SourceFile.from_file(directory)
      parse_file(file, parser, source_file)
      sleep sleep_seconds if sleep_seconds
    end
  end

end
