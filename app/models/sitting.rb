class Sitting < ActiveRecord::Base

  has_one :debates, :class_name => "Debates", :foreign_key => 'sitting_id'

  acts_as_hansard_element

  def first_col
    start_column ? start_column.to_i : nil
  end

  def first_image_source
    start_image_src
  end

end
