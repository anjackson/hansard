class AddMentionCountColumnToActs < ActiveRecord::Migration
  def self.up
    add_column :acts, :act_mentions_count, :integer, :default => 0
    Act.reset_column_information
    Act.find(:all).each do |act|
      Act.update_counters act.id, :act_mentions_count => act.mentions.count
    end
  end

  def self.down
    remove_column :acts, :act_mentions_count
  end
end
