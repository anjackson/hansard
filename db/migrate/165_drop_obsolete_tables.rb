class DropObsoleteTables < ActiveRecord::Migration
  def self.up
    drop_table :indices
    drop_table :index_entries
    drop_table :member_bios
    drop_table :terms
  end

  def self.down
    
    create_table :indices, :force => true do |t|
      t.string :title
      t.date :start_date
      t.string :start_date_text
      t.date :end_date
      t.string :end_date_text
      t.integer :data_file_id
      t.integer :volume_id
    end
    
    create_table :index_entries, :force => true do |t|
      t.integer :index_id,        :limit => 11
      t.string  :letter
      t.integer :parent_entry_id, :limit => 11
      t.string  :text
      t.string  :entry_context
    end
    
    add_index "index_entries", ["index_id"], :name => "index_index_entries_on_index_id"
    
    create_table "member_bios", :force => true do |t|
      t.string   "type"
      t.string   "name_start"
      t.string   "name_end"
      t.string   "bio_url"
      t.string   "constituency"
      t.string   "party_or_affiliation"
      t.string   "contact_url"
      t.string   "member_website"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "member_bios", ["name_end"], :name => "index_member_bios_on_name_end"
    
    create_table "terms", :force => true do |t|
      t.string "text"
      t.string "link"
    end

    add_index "terms", ["text"], :name => "index_terms_on_text"
    
  end
end
