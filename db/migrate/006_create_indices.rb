class CreateIndices < ActiveRecord::Migration
  def self.up
    create_table :indices do |t|
      t.column :title, :string
      t.column :start_date, :datetime
      t.column :start_date_text, :string
      t.column :end_date, :datetime
      t.column :end_date_text, :string
    end
  end

  def self.down
    drop_table :indices
  end
end
