class Sitting < ActiveRecord::Base

  has_one :debates, :class_name => "Debates", :foreign_key => "sitting_id", :dependent => :destroy
  has_many :sections, :foreign_key => 'sitting_id', :dependent => :destroy
  belongs_to :data_file
  acts_as_present_on_date :date
  before_validation_on_create :check_date, :default_sitting_text_to_nil

  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

  def Sitting.find_sitting_and_section type, date, slug
    sitting_model = Sitting.uri_component_to_sitting_model(type)
    sittings = sitting_model.find_all_by_date(date.to_date.to_s)

    sittings.each do |sitting|
      section = sitting.sections.find_by_slug(slug)
      return sitting, section if section
    end
  end

  def self.all_grouped_by_year # important - leave as self.all_grouped_by_year
    sittings = find(:all, :order => "date asc")
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

  def self.find_in_resolution(date, resolution) # important - leave as self.find_in_resolution
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

  def id_hash
    {:year  => year,
     :month => month_abbreviation,
     :day   => zero_padded_day,
     :type  => uri_component}
  end

  protected

    def month_abbreviation
      Date::ABBR_MONTHNAMES[date.month].downcase if date
    end

    def zero_padded_day
      if date
        day = date.day
        day < 10 ? "0"+ day.to_s : day.to_s
      end
    end

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
