class AddLordsMembershipIdToContribution < ActiveRecord::Migration
  def self.up
    add_column :contributions, :lords_membership_id, :integer
    add_index :contributions, :lords_membership_id
  end

  def self.down
    remove_index :contributions, :lords_membership_id
    remove_column :contributions, :lords_membership_id
  end
end
