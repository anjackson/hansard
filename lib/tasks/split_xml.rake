require File.join(File.dirname(__FILE__),'..','deconstruct.rb')

namespace :hansard do
  desc 'splits Hansard XML files in /xml in to XML sections in /data'
  task :split_xml do
    Hansard::Splitter.new.split File.join(File.dirname(__FILE__),'..','..'), false
    puts 'Split ' + __FILE__
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data/** and indented in /data/**/indented'
  task :split_xml_indented do
    Hansard::Splitter.new.split File.join(File.dirname(__FILE__),'..','..'), true
    puts 'Split and indented ' + __FILE__
  end

end
