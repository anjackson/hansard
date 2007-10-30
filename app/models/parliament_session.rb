class ParliamentSession < ActiveRecord::Base

  has_many :sittings, :dependent => :destroy, :order => 'date'
  belongs_to :source_file
  belongs_to :data_file

  before_validation_on_create :populate_volume_in_series_number

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
        sort_by(&:volume_in_series_number)

    sessions_in_series.in_groups_by(&:volume_in_series)
  end

  def self.sessions_in_groups_by_year_of_the_reign monarch_name
    monarch_name = monarch_name.sub('_',' ')
    sessions_in_series = find(:all).
        select {|s| s.monarch_name && (s.monarch_name.downcase == monarch_name) }.
        sort_by(&:monarch_name)

    sessions_in_series.in_groups_by(&:monarch_name)
  end

  def self.find_volume series_number, volume_number_and_part # important don't change self to ParliamentSession
    if volume_number_and_part.include? '_'
      volume_number = volume_number_and_part.split('_')[0].to_i
      part_number = volume_number_and_part.split('_')[1].to_i

      sessions = self.find_all_by_volume_in_series_number_and_volume_in_series_part_number(volume_number, part_number)
    else
      volume_number = volume_number_and_part.to_i
      sessions = self.find_all_by_volume_in_series_number(volume_number)
    end

    selected = sessions.select{|s| s.series_number.downcase == series_number}
    selected.first
  end

  def start_column
    if sittings.size > 0
      sittings.first.start_column
    else
      nil
    end
  end

  def end_column
    if sittings.size > 0
      sittings.last.end_column
    else
      nil
    end
  end

  protected

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

    def populate_volume_in_series_number
      if volume_in_series
        self.volume_in_series_number = volume_in_series_to_i
      end
    end
end
