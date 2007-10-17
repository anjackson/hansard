class AddPartIdToSittings < ActiveRecord::Migration
  def self.up
    add_column :sittings, :part_id, :integer
  end

  def self.down
    remove_column :sittings, :part_id
  end
end
