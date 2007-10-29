class ParliamentSession < ActiveRecord::Base

  has_many :sittings, :foreign_key => 'session_id', :dependent => :destroy
  belongs_to :source_file
  belongs_to :data_file

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

  def self.series
    find(:all).collect(&:series_number).compact.uniq
  end

  def self.sessions_in_groups_by_volume_in_series series_number
    series = series_number.sub('-series','')
    sessions_in_series = find(:all).select {|s| s.series_number && (s.series_number.downcase == series) }.sort_by(&:volume_in_series)
    sessions_in_series.in_groups_by(&:volume_in_series)
  end

  def volume_in_series_to_i
    if volume_in_series
      if volume_in_series.is_roman_numerial?
        volume_in_series.roman_to_i
      elsif volume_in_series.is_arabic_numerial?
        volume_in_series.to_i
      else
        raise "cannot convert volume_in_series to integer: '#{volume_in_series}'"
      end
    else
      raise "cannot convert nil volume_in_series to integer"
    end
  end
end
