namespace :hansard do

  desc 'clears db, parses xml matching data/**/housecommons_*.xml and persists in db'
  task :load_commons => [:environment] do
    sittings = Sitting.find(:all)
    puts "Destroying #{sittings.size} sittings."
    sittings.each {|sitting| sitting.destroy}

    per_file('housecommons_*xml') do |file|
      Hansard::HouseCommonsParser.new(file).parse.save!
    end
  end

  desc 'clears db, parses xml matching data/**/index.xml and persists in db'
  task :load_indices => [:environment] do
    Index.delete_all
    puts 'Deleted indices.'

    per_file('index.xml') do |file|
      Hansard::IndexParser.new(file).parse.save!
    end
  end

  def per_file pattern, &block
    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    puts 'directory count is: ' + directories.size.to_s
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+'/'+pattern).each do |file|
          puts 'parsing: ' + file
          yield file
          puts 'persisted: ' + file
        end
      end
    end
  end

end
