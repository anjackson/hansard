module Hansard
end

module Hansard::ParserHelper

  COMMONS_PATTERN = 'housecommons_*xml'
  LORDS_PATTERN = 'houselords_*xml'
  WRITTEN_PATTERN = 'writtenanswers_*xml'
  INDEX_PATTERN   = 'index.xml'

  def per_data_file pattern, &block
    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+'/'+pattern).each do |file|
          yield d, file
        end
      end
    end
  end

  def reload_commons_on_date date
    reload_on_date(date, COMMONS_PATTERN, HouseOfCommonsSitting, Hansard::HouseCommonsParser)
  end

  def reload_lords_on_date date
    reload_on_date(date, LORDS_PATTERN, HouseOfLordsSitting, Hansard::HouseLordsParser)
  end

  def reload_index_on_date date
    reload_on_date(date, INDEX_PATTERN, Index, Hansard::IndexParser)
  end

  def reload_on_date date, pattern, model_class, parser_type
    date_part = date.to_s.gsub('-','_')
    if pattern == INDEX_PATTERN
      file_name = INDEX_PATTERN
      data_file = DataFile.find_by_sql("select * from data_files where directory like '%#{date_part}%' and name = 'index.xml'").first
      data_file.reset_fields if data_file
      model = model_class.find_by_start_date(date)
    else
      file_name = pattern.sub('*', date_part+'.')
      data_file = DataFile.find_by_name(file_name)
      data_file.reset_fields if data_file
      model = model_class.find_by_date(date)
    end

    if model
      puts "destroying #{model_class.name} instance for #{date.to_s}"
      model.destroy
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

  def parse_file(file, parser, source_file=nil)
    data_file = DataFile.from_file(file)
    parse_via_data_file(file, data_file, parser, source_file)
  end

  def parse_via_data_file(file, data_file, parser_class, source_file=nil)
    unless data_file.saved?
      data_file.source_file = source_file
      data_file.log = ''
      data_file.add_log "parsing\t" + data_file.name, false
      data_file.add_log "directory:\t" + data_file.directory, false
      data_file.attempted_parse = true
      begin
        parser = parser_class.new(file, data_file)
        result = parser.parse
        data_file.parsed = true

        begin
          data_file.attempted_save = true
          result.data_file = data_file
          result.save!
          data_file.add_log "saved\t" + data_file.name, false
          data_file.saved = true
          data_file.save!
        rescue Exception => e
          data_file.add_log "saving FAILED\t" + e.to_s
          data_file.save!
          raise e
        end
      rescue Exception => e
        data_file.add_log "parsing FAILED\t" + e.to_s
        data_file.save!
        raise e
      end
    end
  end

  def per_source_file
    @base_path = File.join(File.dirname(__FILE__),'..','..')
    Dir.mkdir(@base_path + '/data') unless File.exists?(@base_path + '/data')
    source_path = File.join @base_path, 'xml'
    raise "source directory #{source_path} not found" unless File.exists? source_path
    source_files = Dir.glob(File.join(source_path,'*'))
    raise "no source files found in #{source_path}" if source_files.size == 0
    source_files.each do |file|
      yield file
    end
  end

  def split_file file
    source_file = @splitter.split_file @base_path, file
    puts 'RESULT DIR ' + source_file.result_directory
    source_file
  end

  def load_split_files(source_file)
    load_source_files(source_file, COMMONS_PATTERN, Hansard::HouseCommonsParser)
    load_source_files(source_file, LORDS_PATTERN,   Hansard::HouseLordsParser)
    load_source_files(source_file, WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    load_source_files(source_file, INDEX_PATTERN,   Hansard::IndexParser)
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
