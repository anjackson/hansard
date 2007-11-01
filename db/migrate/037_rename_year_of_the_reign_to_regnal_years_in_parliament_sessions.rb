class RenameYearOfTheReignToRegnalYearsInParliamentSessions < ActiveRecord::Migration
  def self.up
    rename_column :parliament_sessions, :year_of_the_reign, :regnal_years
  end

  def self.down
    rename_column :parliament_sessions, :regnal_years, :year_of_the_reign
  end
end
