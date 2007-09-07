namespace :hansard do

  desc 'splits and loads Hansard XML files in /xml'
  task :load_files => :environment do
    @base_path = File.join(File.dirname(__FILE__),'..','..')
    Dir.mkdir(@base_path + '/data') unless File.exists?(@base_path + '/data')
    source_path = File.join @base_path, 'xml'

    raise "source directory #{source_path} not found" unless File.exists? source_path
    source_files = Dir.glob(File.join(source_path,'*'))
    raise "no source files found in #{source_path}" if source_files.size == 0

    @splitter = Hansard::Splitter.new(false, (overwrite=true), true)

    source_files.each do |file|
      source_file = split_file file
      load_split_files source_file
    end
  end

  def split_file file
    source_file = @splitter.split_file @base_path, file
    puts 'RESULT DIR ' + source_file.result_directory
    source_file
  end

  def load_split_files source_file
    
    Dir.glob(source_file.result_directory+'/housecommons_*xml').each do |file|
      parse_file(file, Hansard::HouseCommonsParser, source_file)
    end

    Dir.glob(source_file.result_directory+'/index.xml').each do |file|
      parse_file(file, Hansard::IndexParser, source_file)
    end

    Dir.glob(source_file.result_directory+'/writtenanswers_*xml').each do |file|
      parse_file(file, Hansard::WrittenAnswersParser, source_file)
    end
  end

  def parse_file(file, parser, source_file)
    data_file = DataFile.from_file(file)
    unless data_file.saved?
      data_file.source_file = source_file
      data_file.log = ''
      data_file.add_log "parsing\t" + data_file.name, false
      data_file.add_log "directory:\t" + data_file.directory, false
      data_file.attempted_parse = true
      begin
        result = parser.new(file, data_file).parse
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
        end
      rescue Exception => e
        data_file.add_log "parsing FAILED\t" + e.to_s
        data_file.save!
      end
    end
  end
end
