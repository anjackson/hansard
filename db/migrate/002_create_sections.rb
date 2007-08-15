class CreateSections < ActiveRecord::Migration
  def self.up
    create_table :sections do |t|
      t.string  :type
      t.string  :title
      t.time    :time
      t.string  :time_text
      t.string  :start_column
      t.string  :start_image_src
      t.integer :sitting_id
      t.integer :parent_section_id
    end
  end

  def self.down
    drop_table :sections
  end
end
