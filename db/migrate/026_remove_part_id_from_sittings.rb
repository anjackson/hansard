class RemovePartIdFromSittings < ActiveRecord::Migration
  def self.up
    # remove_column :sittings, :part_id
  end

  def self.down
    # add_column :sittings, :part_id
  end
end
