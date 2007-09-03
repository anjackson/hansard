class CreateFiles < ActiveRecord::Migration
  def self.up
    create_table :files do |t|
      t.string  :name
      t.string  :directory
      t.boolean :attempted_save
      t.boolean :saved
      t.text    :log
    end
  end

  def self.down
    drop_table :files
  end
end
