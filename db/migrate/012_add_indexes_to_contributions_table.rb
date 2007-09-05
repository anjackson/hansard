class AddIndexesToContributionsTable < ActiveRecord::Migration
  def self.up
    add_index :contributions, :section_id
  end

  def self.down
    remove_index :contributions, :section_id
  end
end
