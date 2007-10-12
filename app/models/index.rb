class Index < ActiveRecord::Base

  has_many :index_entries, :dependent => :destroy
  belongs_to :data_file

  def Index.find_by_date_span(start_date, end_date)
    find(:first, :conditions => ["start_date = ? and end_date = ? ", start_date, end_date])
  end

  def self.find_all_in_groups_by_decade
    indices = Index.find(:all, :order => "start_date asc")
    indices.in_groups_by { |index| index.decade }
  end

  def entries(letter)
    index_entries.find(:all, :conditions => ["letter = ?", letter])
  end

  def decade
    year = if start_date
             start_date.year
           elsif end_date
             end_date.year
           else
             nil
           end

    if year
      year - (year % 10)
    else
      0
    end
  end
end