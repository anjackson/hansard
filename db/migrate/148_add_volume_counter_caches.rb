class AddVolumeCounterCaches < ActiveRecord::Migration
  def self.up
    add_column :volumes, :sittings_count, :integer, :default => 0
    Volume.reset_column_information
    Volume.find(:all).each do |v|
      Volume.update_counters v.id, :sittings_count => v.sittings.count
    end
  end

  def self.down
    remove_column :volumes, :sittings_count
  end
end
