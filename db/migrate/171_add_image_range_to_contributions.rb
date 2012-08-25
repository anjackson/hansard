class AddImageRangeToContributions < ActiveRecord::Migration
  def self.up
    add_column :contributions, :start_image, :string
    add_column :contributions, :end_image, :string
  end

  def self.down
    remove_column :contributions, :start_image
    remove_column :contributions, :end_image
  end
end
