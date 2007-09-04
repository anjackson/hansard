class CreateDataFiles < ActiveRecord::Migration
  def self.up
    create_table :data_files do |t|
      t.string  :name
      t.string  :directory
      t.boolean :attempted_parse
      t.boolean :parsed
      t.boolean :attempted_save
      t.boolean :saved
      t.text    :log
    end
  end

  def self.down
    drop_table :data_files
  end
end
