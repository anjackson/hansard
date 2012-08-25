class AddCachedColumnsToBillMentions < ActiveRecord::Migration
  def self.up
    add_column :bill_mentions, :first_in_section, :boolean
    add_column :bill_mentions, :mentions_in_section, :integer
    add_column :bill_mentions, :sitting_type, :string
  end

  def self.down
    remove_column :bill_mentions, :sitting_type
    remove_column :bill_mentions, :mentions_in_section
    remove_column :bill_mentions, :first_in_section
  end
end
