class AddUniqueSlugConstraints < ActiveRecord::Migration
  def self.up
    remove_index :acts, :column => [:slug]
    add_index :acts, [:slug], :unique => true
    remove_index :bills, :column => [:slug]
    add_index :bills, [:slug], :unique => true
    remove_index :members, :column => [:slug]
    add_index :members, [:slug], :unique => true
    remove_index :offices, :column => [:slug]
    add_index :offices, [:slug], :unique => true
  end

  def self.down
    remove_index :acts, :column => [:slug]
    add_index :acts, [:slug]
    remove_index :bills, :column => [:slug]
    add_index :bills, [:slug]
    remove_index :members, :column => [:slug]
    add_index :members, [:slug]
    remove_index :offices, :column => [:slug]
    add_index :offices, [:slug]
  end
end
