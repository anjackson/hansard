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

  BASE_ONE_YEAR_REIGN_PATTERN = '(\d+) ([^ ]+) ([^ ]+)'
  BASE_TWO_YEAR_REIGN_PATTERN = '(\d+) ?(&amp;|and|AND|&#x0026;) ?(\d+) ([^ ]+) ([^ ]+)'
  AND_SEPARATOR_PATTERN = ' ?(&amp;|and|AND|&#x0026;) ?'

  ONE_YEAR_REIGN_PATTERN = /^#{BASE_ONE_YEAR_REIGN_PATTERN}/
  TWO_YEAR_REIGN_PATTERN = /^#{BASE_TWO_YEAR_REIGN_PATTERN}/
  ONE_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/
  ONE_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/

  def self.match_two_year_reign_and_monarch match, index_increment=0
    first_year = match[1 + index_increment]
    and_separator = match[2 + index_increment]
    second_year = match[3 + index_increment]
    name = match[4 + index_increment]
    monarch_suffix = match[5 + index_increment].chomp('.')

    year_of_the_reign = "#{first_year} #{and_separator} #{second_year}"
    monarch_name = "#{name} #{monarch_suffix}"
    return year_of_the_reign, monarch_name
  end

  def self.match_one_year_reign_and_monarch match, index_increment=0
    year = match[1 + index_increment]
    name = match[2 + index_increment]
    monarch_suffix = match[3 + index_increment].chomp('.')

    year_of_the_reign = "#{year}"
    monarch_name = "#{name} #{monarch_suffix}"
    return year_of_the_reign, monarch_name
  end

  def self.find_second_reign_and_monarch text, first_pattern, second_pattern, index_increment
    if (match = first_pattern.match(text))
      other_reign, other_monarch = match_one_year_reign_and_monarch match, index_increment
    elsif (match = second_pattern.match(text))
      other_reign, other_monarch = match_two_year_reign_and_monarch match, index_increment
    else
      other_reign, other_monarch = nil, nil
    end
    return other_reign, other_monarch
  end

  def self.find_reign_and_monarch text
    year_of_the_reign = monarch_name = other_year_of_the_reign = nil

    if (match = TWO_YEAR_REIGN_PATTERN.match(text))
      if ((monarch_suffix = match[5].chomp('.')) && monarch_suffix.is_roman_numerial?)
        year_of_the_reign, monarch_name = match_two_year_reign_and_monarch(match)
        other_year_of_the_reign, other_monarch_name = find_second_reign_and_monarch(text, TWO_YR_ONE_YR_TWO_MONARCHS, TWO_YR_TWO_YR_TWO_MONARCHS, 6)
      end
    elsif (match = ONE_YEAR_REIGN_PATTERN.match(text))
      if ((monarch_suffix = match[3].chomp('.')) && monarch_suffix.is_roman_numerial?)
        year_of_the_reign, monarch_name = match_one_year_reign_and_monarch(match)
        other_year_of_the_reign, other_monarch_name = find_second_reign_and_monarch(text, ONE_YR_ONE_YR_TWO_MONARCHS, ONE_YR_TWO_YR_TWO_MONARCHS, 4)
      end
    end

    if other_year_of_the_reign
      year_of_the_reign += ", #{other_year_of_the_reign}"
      monarch_name += ", #{other_monarch_name}"
    end
    return year_of_the_reign, monarch_name
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
          else
            session_of_parliament, parliament = Hansard::HeaderParser.find_session_and_parliament text
            if session_of_parliament
              session.session_of_parliament = session_of_parliament
              session.number_of_parliament = parliament
            end
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