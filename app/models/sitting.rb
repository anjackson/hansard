class Sitting < ActiveRecord::Base
  
  def first_col
    start_column ? start_column.to_i : nil
  end

end
