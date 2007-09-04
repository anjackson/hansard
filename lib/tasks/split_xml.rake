namespace :hansard do

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

end
