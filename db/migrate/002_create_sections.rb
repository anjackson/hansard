class CreateSections < ActiveRecord::Migration
  def self.up
    create_table :sections do |t|
      t.string :type
      t.string :title
      t.time :time
      t.string :time_text
      t.string :column
    end
  end

  def self.down
    drop_table :sections
  end
end
