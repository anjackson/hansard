require File.join(File.dirname(__FILE__),'..','housecommons_parser.rb')

namespace :hansard do

  desc 'clears db, parses xml found in data/**/housecommons_*.xml and persists in db'
  task :load_db => [:environment] do
    puts 'clearing db ...'
    Sitting.delete_all
    Section.delete_all
    Contribution.delete_all

    Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}.each do |d|
      Dir.glob(d+"/housecommons_*xml").each do |f|
        parse f
      end
    end
  end

  def parse file
    puts 'parsing: ' + file
    @sitting = Hansard::HouseCommonsParser.new(file).parse
    puts 'persisting: ' + file
    @sitting.save!
  end
end
