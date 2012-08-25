class AddSectionTitleToBillMentions < ActiveRecord::Migration
  def self.up
    add_column :bill_mentions, :section_title, :text
  end

  def self.down
    remove_column :bill_mentions, :section_title
  end
end
