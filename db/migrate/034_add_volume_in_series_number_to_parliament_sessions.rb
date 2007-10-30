class AddVolumeInSeriesNumberToParliamentSessions < ActiveRecord::Migration
  def self.up
    add_column :parliament_sessions, :volume_in_series_number, :integer
    ParliamentSession.reset_column_information

    add_index :parliament_sessions, :volume_in_series_number

    ParliamentSession.find(:all).each do |session|
      unless session.volume_in_series.blank?
        session.volume_in_series_number = session.volume_in_series_to_i
        session.save!
      end
    end
  end

  def self.down
    remove_index :parliament_sessions, :volume_in_series_number
    remove_column :parliament_sessions, :volume_in_series_number
  end
end
