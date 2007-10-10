require File.dirname(__FILE__) + '/../hansard/parser_helper'
require File.dirname(__FILE__) + '/../hansard/schema_helper'

namespace :hansard do

  COMMONS_PATTERN = 'housecommons_*xml'
  LORDS_PATTERN = 'houselords_*xml'
  WRITTEN_PATTERN = 'writtenanswers_*xml'
  INDEX_PATTERN   = 'index.xml'

  include Hansard::ParserHelper
  include Hansard::SchemaHelper

  desc 'attempts to validate XML source file against schema'
  task :validate_schema => :environment do
    validate_schema
  end

  task :migrate_down => :environment do
    ENV['VERSION'] = '0'
    Rake::Task['db:migrate'].execute
  end

  task :migrate_up => :environment do
    ENV.delete('VERSION')
    Rake::Task['db:migrate'].execute
  end

  task :clone_structure do
    Rake::Task['db:test:clone_structure'].invoke
  end

  desc 'migrates db down and up, does db:test:clone_structure, and runs rake spec'
  task :clean => [:migrate_down, :migrate_up, :clone_structure] do
  end

  desc 'does a clean sweep and loads xml'
  task :regenerate => [:migrate_down, :migrate_up, :load_new, :clone_structure] do
    puts 'Regenerated all data.'
  end

  desc 'splits files in /xml, loads anything not loaded'
  task :load_new => :environment do
    @splitter = Hansard::Splitter.new(false, (overwrite=true), true)
    per_source_file do |file|
      source_file = split_file file
      load_split_files source_file
    end
  end

  desc 'loads any unloaded commons data from /data (doesn\'t re-split)'
  task :load_new_commons => [:environment] do
    reload_data_files(COMMONS_PATTERN, Hansard::HouseCommonsParser)
  end

  desc 'loads any unloaded lords data from /data (doesn\'t re-split)'
  task :load_new_lords => [:environment] do
    reload_data_files(LORDS_PATTERN, Hansard::HouseLordsParser)
  end

  desc 'wipes and reloads commons data from /data (doesn\'t re-split)'
  task :reload_commons => [:environment] do
    HouseOfCommonsSitting.destroy_all
    DataFile.delete(:conditions => "name like 'housecommons%'")
    Rake::Task['hansard:load_new_commons'].invoke
  end

  desc 'wipes and reloads commons data from /data for given date=yyyy-mm-dd (doesn\'t re-split)'
  task :reload_commons_on_date => [:environment] do
    if ENV['date']
      date = Date.parse(ENV['date'])
      reload_commons_on_date date
    else
      puts ''
      puts 'usage: rake hansard:reload_commons_on_date date=yyyy-mm-dd'
      puts ''
    end
  end

  desc 'loads any unloaded written answer data from /data (doesn\'t re-split)'
  task :load_new_written => [:environment] do
    reload_data_files(WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
  end

  desc 'wipes and reloads written answer data from /data (doesn\'t re-split)'
  task :reload_written => [:environment] do
    WrittenAnswersSitting.destroy_all
    DataFile.delete(:conditions => "name like 'writtenanswers%'")
    Rake::Task['hansard:load_new_written'].invoke
  end

  desc 'loads any unloaded index data from /data (doesn\'t re-split)'
  task :load_new_index => [:environment] do
    reload_data_files(INDEX_PATTERN, Hansard::IndexParser)
  end

  desc 'wipes and reloads index data from /data (doesn\'t re-split)'
  task :reload_index => [:environment] do
    Index.destroy_all
    DataFile.delete(:conditions => "name like 'index%'")
    Rake::Task['hansard:load_new_index'].invoke
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data, overwrites /data'
  task :split_xml => :environment do
    splitter = Hansard::Splitter.new(false, (overwrite=true), true)
    splitter.split File.join(File.dirname(__FILE__),'..','..')
    puts 'Split ' + __FILE__
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data, doesnt overwrite /data'
  task :split_new_xml => :environment do
    splitter = Hansard::Splitter.new(false, (overwrite=false), true)
    splitter.split File.join(File.dirname(__FILE__),'..','..')
    puts 'Split ' + __FILE__
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data/** and indented in /data/**/indented'
  task :split_xml_indented => :environment do
    splitter = Hansard::Splitter.new(true, (overwrite=true), true)
    splitter.split File.join(File.dirname(__FILE__),'..','..')
    puts 'Split and indented ' + __FILE__
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
    Dir.glob(source_file.result_directory+"/"+pattern).each do |file|
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

desc "PICK ME! PICK ME! Does a clean sweep and loads xml"
task :hansard => "hansard:regenerate"
