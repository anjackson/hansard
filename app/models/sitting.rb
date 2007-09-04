class Sitting < ActiveRecord::Base

  has_one :debates, :class_name => "Debates", :foreign_key => 'sitting_id'

  before_validation_on_create :check_date

  acts_as_hansard_element

  def Sitting.find_by_column_and_date_range(column, start_date, end_date)
    find(:first, :conditions => ["date >= ? and date <= ? and start_column <= ?", start_date.to_date, end_date.to_date, column.to_i], :order => "start_column desc")
  end

  def first_col
    start_column ? start_column.to_i : nil
  end

  def first_image_source
    start_image_src
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
