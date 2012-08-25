require File.dirname(__FILE__) + '/hansard_transformer2'
require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'rexml/document'
require 'fileutils'

module Hansard
end

class Hansard::Transformer

  attr_reader :volume, :house, :part, :date

  def initialize source, result_base_path
    @house_commons_hit = false
    @source, @result_base_path = source, result_base_path
    @node_names = []
    @part = '0'
    @date = nil
  end

  def transform write_to_file=true
    doc = Hpricot::XML open_source
    traverse_element doc.children_of_type('HansardDoc').first
    transformed = doc.to_s

    temp_file = 'temporary.xml'
    File.open(temp_file, 'w') { |f| f.write transformed }
    listener = Hansard::Transformer2.new
    REXML::Document.parse_stream(transformed, listener)
    File.delete(temp_file)

    write_result listener.document if write_to_file
    listener.document.to_s
  end

  def open_source
    open(@source)
  end

  def write_result document
    temp_file = 'temporary.xml'
    File::open(temp_file, 'w') {|file| document.write(file)}
    file = File.new(temp_file)
    puts 'Path: ' + result_path
    FileUtils.mkdir_p result_path
    File::open(result_file, 'w') do |result|
      file.each {|line| result.write(line) unless line.blank?}
    end
    file.close
    # File.delete(temp_file)
  end

  def series_volume_identifier(options={:series=>'6'})
    house_id = house[0..0].upcase
    series = options[:series]
    vol = volume
    while vol.size < 4
      vol = '0'+vol
    end
    "S#{house_id}#{series}V#{vol}P#{part}"
  end

  def house_date_identifier
    "house#{house}_#{date.gsub('-','_')}"
  end

  def result_file
    File.join result_path, house_date_identifier+'.xml'
  end

  def result_path
    File.join @result_base_path, house_date_identifier, series_volume_identifier
  end

  private

  def clean text
    text.gsub("\n",' ').gsub("\r",' ').squeeze(' ')
  end

  def traverse_division_element element
    element.children.each do |node|
      if node.elem?
        handle_element_in_division node
      elsif node.procins?
        handle_processing_instruction node
      end
    end
  end

  def traverse_element element
    element.children.each do |node|
      if node.elem?
        handle_element node
      elsif node.procins?
        handle_processing_instruction node
      end
    end
  end

  def handle_processing_instruction node
    if (match = /column=(\d+)/.match node.content)
      column = match[1]
      node = node.swap('<col>').first
      node.inner_html = column
    elsif !@date && (match = /(\d\d\d\d-\d\d-\d\d)/.match node.content)
      @date = match[1]
    end
  end

  def handle_division_number node
    text = clean(node.inner_text)
    div_no = /Division\sNo\.?\s(\d+)/.match(text)[1]
    time = /\[(.*)/.match(text)[1]
    replace node, 'tr'
    node.innerHTML = "<td><b>Division No. #{div_no}]</b></td><td align='right'><b>[#{time.strip}</b></td>"
  end

  def handle_division_header node
    replace node, 'tr'
    text = node.inner_text
    node.innerHTML = "<td colspan='2' align='center'><b>#{text}</b></td>"
  end

  def handle_ayes_or_noes node
    names = (node/'hs_Para/Member').collect { |m| clean(m.inner_text) }
    rows = []
    names.in_groups_of(2) do |pair|
      rows << "<tr><td>#{pair[0]}</td>"
      rows << "<td>#{pair[1]}</td>" unless pair[1].blank?
      rows << "</tr>"
    end
    node.innerHTML = rows.join("\n")
  end

  def handle_teller_names node
    ayes_noes = (node.name == 'TellerNamesAyes') ? 'Ayes' : 'Noes'
    label = "Tellers for the #{ayes_noes}:"
    names = (node/'Member').collect { |m| clean(m.inner_text) }
    rows = ["<tr><td></td><td>#{label}</td></tr>"]
    rows << "<tr><td></td><td>"
    rows << names.join(" and ")
    rows << "</td></tr>"
    node.innerHTML = rows.join("\n")
  end

  def handle_element_in_division node
    case node.name
      when 'hs_Para'
        line_break_free = clean(node.inner_text)
        if line_break_free.include?('Division No')
          handle_division_number node
        elsif line_break_free.include?('Tellers')
          replace node, 'ignore'
        elsif line_break_free.blank?
          replace node, 'ignore'
        else
          handle_element node
        end
      when 'hs_DivListHeader'
        handle_division_header node
      when 'TwoColumn'
        node.children.each do |child|
          handle_element_in_division child
        end
      when /TellerNames(Ayes|Noes)/
        handle_teller_names node
      when /Names(Ayes|Noes)/
        handle_ayes_or_noes node
      else
        handle_element node
    end
  end

  TITLE_TAG =  /hs_3OralAnswers|DepartmentName|hs_8Question|hs_2cStatement|hs_3cOrdersoftheDay|hs_2BillTitle|hs_8Clause|hs_6bBigBoldHdg|hs_2cBillTitle|hs_6bFormalmotion|hs_2cDebatedMotion|hs_2DebBill|hs_6bcBigBoldHdg/ unless defined?(TITLE_TAG)
  PARAGRAPH_TAG = /hs_Para|hs_7SmCapsHdg|hs_Timeline|hs_76fChair|hs_AmendmentLevel0|hs_AmendmentLevel1|hs_AmendmentLevel2|hs_AmendmentLevel3|hs_AmendmentLevel4|hs_2cDebHdgTC|hs_7Bill/ unless defined?(PARAGRAPH_TAG)
  NON_DEBATE_TRIGGER_TAG = /hs_MainHeading|Cover-wrapper|Index|Contents/ unless defined?(NON_DEBATE_TRIGGER_TAG)

  def handle_element node
    strip_attributes(node) unless ['Cover','House'].include?(node.name)

    is_division = false
    case node.name
      when PARAGRAPH_TAG
        replace node, 'p'
      when 'hs_3MainHdg'
        remove_non_commons_debates node
      when TITLE_TAG
        rename node, 'title'
      when 'Member'
        handle_member node
      when 'hs_brev'
        replace node, 'quote'
      when 'I'
        replace node, 'i'
      when 'B'
        replace node, 'b'
      when 'hs_6fDate'
        handle_date node
      when 'SmallCaps'
        make_span node
      when 'Division'
        is_division = true
        replace node, 'division'
        traverse_division_element node
      when NON_DEBATE_TRIGGER_TAG
        remove_system_parent node
      when 'House'
        house_name = node.attributes['name']
        if house_name
          if house_name == 'Commons'
            replace node, 'housecommons'
            @house = 'commons'
          else
            raise 'unable to handle non-commons xml: ' + node.to_s
          end
        end
      when 'AyesNumber'
        make_span node
      when 'NoesNumber'
        make_span node
      when 'Cover'
        @volume = node.attributes['volume']
        @part = node.attributes['part'] if node.attributes['part']
    end
    @node_names << node.name
    traverse_element node unless is_division
  end

  def remove_non_commons_debates node
    if @house_commons_hit
      remove_system_parent node
    else
      @house_commons_hit = true
      rename node, 'title'
    end
  end

  def handle_date node
    is_date = clean(node.inner_text).strip.match(/\d\d?\s+\D+\s+\d\d\d\d/)
    if is_date
      rename node, 'date'
      node.raw_attributes = { :format => Date.parse(node.inner_text) }
    else
      rename node, 'p'
    end
  end

  def handle_member node
    replace node, 'member'
    if node.parent.name == 'p'
      node.parent.raw_attributes = node.parent.raw_attributes.merge({:class => 'membercontribution'})
    end
    member_name = node.children.last
    if member_name.text? && member_name.content.ends_with?(':')
      member_name.content = member_name.content.chomp(':').chomp(' ')
      member_contribution = node.next_node
      if member_contribution.nil? && node.parent.name == 'b'
        member_contribution = node.parent.next_node
      end
      if member_contribution && member_contribution.text?
        member_contribution.content = ':' + member_contribution.content
      end
    end
  end

  def make_span node
    old_name = node.name
    node.stag.name = 'span'
    node.etag.name = 'span'
    node.raw_attributes = {:class => old_name}
  end

  def rename node, name
    old_name = node.name
    replace node, name
    node.raw_attributes = {:class => old_name}
  end

  def replace node, name
    node.stag.name = name
    node.etag.name = name
  end

  def strip_attributes node
    uid = node.raw_attributes['UID']
    if uid
      node.raw_attributes = {'uid' => uid}
    else
      node.raw_attributes = {}
    end
  end

  def remove_system_parent node
    parent = node.parent
    while parent.name != 'System'
      parent = parent.parent
    end
    parent.search('Fragment').remove
  end

end