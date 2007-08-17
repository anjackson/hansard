class CreateContributions < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
      t.string  :type
      t.string  :xml_id
      t.string  :member
      t.string  :member_constituency
      t.text    :text
      t.string  :column_range
      t.string  :image_src_range
      t.string  :oral_question_no
      t.string  :procedural_note
      t.integer :section_id
    end
  end

  def self.down
    drop_table :contributions
  end
end
