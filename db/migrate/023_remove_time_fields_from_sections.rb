class RemoveTimeFieldsFromSections < ActiveRecord::Migration
  def self.up
    remove_column :sections, :time
    remove_column :sections, :time_text
  end

  def self.down
    add_column :sections, :time, :time
    add_column :sections, :time_text, :string
  end
end
