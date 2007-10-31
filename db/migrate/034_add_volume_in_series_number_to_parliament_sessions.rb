class AddVolumeInSeriesNumberToParliamentSessions < ActiveRecord::Migration
  def self.up
    add_column :parliament_sessions, :volume_in_series_number, :integer
    ParliamentSession.reset_column_information

    add_index :parliament_sessions, :volume_in_series_number

    ParliamentSession.find(:all).each do |session|
      session.populate_volume_in_series_number
      session.save!
    end
  end

  def self.down
    remove_index :parliament_sessions, :volume_in_series_number
    remove_column :parliament_sessions, :volume_in_series_number
  end
end
