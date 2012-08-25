class RemoveCachedColumnsFromBillMention < ActiveRecord::Migration
  def self.up
    remove_column :bill_mentions, :sitting_type 
    remove_column :bill_mentions, :section_title
  end

  def self.down
    add_column :bill_mentions, :sitting_type, :string
    add_column :bill_mentions, :section_title, :text
  end
end
