class AddSourceFileToSittings < ActiveRecord::Migration
  def self.up
    add_column :sittings, :data_file_id, :integer
  end

  def self.down
    remove_column :sittings, :data_file_id
  end
end
