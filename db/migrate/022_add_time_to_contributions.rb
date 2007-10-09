class AddTimeToContributions < ActiveRecord::Migration
  def self.up
    add_column :contributions, :time, :time
  end

  def self.down
    remove_column :contributions, :time
  end
end
