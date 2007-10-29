class AddVolumeInSeriesPartNumberToParliamentSessions < ActiveRecord::Migration
  def self.up
    add_column :parliament_sessions, :volume_in_series_part_number, :integer
  end

  def self.down
    remove_column :parliament_sessions, :volume_in_series_part_number
  end
end
