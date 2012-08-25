class AddUniqueConstraintToAlternativeTitlesTable < ActiveRecord::Migration
  def self.up
    add_index :alternative_titles, [:person_id, :degree, :title, :number, :start_date, :title_type], :name => :alternative_titles_unique_fields, :unique => true
    
  end

  def self.down
    remove_index :alternative_titles, :name => :alternative_titles_unique_fields
  end
end
