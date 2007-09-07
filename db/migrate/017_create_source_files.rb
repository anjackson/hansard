class CreateSourceFiles < ActiveRecord::Migration
  def self.up
    create_table :source_files do |t|
      t.column :name, :string
      t.column :schema, :string
      t.column :start_date, :datetime
      t.column :start_date_text, :string
      t.column :end_date, :datetime
      t.column :end_date_text, :string
      t.column :result_directory, :string
      t.column :log, :text
    end
  end

  def self.down
    drop_table :source_files
  end
end
