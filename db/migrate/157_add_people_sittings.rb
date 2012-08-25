class AddPeopleSittings < ActiveRecord::Migration
  def self.up
    create_table :people_sittings, :id => false, :force => true do |t|
      t.integer "person_id"
      t.integer "sitting_id"
    end

    add_index "people_sittings", ["person_id"], :name => "index_people_sittings_on_person_id"
    add_index "people_sittings", ["sitting_id"], :name => "index_people_sittings_on_sitting_id"
    
  end

  def self.down
    drop_table :people_sittings
  end
end
