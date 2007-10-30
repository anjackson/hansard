class AddEndColumnToSittings < ActiveRecord::Migration
  def self.up
    add_column :sittings, :end_column, :string
  end

  def self.down
    remove_column :sittings, :end_column
  end
end
