require 'rubygems'
require 'open-uri'
require 'hpricot'

module Hansard
end

class Hansard::HeaderParser

  include Hansard::ParserHelper

  def initialize file, logger=nil
    @logger = logger
    @doc = Hpricot.XML open(file)
  end

  def log text
    @logger.add_log text if @logger
  end

  def parse
    session = nil
    @doc.children.each do |node|
      if node.elem? && node.name == 'hansard'
        session = create_session node
      end
    end
    if session
      session
    else
      raise 'cannot create session, hansard element not found in source XML'
    end
  end

  private
    def create_session hansard
      session = Session.new

      hansard.children.each do |node|
        if node.elem? and node.name == 'titlepage'
          session.titlepage_text = clean_html(node).strip
        end
      end

      session
    end

end