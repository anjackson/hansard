require 'enumerator'

class Division < ActiveRecord::Base

  belongs_to :division_placeholder, :class_name => 'DivisionPlaceholder', :foreign_key => 'division_placeholder_id'
  has_many :votes, :dependent => :destroy
  after_create :cache_attributes
  belongs_to :bill
  acts_as_hansard_element
  acts_as_sortable_division
  alias :to_activerecord_xml :to_xml


  AGREED_TO = regexp('(Bill|Main\sQuestion|Original\sQuestion|Question|Resolution).*agreed to\.?$', 'i') unless defined? AGREED_TO
  COMMITTED = regexp('^Bill committed to a Standing Committee', 'i') unless defined? COMMITTED
  READ = regexp('^(Bill|\S+\sResolution) read (a|the) .+ time.*', 'i') unless defined? READ
  AMENDMENT = regexp('^Lords amendment.*agreed to\.?$', 'i') unless defined? AMENDMENT
  NEGATIVED = regexp('^Question accordingly negatived\.?$', 'i') unless defined? NEGATIVED
  RESOLUTION = regexp('^On Question, Resolution agreed to\.?$', 'i') unless defined? RESOLUTION
  DISAGREED = regexp('^Resolved in the negative, and (Motion|Amendment) disagreed to accordingly\.?$', 'i') unless defined? DISAGREED

  def anchor_id
    division_placeholder.anchor_id
  end

  def self.is_a_division_result? text
    [AGREED_TO, COMMITTED, READ, AMENDMENT, NEGATIVED, RESOLUTION, DISAGREED].each do |pattern|
      return true if pattern.match text
    end
    false
  end

  def self.divisions_in_groups_by_section_title_and_section_and_sub_section start_letter=nil
    groups = divisions_in_groups_by_section_and_sub_section(start_letter)
    groups.in_groups_by {|g| g[0][0].section_title}
  end

  def self.all_including_unparsed start_letter=nil
    options = {:include => [{:division_placeholder => {:section => [:sitting, :parent_section]}}, :bill]}
    if start_letter
      options = options.merge(:conditions => ['index_letter = ?', start_letter])
    end
    divisions = Division.find(:all, options)
    unparsed_divisions = UnparsedDivisionPlaceholder.find(:all, :include => {:section => [:sitting, :parent_section]})
    unparsed_divisions = unparsed_divisions.select{ |division| division.index_letter == start_letter} if start_letter
    divisions = divisions + unparsed_divisions unless unparsed_divisions.empty?
    divisions
  end

  def self.letters
    Division.find_by_sql "SELECT distinct index_letter FROM divisions where index_letter is not null"
  end

  def self.divisions_in_groups_by_section_and_sub_section start_letter=nil
    divisions = all_including_unparsed start_letter
    groups_by_section = divisions.sort_by{|d| d.section.object_id}.in_groups_by(&:section).sort_by do |group|
      division = group[0]
      "#{division.alphanumeric_section_title}#{division.date}"
    end
    groups_by_section.inject([]) do |groups_by_section_and_sub_section, divisions|
      groups_by_section_and_sub_section << sort_by_division_number(divisions.sort_by{|d| d.sub_section.object_id}.in_groups_by(&:sub_section))
    end
  end

  def self.sort_by_division_number groups
    groups.each { |divisions| divisions.sort! { |d1, d2| d1.compare_by_division_number d2 } }
    groups.sort! { |group, other_group| group[0].compare_by_division_number other_group[0] }
    groups
  end

  def self.number_from name
    name.sub(/No.([0-9])/, 'No. \1').chomp('.1]').sub(/(d+)\.1/,'\1')[/\d+/]
  end


  def compare_by_division_number division
    if division.is_a? UnparsedDivisionPlaceholder
      division.object_id <=> division_placeholder.object_id
    elsif number
      division.number ? number <=> division.number : +1
    else
      division.number ? -1 : 0
    end
  end

  def section
    division_placeholder.section_for_division
  end

  def sub_section
    @sub_section ||= division_placeholder.sub_section
  end

  def sub_section_title
    @sub_section_title ||= division_placeholder.sub_section_title
  end

  def date
    @date ||= division_placeholder.date
  end
  
  def calculate_number
    number = name? ? Division.number_from(name) : (index_in_section + 1)
    number ? number.to_i : nil
  end

  def calculate_index_in_section
   division_placeholder.section.index_of_division self
  end
  
  def calculate_section_title
    division_placeholder.section_title
  end
  
  def cache_attributes
    self.section_title = calculate_section_title
    self.index_in_section = calculate_index_in_section
    self.number = calculate_number
    self.index_letter = calculate_index_letter
    save!
  end

  def divided_text
    division_placeholder.divided_text
  end

  def result_text
    division_placeholder.result_text
  end

  def division_id
    "division_#{number}"
  end

  def to_csv url=nil
    text = []
    text << (url ? url.sub(':80','') : '')
    text << %Q|"#{section_title}"|
    text << "House of #{house}"
    text << date.to_s
    text << (name.blank? ? 'Division' : name)
    text << time_text ? time_text : ''
    text << (divided_text ? %Q|"#{divided_text}"| : '')
    text << (result_text ? %Q|"#{result_text}"| : '')
    text.join("\n")
  end

  def sitting
    section.sitting
  end

  def house
    sitting.house
  end

  def votes_header_xml(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.tr do
      xml.td(:align => "center", :colspan => "2") do
        xml.b(options[:vote_type])
      end
    end
  end

  def vote_pair_xml(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    first_vote = options[:first_vote]
    second_vote = options[:second_vote]
    if first_vote and first_vote.start_column != options[:current_column]
      xml << "</table>"
      first_vote.marker_xml(options)
      xml << "<table>"
    end
    xml.tr do
      xml.td do
        first_vote.to_xml(options) if first_vote
      end
      xml.td do
        second_vote.to_xml(options) if second_vote
      end
    end
  end

  def votes_xml(options)
    votes = options[:votes]
    teller_votes = options[:teller_votes]
    xml = options[:builder]

    votes_header_xml(options)

    if teller_votes.empty?
      simple_votes = votes
    else
      teller_rows = teller_votes.size + 2
      simple_vote_limit = votes.size - teller_rows
      simple_votes = votes[0...simple_vote_limit]
    end

    simple_votes.each_slice(2) do |slice|
      options[:first_vote] = slice.shift
      options[:second_vote] = slice.shift
      vote_pair_xml(options)
    end

    if !teller_votes.empty?
      leftover_votes = votes[simple_vote_limit..votes.size] || []

      xml.tr do
        xml.td do
          leftover_votes.shift.to_xml(options) if !leftover_votes.empty?
        end
        xml.td do
          xml << "Tellers for the #{options[:vote_type].titleize}:"
        end
      end

      while (!teller_votes.empty? or !leftover_votes.empty?)
        options[:first_vote] = leftover_votes.shift
        options[:second_vote] = teller_votes.shift
        vote_pair_xml(options)
      end
    end
  end

  protected

    def self::pre_1981_and_three_columns year, values
      year < 1981 && values.delete_if{|v| v.blank?}.size == 3
    end

    def self::post_1980_and_two_columns year, values
      year > 1980 && values.delete_if{|v| v.blank?}.size == 2
    end
end
