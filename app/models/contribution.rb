require 'hpricot'

class Contribution < ActiveRecord::Base

  include ActionView::Helpers::SanitizeHelper

  belongs_to :section
  belongs_to :commons_membership
  belongs_to :lords_membership
  belongs_to :constituency
  belongs_to :party
  has_many :act_mentions, :dependent => :destroy
  has_many :bill_mentions, :dependent => :destroy
  alias :to_activerecord_xml :to_xml
  attr_accessor :office
  before_validation_on_create :parse_member_suffix,
                              :populate_constituency,
                              :populate_party,
                              :populate_mentions,
                              :correct_part_mispellings,
                              :correct_fact_mispellings

  before_create :populate_memberships
  acts_as_hansard_element
  acts_as_string_normalizer
   
  acts_as_solr :fields => [:solr_text, {:person_id => :facet},
                                       {:date => :facet},
                                       {:year => :facet},
                                       {:decade => :facet},
                                       {:sitting_type => :facet}],
               :facets => [:person_id, {:date => :date}, :year, :decade ]
  
  def person
    if commons_membership
      commons_membership.person
    elsif lords_membership
        lords_membership.person
    else
      nil
    end
  end
  
  def person_id
    if commons_membership
      commons_membership.person_id
    elsif lords_membership
      lords_membership.person_id
    else
      nil
    end
  end

  def Contribution.contributions_for_sitting(sitting)
    find(:all, :conditions => ["contributions.section_id in (SELECT id from sections where sitting_id = ?)", sitting])
  end

  def solr_text
    return nil unless text
    solr_text = text.gsub(/<col>\d+<\/col>/, '')
    solr_text = strip_tags(solr_text)
    HTMLEntities.new.decode(solr_text)
  end

  def mentions
    mentions = act_mentions + bill_mentions
    mentions.sort_by(&:start_position)
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    xml_para(options) do
      xml << text.to_xs if text
    end
  end

  def year
    date.year
  end
  
  def decade
    date.decade
  end

  def sitting
    section.sitting
  end

  def sitting_title
    sitting.title
  end

  def sitting_type
    section.sitting_type
  end

  def date
    section.date
  end

  def parent_sections
    [section] + section.parent_sections
  end

  def first_linkable_parent
    linkable_parent = parent_sections.detect{ |section| section.linkable? }
    linkable_parent = parent_sections.first unless linkable_parent
    linkable_parent
  end

  def cols
     column_range ? column_range.split(",").map{ |col| col } : []
  end

  def start_column
    cols.empty? ? nil : cols.first
  end
  
  def end_column
    cols.empty? ? nil : cols.last
  end

  def xml_para(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    attribute_hash = {}
    if style
      style.split(" ").each do |style|
        key, value = style.split('=')
        attribute_hash[key] = value
      end
    end
    attribute_hash.update(:id => anchor_id)
    xml.p(attribute_hash) do
      yield
    end
  end

  def Contribution.find_by_person_in_year(person, year)
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)
    commons_membership_ids = person.commons_memberships.map{ |m| m.id }
    lords_membership_ids = person.lords_memberships.map{ |m| m.id }
    params = person_in_year_params(commons_membership_ids, lords_membership_ids, start_date, end_date)
    contributions = Contribution.find(:all, :conditions => params, 
                                            :include => [{:section => [:sitting]}])
    return [] if contributions.empty?
    contributions.sort_by {|c| [c.section.date, c.section.id] }.in_groups_by {|c| c.section.id }
  end

  def Contribution.person_in_year_params(commons_ids, lords_ids, start_date, end_date)
    param_string = ''
    params = []
    if !commons_ids.empty? and !lords_ids.empty? 
      param_string += "(contributions.commons_membership_id in (?) or
                       contributions.lords_membership_id in (?)) and "
      params << commons_ids
      params << lords_ids
    elsif !commons_ids.empty?
      param_string += "contributions.commons_membership_id in (?) and "
      params << commons_ids
    elsif !lords_ids.empty? 
      param_string += "contributions.lords_membership_id in (?) and "
      params << lords_ids
    end
    param_string += "\n sittings.date >= ? and 
                     sittings.date <= ?"
    params << start_date
    params << end_date 
    params.unshift(param_string.squeeze(' '))
    params
  end

  def title_via_associations
    return section.title if !section.title.blank?
    return section.parent_section.title if section.parent_section and !section.parent_section.title.blank?
    return sitting.title
  end

  def get_memberships_by_office(office)
    memberships = offices_in_sitting[office.downcase].uniq
    memberships = membership_lookups[:office_names][office.downcase].uniq if memberships.empty?
    memberships
  end

  def narrow_memberships_by_office(memberships, office)
    office_memberships = get_memberships_by_office(office)
    memberships.select{ |member| office_memberships.include?(member) }.uniq
  end

  def narrow_memberships_by_constituency(memberships)
    return memberships unless constituency_id
    constituency_hash = membership_lookups[:constituency_ids]
    constituency_members = constituency_hash[constituency_id]
    memberships.select{|member| constituency_members.include?(member)}.uniq
  end

  def narrow_memberships_by_previous_speakers(memberships, members_in_section)
    return [] if members_in_section.empty?
    all_but_most_recent = members_in_section[0, members_in_section.size-1].compact
    selection = all_but_most_recent.select{|member| memberships.include?(member)}.uniq
    selection
  end

  def person_name
    if Contribution.is_office?(member_name) and !constituency_name.blank?
      name = constituency_name
    else
      name = member_name
    end
    self.office, name = Contribution.office_and_name(name)
    name
  end

  def needs_commons_membership?
    needs_membership?('Commons')
  end
  
  def needs_lords_membership?
    needs_membership?('Lords')
  end
  
  def needs_membership?(house)
    return false if member_name.blank? or sitting.house != house
    return false if Contribution.generic_member_description?(member_name)
    return true
  end

  def members_in_section
    @members_in_section ||= section.members_in_section
  end

  def offices_in_sitting
    @offices_in_sitting ||= sitting.offices_in_sitting
  end

  def membership_lookups
    @membership_lookups ||= sitting.membership_lookups
  end

  def initial_membership_list(name, office, membership_class)
    if !name.blank?
      membership_class.get_memberships_by_name(name, membership_lookups)
    elsif office
      get_memberships_by_office(office)
    else
      []
    end
  end
  
  def populate_memberships
    Contribution.populate_memberships(self)
    return true
  end

  def self.populate_memberships(contribution)
    contribution.populate_commons_membership if contribution.needs_commons_membership?
    contribution.populate_lords_membership if contribution.needs_lords_membership?
  end
  
  def populate_commons_membership
    memberships = initial_membership_list(person_name, office, CommonsMembership)
    unless (is_set = set_membership(memberships, 'commons'))
     memberships = narrow_memberships_by_constituency(memberships)
     unless (is_set = set_membership(memberships, 'commons'))
       if office && !person_name.blank?
         memberships = narrow_memberships_by_office(memberships, office)
         is_set = set_membership(memberships, 'commons')
       end
       unless is_set
         memberships = narrow_memberships_by_previous_speakers(memberships,members_in_section)
         is_set = set_membership([memberships.last], 'commons') unless memberships.empty?
       end
     end
    end
    unless is_set
      members_in_section << nil
    end
  end
  
  def populate_lords_membership
    memberships = initial_membership_list(person_name, office, LordsMembership)
    is_set = set_membership(memberships, 'lords')
  end

  def set_membership(memberships, type)
    if memberships.size == 1
      id = memberships.first
      self.send("#{type}_membership_id=".to_sym, id)
      members_in_section << id
      if office and id
        if /chairman of/.match office.downcase
          offices_in_sitting['chairman'] << id
        end
        offices_in_sitting[office.downcase] << id
      end
      return true
    else
      return false
    end
  end

  def populate_constituency
    if constituency.nil?
      self.constituency = Constituency.find_by_name_and_date(constituency_name, date) if constituency_name
    end
  end

  def populate_mentions
    mentionables = [[Act, act_mentions], [Bill, bill_mentions]]
    mentionables.each do |mentionable_class, mention_association|
      mentionable_class.populate_mentions(text, first_linkable_parent, self).each do |mention|
        mention_association << mention
      end if mention_association.empty?
    end
  end

  def preceding_contribution
    section.preceding_contribution(self)
  end

  def following_contribution
    section.following_contribution(self)
  end

  # Text with elements removed #
  def plain_text
    text ? text.gsub(/<[^>]+>/,' ').squeeze(' ').strip : nil
  end

  private


    PHRASE = '([^)(]*)'

    OPTIONAL_SPACE = '\s*?'

    MEMBER_SUFFIX_PATTERNS = [ # Constituency in correct brackets
                        /\A\(#{PHRASE}\)\Z/,
                        # Constituency in correct brackets, party in correct brackets
                        /\A\(#{PHRASE}\)#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/,
                        # Constituency in correct brackets, party in correct brackets, urgent question
                        /\A\(#{PHRASE}\)#{OPTIONAL_SPACE}\(#{PHRASE}\)#{OPTIONAL_SPACE}\(urgent question\)\Z/,
                        # Constituency only, missing end bracket
                        /\A\(#{PHRASE}\Z/,
                        # Constituency in correct brackets, party missing end bracket
                        /\A\(#{PHRASE}\)#{OPTIONAL_SPACE}\(#{PHRASE}\Z/,
                        # Constituency in correct brackets, party missing start bracket
                        /\A\(#{PHRASE}\)#{OPTIONAL_SPACE}#{PHRASE}\)\Z/,
                        # Constituency missing end bracket, party in correct brackets
                        /\A\(#{PHRASE}#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/,
                        # Constituency in correct brackets, party in correct brackets, misc. char in between
                        /\A\(#{PHRASE}\)#{OPTIONAL_SPACE}.#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/,
                        # Constituency missing start bracket, party in correct brackets
                        /\A#{PHRASE}\)#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/,
                        # Constituency with a bracketed part, party in correct brackets
                        /(\A[^)(]*#{OPTIONAL_SPACE}\([^)(]*\))#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/,
                        # Just constituency, no brackets
                        /\A#{PHRASE}\Z/,
                        # Constituency no brackets, party has brackets
                        /\A#{PHRASE}#{OPTIONAL_SPACE}\(#{PHRASE}\)\Z/
                      ]

    def parse_member_suffix
      return if member_suffix.nil?
      suffix = String.new(member_suffix.strip)

      Contribution.correct_trailing_punctuation(suffix)
      Contribution.normalize_spaces(suffix)
      Contribution.correct_hyphen_variants(suffix)

      suffix.gsub!(/\):\s+.$/, ')')    # strip a single trailing char after ):
      suffix.gsub!(/^.\(/, '(')        # strip a single leading char before (
      suffix.gsub!(/\),\s+?\(?/, ', ') # strip brackets that conflict with ',' and 'and'
      suffix.gsub!(/and \(/, 'and ')
      suffix.gsub!(/\A:\s+?/, '')

      MEMBER_SUFFIX_PATTERNS.each do |suffix_pattern|
        if match = suffix_pattern.match(suffix)
          self.constituency_name = match[1].strip
          self.party_name = match[2].strip if match[2]
          return
        end
      end
    end

    def populate_party
      unless party
        self.party = Party.find_or_create_by_name(party_name) if party_name
      end
    end

    def correct_part_mispellings
      self.text = Contribution.correct_part(text) unless text.blank?
    end

    def correct_fact_mispellings
      self.text = Contribution.correct_fact(text) unless text.blank?
    end
end
