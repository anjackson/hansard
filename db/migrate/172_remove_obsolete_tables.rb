class RemoveObsoleteTables < ActiveRecord::Migration
  def self.up
    drop_table :constituency_holders
    drop_table :members
    drop_table :members_sittings
  end

  def self.down
    
    create_table "constituency_holders", :force => true do |t|
      t.integer "member_id",       :limit => 11
      t.integer "constituency_id", :limit => 11
      t.date    "start_date"
      t.date    "end_date"
    end

    add_index "constituency_holders", ["constituency_id"], :name => "index_constituency_holders_on_constituency_id"
    add_index "constituency_holders", ["member_id"], :name => "index_constituency_holders_on_member_id"
    add_index "constituency_holders", ["start_date"], :name => "index_constituency_holders_on_start_date"
    add_index "constituency_holders", ["end_date"], :name => "index_constituency_holders_on_end_date"
    
    create_table "members", :force => true do |t|
      t.string  "name"
      t.string  "slug"
      t.integer "contribution_count", :limit => 11, :default => 0
      t.text    "merge_candidates"
    end

    add_index "members", ["name"], :name => "index_members_on_name", :unique => true
    add_index "members", ["slug"], :name => "index_members_on_slug", :unique => true

    create_table "members_sittings", :id => false, :force => true do |t|
      t.integer "member_id",  :limit => 11
      t.integer "sitting_id", :limit => 11
    end

    add_index "members_sittings", ["member_id"], :name => "index_members_sittings_on_member_id"
    add_index "members_sittings", ["sitting_id"], :name => "index_members_sittings_on_sitting_id"
    
  end
  
end
