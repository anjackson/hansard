class AddIndexToBillMentions < ActiveRecord::Migration
  def self.up
    add_index :bill_mentions, :first_in_section
  end

  def self.down
    remove_index :bill_mentions, :first_in_section
  end
end
