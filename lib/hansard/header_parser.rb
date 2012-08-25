require 'rubygems'
require 'open-uri'
require 'hpricot'

module Hansard
end

class Hansard::HeaderParser

  include Hansard::ParserHelper
  include ActionView::Helpers::SanitizeHelper

  def initialize file, data_file, source_file, parse_divisions=false
    @data_file = data_file
    @source_file = source_file
    @xml_file = file
  end

  def parse
    file_text = open(@xml_file).read
    doc = Hpricot.XML file_text
    parse_doc(doc)
  end

  def parse_doc doc
    hansard_element = doc.at('hansard')
    raise 'cannot create volume, hansard element not found in source XML' unless hansard_element
    create_volume(hansard_element)
  end

  AND_SEPARATOR_PATTERN = ' ?(&amp;|and|AND|&#x0026;|ET) ?'
  BASE_MAJESTY_PATTERN = '.*(?:in the |\A|, |IRELAND)(.+ ){1,2}YEAR OF THE REIGN OF(?: (?:HIS|HER),? MAJESTY)? ([^ ]+) ([^ ][^ ][^ ]+) ?(?:THE )?([^ ]+)?'
  BASE_ONE_YEAR_REIGN_PATTERN = '(\d+(?:&#x00B0;)?) ([^ ][^ ][^ ]+) ([IV]+)?'
  BASE_TWO_YEAR_REIGN_PATTERN = /(\d+)#{AND_SEPARATOR_PATTERN}(\d+) ([^ ][^ ][^ ]+) ?([IV]+)?/


  MAJESTY_PATTERN = /^#{BASE_MAJESTY_PATTERN}/i
  PARLIAMENT_AND_MAJESTY_PATTERN = /NORTHERN IRELAND #{BASE_MAJESTY_PATTERN}$/
  PARLIAMENT_AND_ONE_YEAR_REIGN_PATTERN = /NORTHERN IRELAND #{BASE_ONE_YEAR_REIGN_PATTERN}/
  PARLIAMENT_AND_TWO_YEAR_REIGN_PATTERN = /NORTHERN IRELAND #{BASE_TWO_YEAR_REIGN_PATTERN}/


  ONE_YEAR_REIGN_PATTERN = /^#{BASE_ONE_YEAR_REIGN_PATTERN}/
  TWO_YEAR_REIGN_PATTERN = /^#{BASE_TWO_YEAR_REIGN_PATTERN}/
  ONE_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/

  ONE_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/

  AND_PATTERN = /\A(.*\d\d\d\d.)and the/i

  def clean_period_line line
    if (and_match = AND_PATTERN.match line)
      line = and_match[1].strip
    end
    line = line.gsub("\n", ' ')
    line
  end

  def match_majesty_reign_and_name match
    year = match[1].strip.sub(' ','-')
    name = match[3]
    if match[4]
      monarch_suffix = match[4].gsub(/\.|,/, '')
      if !monarch_suffix.is_roman_numeral?
        monarch_ordinal = monarch_suffix.ordinal_to_number
        monarch_suffix = monarch_ordinal.to_roman if monarch_ordinal
      end
    end
    regnal_years = "#{year}"
    if monarch_suffix
      monarch_name = "#{name} #{monarch_suffix}"
    else
      monarch_name = name
    end
    return regnal_years, monarch_name
  end

  def match_two_year_reign_and_monarch match, index_increment=0
    first_year = match[1 + index_increment]
    and_separator = match[2 + index_increment]
    second_year = match[3 + index_increment]
    name = match[4 + index_increment].gsub('.', '')
    monarch_suffix = match[5 + index_increment]
    regnal_years = "#{first_year} #{and_separator} #{second_year}"
    monarch_name = "#{name}"
    monarch_name += " #{monarch_suffix.chomp('.')}" if monarch_suffix
    return regnal_years, monarch_name
  end

  def match_one_year_reign_and_monarch match, index_increment=0
    year = match[1 + index_increment]
    name = match[2 + index_increment]
    monarch_suffix = match[3 + index_increment]
    regnal_years = "#{year}"
    monarch_name = "#{name}"
    monarch_name += " #{monarch_suffix.chomp('.')}" if monarch_suffix
    return regnal_years, monarch_name
  end

  def find_second_reign_and_monarch text, first_pattern, second_pattern, index_increment
    if (match = first_pattern.match(text))
      other_reign, other_monarch = match_one_year_reign_and_monarch match, index_increment
    elsif (match = second_pattern.match(text))
      other_reign, other_monarch = match_two_year_reign_and_monarch match, index_increment
    else
      other_reign, other_monarch = nil, nil
    end
    return other_reign, other_monarch
  end

  def find_reign_and_monarch text
    regnal_years = monarch_name = other_regnal_years = nil
    text = strip_tags(text)
    if (match = TWO_YEAR_REIGN_PATTERN.match(text))
      regnal_years, monarch_name = match_two_year_reign_and_monarch(match)
      other_regnal_years, other_monarch_name = find_second_reign_and_monarch(text, TWO_YR_ONE_YR_TWO_MONARCHS, TWO_YR_TWO_YR_TWO_MONARCHS, 6)
    elsif (match = ONE_YEAR_REIGN_PATTERN.match(text))
      regnal_years, monarch_name = match_one_year_reign_and_monarch(match)
      other_regnal_years, other_monarch_name = find_second_reign_and_monarch(text, ONE_YR_ONE_YR_TWO_MONARCHS, ONE_YR_TWO_YR_TWO_MONARCHS, 4)
    elsif ((match = PARLIAMENT_AND_MAJESTY_PATTERN.match(text)) || (match = MAJESTY_PATTERN.match(text)))
      regnal_years, monarch_name = match_majesty_reign_and_name(match)
    elsif (match = PARLIAMENT_AND_TWO_YEAR_REIGN_PATTERN.match(text))
      regnal_years, monarch_name = match_two_year_reign_and_monarch(match)
    elsif (match = PARLIAMENT_AND_ONE_YEAR_REIGN_PATTERN.match(text))
      regnal_years, monarch_name = match_one_year_reign_and_monarch(match)
    end

    monarch_name = monarch_name.gsub(',','') if monarch_name

    if other_regnal_years && !other_monarch_name.blank?
      regnal_years += ", #{other_regnal_years}"
      monarch_name += ", #{other_monarch_name}"
    end
    return regnal_years, monarch_name
  end

  VOLUME_PATTERN = /VOL(?:\.|UME)(?!OF) ([^ ]+)/

  def find_volume text
   if (match = VOLUME_PATTERN.match text)
     return match[1].chomp('.')
   end
  end

  SESSION_PARLIAMENT_PATTERN = /^([^ ]+) SESSION OF THE ([^ ]+) PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN/

  def find_session_and_parliament text
    if (match = SESSION_PARLIAMENT_PATTERN.match(text) )
      session_of_parliament = match[1]
      number_of_parliament = match[2]
    end
    return session_of_parliament, number_of_parliament
  end

  COMPRISING_PERIOD = /(?:COM)?PA?RISING;?(?: T(?:H|II)E)? (?:PE[R|E]IODS?)?(?: [FP]ROM)?\.?/i
  BASE_COMPRISING_PERIOD = '(.*[^x]\d\d\d\d)(\.|\))?(,|\.|\))?'
  COMPRISING_PERIOD_ONE_LINE_PATTERN =      /#{COMPRISING_PERIOD}\s?#{BASE_COMPRISING_PERIOD}/
  COMPRISING_PERIOD_ONE_LINE_NO_YEAR_PATTERN = /#{COMPRISING_PERIOD}\s(.+?)(\.(.*?))?$/

  def find_comprising_period first_line, second_line
    line = "#{clean_period_line(first_line)} #{clean_period_line(second_line)}"
    get_one_line_period(line)
  end

  def get_one_line_period(line)
    line = clean_period_line(line)
    if (match = COMPRISING_PERIOD_ONE_LINE_PATTERN.match(line))
      period = match[1]
      if match = /^(.*?\d\d\d\d)\.(?!\s*TO)/.match(period)
        period = match[1]
      end
      if match = /^(.*?)\s*London/i.match(period)
        period = match[1]
      end
      if match = /^(.*?),?\.?;?\s*(and|also) the general/i.match(period)
        period = match[1]
      end
    elsif (match = COMPRISING_PERIOD_ONE_LINE_NO_YEAR_PATTERN.match(line))
      period = match[1]
    else
      @data_file.add_log 'no comprising period identified from line: ' + line
      period = nil
    end
    period
  end

  def extract_members doc
    members = []
    titles = doc.search("title")
    member_list_headers = titles.select { |ele| ele.inner_text =~ /Alph?abetical List of Members/i }
    return members if member_list_headers.empty?
    member_list_header = member_list_headers.first
    member_list_section = member_list_header.search('../section')
    member_list_elements = member_list_section.search('p')
    if member_list_section.empty?
     member_list_section = member_list_header.search('..')
     member_list_elements = member_list_section.search('p')
     current_section = member_list_section.first.next_sibling
     while current_section and current_section.name == 'section'
       member_list_elements += current_section.search('p')
       current_section = current_section.next_sibling
     end
    end
    member_list_elements.each do |member_list_element|
      members += member_and_constituency(member_list_element.inner_html)
    end
    members
  end


  def member_and_constituency member_text
    member_text = member_text.gsub("\r\n", ' ')
    match_list = []
    begin
      match = get_member_match(member_text)
      unless match.empty?
        match_list << match
      end
    end while !match.empty? and !member_text.empty?
    match_list
  end

  def get_member_match(string)
    member_with_comma_pattern = /((?:\w|-|;|\d|&|\#)+?)  # lastname
                                 [,|\.]?\s              # punctuation
                                 ([^\(]*)               # firstnames
                                 \(?\(([^\(\)]*)\)?       # constituency in brackets
                                 (?:\s\[?<i>
                                   \[?([^\(]*)\s(.*?\s\d\d\d\d)\]? # optionally italicised reason for transition
                                   <\/i>\]?)?
                                 /x
    match = member_with_comma_pattern.match(string)
    return {} unless match
    member_info = { :lastname     => match[1].strip,
                    :firstnames   => match[2].strip,
                    :constituency => match[3].strip }
    if !match[4].blank?
      member_info[:transition_reason] = match[4].gsub(',', '').strip
      member_info[:transition_date] = match[5].strip
    end
    string.slice!(0, match.end)
    return member_info
  end

  def reparse_volume_attributes(volume)
    doc = Hpricot.XML open(@xml_file)
    hansard_element = doc.at('hansard')
    titlepage = hansard_element.at('titlepage')
    handle_titlepage(titlepage, volume)
  end
  
  private

    def handle_titlepage titlepage, volume
      lines = clean_paras(titlepage)
      lines.each_with_index do |text, index|
        if COMPRISING_PERIOD.match(text)
          next_text = comprising_period_text(lines, index)
          volume.period = find_comprising_period text, next_text
          next
        end
        find_volume_attributes(text, volume)
      end
    end

    def handle_hansard hansard_element, volume
      lines = clean_paras(hansard_element)
      lines.each{ |text| find_volume_attributes(text, volume) }
    end

    def find_volume_attributes(text, volume)
      unless volume.number_string
        volume.number_string = find_volume(text)
      end
      unless volume.session_of_parliament
        volume.session_of_parliament, volume.parliament = find_session_and_parliament(text)
      end
      unless volume.regnal_years
        volume.regnal_years, volume.monarch = find_reign_and_monarch(text)
      end
    end

    def comprising_period_text(lines, index)
      text = lines[index+1]
      if text.strip == 'FROM'
        index += 1
        text = lines[index+1]
      end
      year_patt = /(?:^|\s)\d\d\d\d/
      
      if /^TO$/i.match lines[index+2] 
        text += " #{lines[index+2]} "
        text += lines[index+3]
        if !year_patt.match(lines[index+3])
          text += " #{lines[index+4]}"
        end
      elsif period_incomplete?(text)
        text += " #{lines[index+2]}"
      elsif !year_patt.match text and year_patt.match(lines[index+2])
        text += " #{lines[index+2]}"
      end
      text
    end

    def period_incomplete?(text)
      return true if /(\s|^)TO$/.match(text) 
      return true if /(\s|^)OF$/.match(text) 
      return true if /,$/.match(text)
      return false
    end

    def clean_paras node
      lines = []
      node.children_of_type('p').each do |node|
        line = clean_html(node).gsub('<lb></lb>', ' ').squeeze(' ').strip
        lines << line
      end
      lines
    end

    def create_volume(hansard_element)
      series = Series.find_by_source_file(@source_file)
      volume = Volume.new(:series => series,
                          :number => @source_file.volume_number,
                          :part => @source_file.part_number,
                          :source_file => @source_file)
      titlepage_element = hansard_element.at('titlepage')
      handle_titlepage titlepage_element, volume
      handle_hansard hansard_element, volume if volume.regnal_years.blank?
      volume
    end

end