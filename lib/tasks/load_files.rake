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
      result_directory = split_file file
      load_split_files result_directory
    end
  end

  def split_file file
    result_directory = @splitter.split_file @base_path, file
    puts 'RESULT DIR ' + result_directory
    result_directory
  end

  def load_split_files result_directory
    Dir.glob(result_directory+'/housecommons_*xml').each do |file|
      data_file = DataFile.from_file(file)
      unless data_file.saved?
        data_file.add_log "parsing\t" + data_file.name, false
        data_file.attempted_parse = true
        begin
          result = Hansard::HouseCommonsParser.new(file, data_file).parse
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

end
