class Sitting < ActiveRecord::Base

  has_one :debates, :class_name => "Debates", :foreign_key => "sitting_id", :dependent => :destroy
  has_many :sections, :foreign_key => 'sitting_id', :dependent => :destroy
  belongs_to :data_file
  acts_as_present_on_date :date
  before_validation_on_create :check_date, :default_sitting_text_to_nil

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

  def self.all_grouped_by_year
    sittings = self.find(:all, :order => "date asc")
    sittings.in_groups_by { |s| s.date.year }
  end
  
  def Sitting.find_section_by_column_and_date_range(column, start_date, end_date)
    sitting = find(:first, :conditions => ["date >= ? and date <= ? and start_column <= ?", start_date.to_date, end_date.to_date, column.to_i], :order => "start_column desc")
    if sitting
      section = sitting.sections.find(:first, :conditions => ["start_column <= ?", column], :order => "start_column desc")
    else
      nil
    end
  end

  def Sitting.most_recent
    find_next(Date.today, "<")
  end

  def Sitting.find_in_resolution(date, resolution, part_id=nil)
    case resolution
      when :day
        sittings = find_all_present_on_date(date)
      when :month
        first, last = date.first_and_last_of_month
        sittings = find_all_present_in_interval(first, last)
      when :year
        year_first, year_last = date.first_and_last_of_year
        sittings = find_all_present_in_interval(year_first, year_last)
    end
    if part_id 
      sittings = sittings.select{|sitting| sitting.part_id == part_id}
    end
    sittings
  end

  def Sitting.find_next(day, direction)
    find(:first,
         :conditions => ["date #{direction} ?", day.to_date],
         :order => "date #{direction == ">" ? "asc" : "desc"}")
  end

  def Sitting.uri_component_to_sitting_model type
    case type
      when HouseOfCommonsSitting.uri_component
        HouseOfCommonsSitting
      when HouseOfLordsSitting.uri_component
        HouseOfLordsSitting
      when WrittenAnswersSitting.uri_component
        WrittenAnswersSitting
    end
  end

  def uri_component
    self.class.uri_component
  end

  def first_col
    start_column ? start_column.to_i : nil
  end

  def first_image_source
    start_image_src
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

  protected

    def check_date
      if self.date
        if self.date > Date.today
          raise 'not valid, sitting date is in the future: ' + self.date
        end
      end
    end

    def default_sitting_text_to_nil
      if self.text.blank?
        self.text = nil
      end
    end
end
