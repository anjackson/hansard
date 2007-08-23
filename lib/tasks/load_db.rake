require File.join(File.dirname(__FILE__),'..','housecommons_parser.rb')

namespace :hansard do

  desc 'clears db, parses xml found in data/**/housecommons_*.xml and persists in db'
  task :load_db => [:environment] do
    Sitting.delete_all
    puts 'Deleted Sittings.'
    Section.delete_all
    puts 'Deleted Sections.'
    Contribution.delete_all
    puts 'Deleted Contributions.'

    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+"/housecommons_*xml").each do |f|
          parse f
        end
      end
    end
  end

  def parse file
    @sitting = Hansard::HouseCommonsParser.new(file).parse
    puts 'Parsed: ' + file
    @sitting.save!
    puts 'Saved: ' + file
  end
end
