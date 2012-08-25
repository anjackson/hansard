class AddSittingsTriedCountToVolume < ActiveRecord::Migration
  def self.up
    add_column :volumes, :sittings_tried_count, :integer, :default => 0
    Volume.reset_column_information
    Volume.find(:all).each do |volume|
      volume.sittings_tried_count = volume.source_file.data_files.count( :conditions => ["name != 'header.xml'"])
      volume.save!
    end
  end

  def self.down
    remove_column :volumes, :sittings_tried_count
  end
end
