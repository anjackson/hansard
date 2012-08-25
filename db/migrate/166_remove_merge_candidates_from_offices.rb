class RemoveMergeCandidatesFromOffices < ActiveRecord::Migration
  def self.up
    remove_column :offices, :merge_candidates
  end

  def self.down
    add_column :offices, :merge_candidates, :text
  end
end
