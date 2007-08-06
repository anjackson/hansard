class CreateContributions < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
      t.string :type
      t.string :xml_id
      t.string :member
      t.string :memberconstituency
      t.string :membercontribution
      t.string :column
      t.string :oral_question_no
    end
  end

  def self.down
    drop_table :contributions
  end
end
