class CreateContributions < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
      t.string  :type
      t.string  :xml_id
      t.string  :member
      t.string  :memberconstituency
      t.text    :text
      t.string  :column
      t.string  :oral_question_no
      t.integer :section_id
    end
  end

  def self.down
    drop_table :contributions
  end
end
