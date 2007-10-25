class AddTypeIndexToContributions < ActiveRecord::Migration
  def self.up
    add_index :contributions, :type
  end

  def self.down
    remove_index :contributions, :type
  end
end
