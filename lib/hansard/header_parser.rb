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

  def self.find_series_and_volume_and_part text
    if (match = /^([^ ]+) SERIES&#x2014;VOLUME ([^ ]+)$/.match text)
      series_number = match[1]
      volume_in_series = match[2]
      volume_part_number = nil
    elsif (match = /^([^ ]+) SERIES&#x2014;VOLUME ([^ ]+) \(Part ([^ ]+)\)$/.match text)
      series_number = match[1]
      volume_in_series = match[2]
      volume_part_number = match[3]
    else
      series_number = volume_in_series = volume_part_number = nil
    end

    return [series_number, volume_in_series, volume_part_number]
  end

  private

    def handle_titlepage titlepage, session
      session.titlepage_text = clean_html(titlepage).strip

      titlepage.children.each do |node|
        if is_element? 'p', node
          text = clean_html(node).strip
          series, volume = Hansard::HeaderParser.find_series_and_volume_and_part text
          if series
            session.series_number = series
            session.volume_in_series = volume
          end
        end
      end
    end

    def create_session hansard
      session = Session.new

      hansard.children.each do |node|
        if is_element? 'titlepage', node
          handle_titlepage node, session
        end
      end

      session
    end

end