class AddAnchorIdToContributions < ActiveRecord::Migration
  def self.up
    add_column :contributions, :anchor_id, :string
  end

  def self.down
    remove_column :contributions, :anchor_id
  end
end
