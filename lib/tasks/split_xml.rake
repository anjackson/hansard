require File.join(File.dirname(__FILE__),'..','hansard_splitter.rb')

namespace :hansard do

  desc 'splits Hansard XML files in /xml in to XML sections in /data'
  task :split_xml => :environment do
    splitter = Hansard::Splitter.new(false, true)
    splitter.split File.join(File.dirname(__FILE__),'..','..'), false
    puts 'Split ' + __FILE__
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data/** and indented in /data/**/indented'
  task :split_xml_indented => :environment do
    splitter = Hansard::Splitter.new(true, true)
    splitter.split File.join(File.dirname(__FILE__),'..','..'), true
    puts 'Split and indented ' + __FILE__
  end

end
