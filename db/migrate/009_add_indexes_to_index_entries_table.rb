class AddIndexesToIndexEntriesTable < ActiveRecord::Migration
  def self.up
    add_index :index_entries, :index_id
  end

  def self.down
    remove_index :index_entries, :index_id
  end
end
