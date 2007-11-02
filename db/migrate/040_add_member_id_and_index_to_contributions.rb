class AddMemberIdAndIndexToContributions < ActiveRecord::Migration
  def self.up
    add_column :contributions, :member_id, :integer
    add_index :contributions, :member_id
  end

  def self.down
    remove_index :contributions, :member_id
    remove_column :contributions, :member_id
  end
end
