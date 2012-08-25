class AddCachedColumnsForActMentions < ActiveRecord::Migration
  def self.up
    add_column :act_mentions, :first_in_section, :boolean
    add_column :act_mentions, :mentions_in_section, :integer
    add_index :act_mentions, :first_in_section
  end

  def self.down
    remove_index :act_mentions, :first_in_section
    remove_column :act_mentions, :mentions_in_section
    remove_column :act_mentions, :first_in_section
  end
end
