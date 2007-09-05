namespace :hansard do

  desc 'populates data files table based on files in /data'
  task :populate_data_files => [:environment] do
    per_file('*xml') do |file|
      name = File.basename(file)
      directory = File.dirname(file)
      if DataFile.count("name = '#{name}' and directory = '#{directory}'") == 0
        data_file = DataFile.new :name => name, :directory => directory
        data_file.save!
      end
    end
  end

  desc 'dummy task, refers to load_commons'
  task :load_db => [:environment] do
    puts "There's no hansard:load_db task. Try hansard:load_commons!"
  end

  desc 'clears db, parses xml matching data/**/housecommons_*.xml and persists in db'
  task :load_commons => [:environment] do
    sleep_seconds = ENV['sleep'].to_i if ENV['sleep']
    per_file('housecommons_*xml') do |file|
      parse_file(file, Hansard::HouseCommonsParser)
      sleep sleep_seconds if sleep_seconds
    end
  end

  desc 'clears db, parses xml matching data/**/index.xml and persists in db'
  task :load_indices => [:environment] do
    sleep_seconds = ENV['sleep'].to_i if ENV['sleep']
    Index.destroy_all
    puts 'Deleted indices.'
    per_file('index.xml') do |file|
      parse_file(file, Hansard::IndexParser)
      sleep sleep_seconds if sleep_seconds
    end
  end

  desc 'clears db, parses xml matching data/**/writtenanswers_*.xml and persists in db'
  task :load_written => [:environment] do
    sleep_seconds = ENV['sleep'].to_i if ENV['sleep']
    sittings = WrittenAnswersSitting.find(:all)
    puts "Attempting to destroy #{sittings.size} written answers sittings."
    destroy sittings
    per_file('writtenanswers*xml') do |file|
      parse_file(file, Hansard::WrittenAnswersParser)
      sleep sleep_seconds if sleep_seconds
    end
  end

  def destroy models
    models.each do |model|
      model.destroy
      puts "Destroyed #{model}."
    end
  end

  def parse_file(file, parser)
    data_file = DataFile.from_file(file)
    unless data_file.saved?
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

  def per_file pattern, &block
    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    puts 'directory count is: ' + directories.size.to_s
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+'/'+pattern).each do |file|
          yield file
        end
      end
    end
  end

end
