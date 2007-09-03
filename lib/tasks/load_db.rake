namespace :hansard do

  desc 'clears db, parses xml found in data/**/housecommons_*.xml and persists in db'
  task :load_db => [:environment] do
    Sitting.delete_all
    puts 'Deleted Sittings.'
    Section.delete_all
    puts 'Deleted Sections.'
    Contribution.delete_all
    puts 'Deleted Contributions.'
    Index.delete_all
    puts 'Deleted Indices.'
    

    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    puts 'directory count is: ' + directories.size.to_s
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+"/housecommons_*xml").each do |f|
          parse f, Hansard::HouseCommonsParser
        end
        Dir.glob(d+"/index.xml").each do |f|
          parse f, Hansard::IndexParser
        end
      end
    end
  end

  def parse file, parser
    @sitting = parser.new(file).parse
    puts 'Parsed: ' + file
    @sitting.save!
    puts 'Saved: ' + file
  end
end
