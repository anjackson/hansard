class CreateParliamentSessions < ActiveRecord::Migration
  def self.up
    drop_table :sessions
    create_table :parliament_sessions do |t|
      t.string  :series_number
      t.string  :volume_in_series
      t.string  :type
      t.integer :source_file_id
      t.string  :session_of_parliament
      t.string  :number_of_parliament
      t.string  :year_of_the_reign
      t.string  :monarch_name
      t.string  :years_of_session
      t.string  :volume_of_session
      t.string  :period_start_date_text
      t.string  :period_end_date_text
      t.date    :period_start_date
      t.date    :period_end_date
      t.string  :may_be_cited_as
      t.string  :isbn
      t.text    :titlepage_text
    end
  end

  def self.down
    drop_table :parliament_sessions
    create_table :sessions do |t|
    end
  end
end
