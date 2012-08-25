$:.unshift File.dirname(__FILE__)

# BingoDisk is a Ruby library for managing files on Joyent's BingoDisk (http://bingodisk.com).
module BingoDisk
  # Set login credentials global for the library
  def self.set_credentials(username, password) 
    @username, @password = username, password
  end
  
  def self.username
    @username
  end
  
  def self.password
    @password
  end
  
  # Contructs a BingoDisk compatible username
  def self.make_username(username)
    username + '@bingodisk.com'
  end
  
  # Contructs a BingoDisk URL
  def self.make_host(username)
    "http://#{username}.bingodisk.com/bingo"
  end
  
  # A connection to BingoDisk
  class Connection
    attr_reader :last_response
    
    # Starts the connection to BingoDisk, requires a block
    def initialize(username = BingoDisk.username, password = BingoDisk.password)
      unless block_given?
        raise ArgumentError.new("No block given")
      end
      
      @username, @password = BingoDisk.make_username(username), password
      
      @uri = URI.parse(BingoDisk.make_host(username))
      Net::HTTP.start(@uri.host) do |http|
        @http = http
        @res = http.head(@uri.request_uri)
        yield self
      end
    end
    
    # Uploads a open IO object to BingoDisk. The optional directory argument
    # places the files in a certain directory
    def upload(filename, file, directory = '/')
      create_directory(directory)
      req = Net::HTTP::Put.new("/bingo#{directory}/#{filename}")
      req.digest_auth(@username, @password, @res)
      @last_response = @http.request(req, file.read)
    end
    
    # Creates a directory on BingoDisk. Will create parent directories.
    def create_directory(directory)
      directory_array = directory.split('/')
      directory_array.shift
      directory_array.each_index do |i|
        req = Net::HTTP::Mkcol.new('/bingo/' + directory_array[0..i].join('/'))
        req.digest_auth(@username, @password, @res)
        @last_response = @http.request(req)
      end
    end
    
    # Deletes a files from BingoDisk. Will delete it from the optional directory if
    # directory is given.
    def delete(filename, directory = '/')
      req = Net::HTTP::Delete.new("/bingo#{directory}/#{filename}")
      req.digest_auth(@username, @password, @res)
      @last_response = @http.request(req)
    end
    
    # Checks if a file exsists on BingoDisk. Will check in the optional directory if
    # directory is given.
    def file_exsists?(filename, directory = '/')
      req = Net::HTTP::Head.new("/bingo#{directory}/#{filename}")
      req.digest_auth(@username, @password, @res)
      @last_response = @http.request(req)
      return @last_response.code.eql?("200")
    end
    
    # Downloads a file from BringoDisk. Will download from the optional directory if
    # directory is given.
    #
    #   BingoDisk::Connection.new do |bingo|
    #     open("test.jpg", "wb") do |file|
    #       file.write(bingo.download)
    #     end
    #   end
    #   
    def download(filename, directory = '/')
      req = Net::HTTP::Get.new("/bingo#{directory}/#{filename}")
      req.digest_auth(@username, @password, @res)
      @last_response = @http.request(req)
      @last_response.body
    end
  end
end

require 'digest/md5'
require 'net/http'

# Allows the Net:HTTP library to use diget authentication.
# This code was taken from (http://theexciter.com/articles/bingo)
module Net
  module HTTPHeader
    @@nonce_count = -1
    CNONCE = Digest::MD5.new.update("%x" % (Time.now.to_i + rand(65535))).hexdigest
    def digest_auth(user, password, response)
      # based on http://segment7.net/projects/ruby/snippets/digest_auth.rb
      @@nonce_count += 1

      response['www-authenticate'] =~ /^(\w+) (.*)/

      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

      a_1 = "#{user}:#{params['realm']}:#{password}"
      a_2 = "#{@method}:#{@path}"
      request_digest = ''
      request_digest << Digest::MD5.new.update(a_1).hexdigest
      request_digest << ':' << params['nonce']
      request_digest << ':' << ('%08x' % @@nonce_count)
      request_digest << ':' << CNONCE
      request_digest << ':' << params['qop']
      request_digest << ':' << Digest::MD5.new.update(a_2).hexdigest

      header = []
      header << "Digest username=\"#{user}\""
      header << "realm=\"#{params['realm']}\""
      
      header << "qop=#{params['qop']}"

      header << "algorithm=MD5"
      header << "uri=\"#{@path}\""
      header << "nonce=\"#{params['nonce']}\""
      header << "nc=#{'%08x' % @@nonce_count}"
      header << "cnonce=\"#{CNONCE}\""
      header << "response=\"#{Digest::MD5.new.update(request_digest).hexdigest}\""

      @header['Authorization'] = header
    end
  end
end
