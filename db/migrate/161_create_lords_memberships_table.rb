class CreateLordsMembershipsTable < ActiveRecord::Migration
  def self.up

    create_table :lords_memberships, :force => true do |t|
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
      t.string :membership_type
      t.timestamps
    end
    
    add_index :lords_memberships, :start_date
    add_index :lords_memberships, :end_date
    add_index :lords_memberships, :person_id

  end

  def self.down

    remove_index :lords_memberships, :person_id
    remove_index :lords_memberships, :end_date
    remove_index :lords_memberships, :start_date

    drop_table :lords_memberships

  end
end
