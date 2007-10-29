class ParliamentSession < ActiveRecord::Base

  has_many :sittings, :foreign_key => 'session_id', :dependent => :destroy
  belongs_to :source_file
  belongs_to :data_file

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

  def self.monarchs
    find(:all).collect(&:monarch_name).compact.uniq
  end

  def self.series
    find(:all).collect(&:series_number).compact.uniq
  end

  def self.sessions_in_groups_by_volume_in_series series_number
    sessions_in_series = find(:all).
        select {|s| s.series_number && (s.series_number.downcase == series_number) }.
        sort_by(&:volume_in_series_to_i)

    sessions_in_series.in_groups_by(&:volume_in_series)
  end

  def self.sessions_in_groups_by_year_of_the_reign monarch_name
    monarch_name = monarch_name.sub('_',' ')
    sessions_in_series = find(:all).
        select {|s| s.monarch_name && (s.monarch_name.downcase == monarch_name) }.
        sort_by(&:monarch_name)

    sessions_in_series.in_groups_by(&:monarch_name)
  end

  def volume_in_series_to_i
    if volume_in_series
      if volume_in_series.is_roman_numeral?
        volume_in_series.roman_to_i
      elsif volume_in_series.is_arabic_numeral?
        volume_in_series.to_i
      else
        raise "cannot convert volume_in_series to integer: '#{volume_in_series}'"
      end
    else
      raise "cannot convert nil volume_in_series to integer"
    end
  end
end
