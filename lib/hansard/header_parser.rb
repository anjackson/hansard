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

  SESSION_PARLIAMENT_PATTERN = /^([^ ]+) SESSION OF THE ([^ ]+) PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN/

  def self.find_session_and_parliament text
    if (match = SESSION_PARLIAMENT_PATTERN.match(text) || (match = SESSION_PARLIAMENT_PATTERN.match(text.sub('<lb/>',''))))
      session_of_parliament = match[1]
      number_of_parliament = match[2]
    end
    return session_of_parliament, number_of_parliament
  end

  BASE_SERIES_VOLUME_PATTERN = "([^ ]+) SERIES ?(&#x2014;|—|-|&#2014;) ?VOLUME ([^ ]+)"
  SERIES_VOLUME_PATTERN      = /^#{BASE_SERIES_VOLUME_PATTERN}$/
  SERIES_VOLUME_PART_PATTERN = /^#{BASE_SERIES_VOLUME_PATTERN} \(Part ([^ ]+)\)$/

  def self.find_series_and_volume_and_part text
    if (match = SERIES_VOLUME_PATTERN.match text)
      series_number = match[1]
      volume_in_series = match[3].chomp('.')
      volume_part_number = nil
    elsif (match = SERIES_VOLUME_PART_PATTERN.match text)
      series_number = match[1]
      volume_in_series = match[3].chomp('.')
      volume_part_number = match[4]
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