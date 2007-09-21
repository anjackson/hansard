class AddSlugToSectionsTable < ActiveRecord::Migration
  def self.up
    add_column :sections, :slug, :string
  end

  def self.down
    remove_column :sections, :slug
  end
end
