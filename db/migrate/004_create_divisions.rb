class CreateDivisions < ActiveRecord::Migration

  def self.up
    create_table :divisions do |t|
      t.string  :name
      t.time    :time
      t.string  :time_text
      t.integer :division_placeholder_id
    end
  end

  def self.down
    drop_table :divisions
  end
end
