class CreateIndexEntries < ActiveRecord::Migration
  def self.up
    create_table :index_entries do |t|
      t.column :index_id, :integer
      t.column :letter, :string
      t.column :parent_entry_id, :integer
      t.column :text, :string
      t.column :entry_context, :string
    end
  end

  def self.down
    drop_table :index_entries
  end
end
