class AddSourceFileIdToDataFilesTable < ActiveRecord::Migration
  def self.up
    add_column :data_files, :source_file_id, :integer
  end

  def self.down
    remove_column :data_files, :source_file_id
  end
end
