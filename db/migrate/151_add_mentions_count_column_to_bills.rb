class AddMentionsCountColumnToBills < ActiveRecord::Migration
  def self.up
    add_column :bills, :bill_mentions_count, :integer, :default => 0
    Bill.reset_column_information
    Bill.find(:all).each do |bill|
      Bill.update_counters bill.id, :bill_mentions_count => bill.mentions.count
    end
  end

  def self.down
    remove_column :bills, :bill_mentions_count
  end
end
