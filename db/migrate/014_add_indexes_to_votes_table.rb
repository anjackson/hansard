class AddIndexesToVotesTable < ActiveRecord::Migration
  def self.up
    add_index :votes, :division_id
  end

  def self.down
    remove_index :votes, :division_id
  end
end
