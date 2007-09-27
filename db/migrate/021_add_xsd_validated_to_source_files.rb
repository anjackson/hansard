class AddXsdValidatedToSourceFiles < ActiveRecord::Migration
  def self.up
    add_column :source_files, :xsd_validated, :boolean
  end

  def self.down
    remove_column :source_files, :xsd_validated
  end
end
