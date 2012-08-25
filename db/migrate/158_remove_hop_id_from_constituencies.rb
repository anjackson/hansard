class RemoveHopIdFromConstituencies < ActiveRecord::Migration
  def self.up
    remove_column :constituencies, :hop_id
  end

  def self.down
    add_column :constituencies, :hop_id, :integer
  end
end
