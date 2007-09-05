class Index < ActiveRecord::Base
  has_many :index_entries, :dependent => :destroy
  belongs_to :data_file
  
  def Index.find_by_date_span(start_date, end_date)
    find(:first, :conditions => ["start_date = ? and end_date = ? ", start_date, end_date])
  end
  
  def entries(letter)
    index_entries.find(:all, :conditions => ["letter = ?", letter])
  end

end