class Sitting < ActiveRecord::Base

  has_one :debates, :class_name => "Debates", :foreign_key => 'sitting_id'
  has_many :sections, :foreign_key => 'sitting_id'
  belongs_to :data_file 
  acts_as_present_on_date :date
  before_validation_on_create :check_date

  acts_as_hansard_element

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
  
  def Sitting.find_next(day, direction)
    find(:first, 
         :conditions => ["date #{direction} ?", day.to_date], 
         :order => "date #{direction == ">" ? "asc" : "desc"}")
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

end
