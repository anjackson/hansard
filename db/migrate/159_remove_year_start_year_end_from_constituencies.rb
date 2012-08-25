class RemoveYearStartYearEndFromConstituencies < ActiveRecord::Migration
  def self.up
    remove_column :constituencies, :year_start 
    remove_column :constituencies, :year_end
  end

  def self.down
    add_column :constituencies, :year_start, :integer
    add_column :constituencies, :year_end, :integer
  end
end
