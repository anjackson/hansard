class AddEndColumnToSections < ActiveRecord::Migration
  def self.up
    add_column :sections, :end_column, :string
  end

  def self.down
    remove_column :sections, :end_column
  end
end
