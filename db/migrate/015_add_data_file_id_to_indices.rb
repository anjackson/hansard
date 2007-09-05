class AddDataFileIdToIndices < ActiveRecord::Migration
  def self.up
    add_column :indices, :data_file_id, :integer
  end

  def self.down
    remove_column :indices, :data_file_id
  end
end
