class RenameMemberToMemberNameInContributions < ActiveRecord::Migration
  def self.up
    rename_column :contributions, :member, :member_name
  end

  def self.down
    rename_column :contributions, :member_name, :member
  end
end
