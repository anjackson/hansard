class Sitting < ActiveRecord::Base

  belongs_to :volume, :counter_cache => true
  has_one :debates, :class_name => "Debates", :foreign_key => "sitting_id", :dependent => :destroy
  has_many :all_sections, :foreign_key => 'sitting_id', :class_name => "Section", :dependent => :destroy
  belongs_to :data_file
  acts_as_present_on_date :date
  after_save :populate_people, :populate_cached_mention_columns
  has_and_belongs_to_many :people, :uniq => true
  has_many :direct_descendents, :foreign_key => 'sitting_id', :class_name => "Section", :conditions => "parent_section_id is null"

  validates_presence_of :date

  has_many :act_mentions
  has_many :bill_mentions

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element
  acts_as_string_normalizer

  @@sitting_order = %w[HouseOfCommonsSitting
                     WestminsterHallSitting
                     CommonsWrittenAnswersSitting
                     CommonsWrittenStatementsSitting
                     HouseOfLordsSitting
                     GrandCommitteeReportSitting
                     LordsWrittenAnswersSitting
                     LordsWrittenStatementsSitting
                     HouseOfLordsReport]

  class << self

    def sort_by_type(sittings)
      sittings.sort{ |a,b| sort_position(a.class.name) <=> sort_position(b.class.name) }
    end
    
    def house
      'Both'
    end

    def find_sitting_and_section type, date, slug
      sitting_model = uri_component_to_sitting_model(type)
      sittings = sitting_model.find_all_by_date(date.to_date.to_s)
      sittings.each do |sitting|
        section = sitting.find_section_by_slug(slug)
        return sitting, section if section
      end
      return [nil, nil]
    end

    def find_sitting type, date
      sitting_model = uri_component_to_sitting_model(type)
      sitting_model.find_by_date(date.to_date.to_s)
    end

    def each_year_of_sittings
      all_grouped_by_year.each do |group|
        yield group.first.date.year, group
      end
    end

    def all_grouped_by_year
      sittings = find(:all, :order => "date asc")
      sittings.in_groups_by { |s| s.date.year }
    end
    
    def find_for_year year
      return find(:all, :conditions => ['YEAR(date) = ?',year])
    end

    def find_section_by_column_and_date(column, date, end_column=nil)
      sittings = find_all_by_date(date)
      if sittings.size == 1
        sittings.first.find_section_by_column(column, end_column)
      elsif sittings.size > 1
        logger.error "Error: Sitting.find_section_by_column_and_date unexpectedly found more than one #{self.name} sitting for date #{date.to_s}"
        nil
      else
        nil
      end
    end

    def find_in_resolution(date, resolution) # important - leave as self.find_in_resolution
      case resolution
        when :day
          find_all_present_on_date(date)
        when :month
          first, last = date.first_and_last_of_month
          find_all_present_in_interval(first, last)
        when :year
          year_first, year_last = date.first_and_last_of_year
          find_all_present_in_interval(year_first, year_last)
        when :decade
          decade_first, decade_last = date.first_and_last_of_decade
          find_all_present_in_interval(decade_first, decade_last)
      end
    end

    def find_next(day, direction)
      find(:first,
           :conditions => ["date #{direction} ?", day.to_date],
           :order => "date #{direction == ">" ? "asc" : "desc"}")
    end

    def uri_component_to_sitting_model type
      case type
        when HouseOfCommonsSitting.uri_component
          HouseOfCommonsSitting
        when HouseOfLordsSitting.uri_component
          HouseOfLordsSitting
        when HouseOfLordsReport.uri_component
          HouseOfLordsReport
        when WrittenAnswersSitting.uri_component
          WrittenAnswersSitting
        when WrittenStatementsSitting.uri_component
          WrittenStatementsSitting
        when WestminsterHallSitting.uri_component
          WestminsterHallSitting
        when GrandCommitteeReportSitting.uri_component
          GrandCommitteeReportSitting
      end
    end

    def column_number(column)
      column_number = /\d+/.match(column.to_s)
      column_number ? column_number[0].to_i : 0
    end

    def normalized_column(column)
      "#{column_number(column)}#{hansard_reference_suffix}"
    end

    def sitting_type_name
      uri_component.humanize.titleize
    end

    def hansard_reference_prefix
      ""
    end

    def hansard_reference_suffix
      ""
    end

    def sort_position(sitting_class)
      order_index = @@sitting_order.index(sitting_class)
      order_index or @@sitting_order.length
    end

    def extra_column_suffix(column)
      sitting_type_suffixes = ['W', 'WS', 'GC', 'WA', 'WS', 'WH']
      column_with_suffix = /\d+([A-Za-z]+)/.match(column.to_s)
      if column_with_suffix
        suffix = column_with_suffix[1]
        return nil if sitting_type_suffixes.include? suffix.upcase
        return suffix
      end
      nil
    end
    
    def sections_from_years_ago(years, date, num_days)
      sections = []
      date = date - (num_days - 1)
      num_days.times do 
        section = section_from_years_ago(years, date)
        sections << [section, date] unless sections.assoc(section)
        date += 1
      end
      sections.reverse
    end
    
    def section_from_years_ago(years, date=nil)
      date = Date.today unless date
      sitting = find_closest_to date.years_ago(years)
      return nil unless sitting
      sitting.longest_sections(1).first
    end

    def find_closest_to date
      date = date.to_date
      next_sitting = find(:first, :conditions => ['date >= ?', date], :order => 'date asc')
      return next_sitting if next_sitting and next_sitting.date == date
      previous_sitting = find(:first, :conditions => ['date < ?', date], :order => 'date desc')
      return next_sitting if next_sitting and !previous_sitting
      return previous_sitting if previous_sitting and !next_sitting
      return nil if !(next_sitting and previous_sitting)
      if (date - previous_sitting.date) < (next_sitting.date - date)
        return previous_sitting
      else
        return next_sitting
      end
    end

    def column_significant_digits(start_number, end_number)
      start_text = start_number.to_s
      end_text = end_number.to_s
      if end_text.size > start_text.size
        significant_digits = end_text
      else
        start_part = start_text
        end_part = end_text
        while start_part && end_part && start_part[0] == end_part[0]
          start_part = start_part[1, (start_part.size - 1)]
          end_part = end_part[1, (end_part.size - 1)]
        end
        significant_digits = end_part
      end
      significant_digits
    end

    def single_column_reference column
      if column_number(column) == 0
        ""
      else
        "#{column_number(column).to_s}#{extra_column_suffix(column)}"
      end
    end

    def column_range_reference column, end_column
      start_number = column_number(column)
      end_number = column_number(end_column)
      extra_suffix = extra_column_suffix(column)
      extra_end_suffix = extra_column_suffix(end_column)
      significant_digits = column_significant_digits(start_number, end_number)
      "c#{start_number}#{extra_suffix}-#{significant_digits}#{extra_end_suffix}"
    end
  end

  def find_section_by_slug slug
    includes = [{:contributions => [{:act_mentions => :act}, 
                                    {:bill_mentions => :bill}, 
                                    {:commons_membership => :person}, 
                                    {:lords_membership => :person}]}]
    section = all_sections.find_by_slug(slug, :include => includes)
  end

  def find_division division_number
    divisions = all_sections.collect(&:divisions).flatten
    if divisions
      divisions.find{|d| d.division_id == division_number}
    else
      nil
    end
  end

  def longest_sections number
    all_sections.sort_by(&:word_count).reverse.slice(0, number)
  end
  
  def title_cleaned
    if title && title.ends_with?(",")
      title.chop!
    else
      title
    end
  end

  def missing_columns?
    return true unless (start_column and end_column)
    first = Sitting.column_number(start_column)
    last = Sitting.column_number(end_column)
    first.upto(last) do |column|
      return true unless find_section_by_column(column.to_s)
    end
    false
  end

  def date_and_column_sort_params
    [date, Sitting.column_number(start_column), Sitting.sort_position(self.class.name)]
  end

  def find_section_in_sections_by_column(column, sections, end_column)
    section = sections.detect{ |section| section.in_columns?(column, end_column) } if end_column
    return section if section
    section = sections.detect{ |section| section.in_column?(column) }
  end

  def find_section_by_column(column, end_column=nil)
    section = find_section_in_sections_by_column(column, all_sections, end_column)
    return nil unless section
    while section.sections.size > 0
      found = find_section_in_sections_by_column(column, section.sections, end_column)
      break if not found
      section = found
    end
    section
  end

  def self.uri_component
    'sittings'
  end

  def sitting_type_name
    self.class.sitting_type_name
  end

  def house
    self.class.house
  end

  def anchor
    self.class.anchor
  end

  def uri_component
    self.class.uri_component
  end

  def year
    date.year if date
  end

  def month
    date.month if date
  end

  def day
    date.day if date
  end

  def id_hash
    {:year  => year,
     :month => month_abbreviation,
     :day   => zero_padded_day,
     :type  => uri_component}
  end

  def top_level_sections
    if debates
      debates.sections
    elsif all_sections
      all_sections
    else
      []
    end
  end

  def populate_people
    self.people = []
    contributions.each do |contribution|
      if contribution.person and !self.people.include? contribution.person
        self.people << contribution.person
      end
    end

    true
  end
  
  def offices_in_sitting
    @offices_in_sitting ||= create_offices_in_sitting
  end

  def create_offices_in_sitting
    offices = Hash.new { |hash, key| hash[key] = [] }
    if chairman
      office, name = Sitting.office_and_name(chairman)
      if office
        offices['chairman'] = membership_lookups[:office_names][office.downcase]
      elsif name
        offices['chairman'] = membership_class.get_memberships_by_name(name, membership_lookups)
      end
    end
    offices
  end

  def membership_lookups
    @lookups ||= get_membership_lookups
  end
  
  def get_membership_lookups
    return membership_class.membership_lookups(date) 
  end
  
  def membership_class
    return CommonsMembership if house == 'Commons'
    return LordsMembership if house == 'Lords'
  end

  def match_people
    #populating relationships with same model instances to keep context between contributions
    all_sections.each do |section|
      section.sitting = self
      section.contributions.each do |contribution|
        contribution.section = section
        contribution.populate_memberships
        contribution.save
      end
    end
  end
  
  def person_contributions(person)
    contributions.select do |c| 
      person.commons_membership_ids.include? c.commons_membership_id or person.lords_membership_ids.include? c.lords_membership_id
    end
  end
  
  def contributions(contribution_include=nil)
    to_include = :contributions
    to_include = contribution_include if contribution_include
    sections = Section.find(:all, :conditions => ["sitting_id = ?", self], :include => to_include)
    sections.map{|section| section.contributions}.flatten
  end

  def each_section
    all_sections.each do |section|
      yield section
    end
  end

  def volume_ref
    (volume && volume.number) ? "vol #{volume.number}" : ''
  end
  
  def series
    volume ? volume.series : nil
  end

  def column_reference column, end_column
    if end_column && end_column != column
      column_reference = Sitting.column_range_reference(column, end_column)
    else
      column_reference = Sitting.single_column_reference(column)
    end
    column_reference += " " if ('a'..'z').include?(column_reference.last.downcase) if ! column_reference.blank?
    column_reference += self.class.hansard_reference_suffix if ! column_reference.blank?
    column_reference = "c#{column_reference}" if ! column_reference.blank?
    column_reference
  end

  def hansard_reference column, end_column=nil
    date_text = date.strftime('%d %B %Y')
    reference = "#{self.class.hansard_reference_prefix} Deb #{date_text} #{volume_ref}"
    column_ref = column_reference(column, end_column)
    reference += " #{column_ref}" if ! column_ref.blank?
    reference
  end

  def debates_sections
    debates.sections
  end

  def debates_sections_count
    debates_sections.size
  end
  
  def populate_cached_mention_columns
    [[:act_mentions, :act_id], [:bill_mentions, :bill_id]].each do |mention_list, mentionable_id_attribute|
      mentionable_lists = self.send(mention_list).group_by(&:section_id)
      mentionable_lists.keys.each do |section_id|
        section_mentions = mentionable_lists[section_id]
        add_summary_info_to_section_mentions(section_mentions, mentionable_id_attribute)
      end
    end
  end
  
  def add_summary_info_to_section_mentions mention_list, mentionable_id_attribute
    mentions_by_instance = mention_list.group_by(&mentionable_id_attribute)
    mentions_by_instance.keys.each do |mentionable_id|
      mentions = mentions_by_instance[mentionable_id]
      count = mentions.size
      contribution_list = mentions.select{ |mention| mention.contribution_id }
      first_mention = contribution_list.min{ |a,b| a.contribution_id <=> b.contribution_id }
      first_mention = mentions.first unless first_mention
      first_mention.first_in_section = true
      first_mention.mentions_in_section = count
      first_mention.save!
    end
  end
  
  def type_abbreviation
    abbreviation = []
    self.class.name.each_char{ |char| abbreviation << char if char == char.upcase }
    abbreviation = abbreviation.join.chomp('S')
    if match = /part_(\d).xml/.match(data_file.name)
      abbreviation += match[1]
    end
    abbreviation
  end

  def short_date
    date ? date.strftime("%Y%m%d") : ''
  end
  
  protected

    def month_abbreviation
      Date::ABBR_MONTHNAMES[date.month].downcase if date
    end

    def zero_padded_day
      if date
        day = date.day
        zero_padded_digit(day)
      end
    end

    def check_date
      if date && date > Date.today
        raise 'not valid, sitting date is in the future: ' + date.to_s
      end
    end

end
