class AddComprisingPeriodTextToParliamentSessions < ActiveRecord::Migration
  def self.up
    add_column :parliament_sessions, :comprising_period, :string
  end

  def self.down
    remove_column :parliament_sessions, :comprising_period
  end
end
