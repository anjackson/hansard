class CreateAlternativeTitleTable < ActiveRecord::Migration
  def self.up
    create_table :alternative_titles, :force => true do |t|
      t.integer :import_id
      t.integer :person_id
      t.date :start_date
      t.date :end_date
      t.boolean :estimated_start_date
      t.boolean :estimated_end_date
      t.integer :data_source_id
      t.string :number
      t.string :degree
      t.string :title
      t.string :name
      t.string :title_type 
      t.timestamps
    end
  end

  def self.down
    drop_table :alternative_titles
  end
end
