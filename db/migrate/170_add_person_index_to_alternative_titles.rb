class AddPersonIndexToAlternativeTitles < ActiveRecord::Migration
  def self.up
    add_index :alternative_titles, :person_id
  end

  def self.down
    remove_index :alternative_titles, :person_id
  end
end
