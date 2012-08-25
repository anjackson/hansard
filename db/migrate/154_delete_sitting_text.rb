class DeleteSittingText < ActiveRecord::Migration
  def self.up
    remove_column :sittings, :text
  end

  def self.down
    add_column :sittings, :text, :text
  end
end
