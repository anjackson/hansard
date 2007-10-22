class AddIndexToMemberFieldInContributions < ActiveRecord::Migration
  def self.up
    add_index :contributions, :member
  end

  def self.down
    remove_index :contributions, :member
  end
end
