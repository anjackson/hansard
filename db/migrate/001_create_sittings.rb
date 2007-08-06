class CreateSittings < ActiveRecord::Migration
  def self.up
    create_table :sittings do |t|
      t.string :type
      t.date :date
      t.string :title
      t.string :date_text
      t.string :column
      t.text :text
    end
  end

  def self.down
    drop_table :sittings
  end
end
