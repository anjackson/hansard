class AddContributionCountToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :contribution_count, :integer, :default => 0
  end

  def self.down
    remove_column :people, :contribution_count
  end
end
