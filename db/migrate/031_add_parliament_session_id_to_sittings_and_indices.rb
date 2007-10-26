class AddParliamentSessionIdToSittingsAndIndices < ActiveRecord::Migration
  def self.up
    add_column :sittings, :parliament_session_id, :integer
    add_column :indices, :parliament_session_id, :integer

    add_column :parliament_sessions, :data_file_id, :integer
  end

  def self.down
    remove_column :sittings, :parliament_session_id
    remove_column :indices, :parliament_session_id

    remove_column :parliament_sessions, :data_file_id
  end
end
