class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      # replaced by 030_create_parliament_sessions
    end
  end

  def self.down
    drop_table :sessions
  end
end
