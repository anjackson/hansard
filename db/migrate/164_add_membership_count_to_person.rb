class AddMembershipCountToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :membership_count, :integer, :default => 0
  end

  def self.down
    remove_column :people, :membership_count
  end
end
