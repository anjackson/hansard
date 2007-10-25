class ParliamentSession < ActiveRecord::Base

  has_many :sittings, :foreign_key => 'session_id', :dependent => :destroy
  belongs_to :source_file

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

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
