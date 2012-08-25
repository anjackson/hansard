= BingoDisk

BingoDisk is a Ruby library for managing files on Joyent's BingoDisk (http://bingodisk.com).

== Usage

To get started, require 'bingo_disk', then make a connection:

  require 'bingo_disk'
  BingoDisk::Connection.new('bingo_subdomain', 'password') do
    ...
  end

To save time and keystrokes, you can set the credentials global across the library:

  require 'bingo_disk'
  BingoDisk.set_credentials('bingo_subdomain', 'password')
  BingoDisk::Connection.new do
    ...
  end
  
Once you've made a connection you can upload files:

  BingoDisk::Connection.new do |bingo|
    bingo.upload('filename.jpg', open(file))
  end
  
