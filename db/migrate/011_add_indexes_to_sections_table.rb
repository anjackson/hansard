class AddIndexesToSectionsTable < ActiveRecord::Migration
  def self.up
    add_index :sections, :sitting_id
    add_index :sections, :parent_section_id
  end

  def self.down
    remove_index :sections, :sitting_id
    remove_index :sections, :parent_section_id
  end
end
