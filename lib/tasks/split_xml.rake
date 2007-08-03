require File.join(File.dirname(__FILE__),'..','deconstruct.rb')

namespace :hansard do
  desc 'splits Hansard XML files in /xml in to XML sections in /data'
  task :split_xml do
    Hansard::Splitter.new.split File.join(File.dirname(__FILE__),'..','..')
  end
end
