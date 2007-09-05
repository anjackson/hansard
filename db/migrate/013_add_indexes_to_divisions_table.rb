class AddIndexesToDivisionsTable < ActiveRecord::Migration
  def self.up
    add_index :divisions, :division_placeholder_id
  end

  def self.down
    remove_index :divisions, :division_placeholder_id
  end
end
