class RemoveGeonames < ActiveRecord::Migration
  def self.up
    drop_table :geonames
    drop_table :geoname_mentions
  end

  def self.down
    create_table "geoname_mentions", :force => true do |t|
      t.integer "geoname_id",      :limit => 11
      t.integer "contribution_id", :limit => 11
      t.integer "section_id",      :limit => 11
      t.integer "sitting_id",      :limit => 11
      t.date    "date"
      t.integer "start_position",  :limit => 11
      t.integer "end_position",    :limit => 11
    end

    add_index "geoname_mentions", ["geoname_id"], :name => "index_geoname_mentions_on_geoname_id"
    add_index "geoname_mentions", ["sitting_id"], :name => "index_geoname_mentions_on_sitting_id"
    add_index "geoname_mentions", ["contribution_id"], :name => "index_geoname_mentions_on_contribution_id"
    add_index "geoname_mentions", ["section_id"], :name => "index_geoname_mentions_on_section_id"

    create_table "geonames", :force => true do |t|
      t.integer "geonameid",          :limit => 11
      t.string  "name"
      t.string  "asciiname"
      t.text    "alternatenames"
      t.decimal "latitude",                         :precision => 10, :scale => 7
      t.decimal "longitude",                        :precision => 10, :scale => 7
      t.string  "feature_class"
      t.string  "feature_code"
      t.string  "country_code"
      t.string  "cc2"
      t.string  "admin1_code"
      t.string  "admin2_code"
      t.string  "admin3_code"
      t.string  "admin4_code"
      t.integer "population",         :limit => 11
      t.integer "elevation",          :limit => 11
      t.integer "gtopo30",            :limit => 11
      t.string  "timezone"
      t.date    "modification_date"
      t.string  "first_word_in_name"
      t.boolean "unique_name"
    end

    add_index "geonames", ["first_word_in_name"], :name => "index_geonames_on_first_word_in_name"
    add_index "geonames", ["name"], :name => "index_geonames_on_name"
    add_index "geonames", ["unique_name"], :name => "index_geonames_on_unique_name"
    
  end
end
