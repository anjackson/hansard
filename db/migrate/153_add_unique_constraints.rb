class AddUniqueConstraints < ActiveRecord::Migration
  def self.up
    add_index :acts, [:name, :year], :unique => true
    add_index :bills, [:name, :number], :unique => true
    remove_index :members, :column => [:name]
    add_index :members, [:name], :unique => true
    add_index :parties, [:name], :unique => true
    remove_index :offices, :column => [:name]
    add_index :offices, [:name], :unique => true
  end

  def self.down
    remove_index :offices, :column => [:name]
    add_index :offices, [:name]
    remove_index :parties, :column => [:name]
    remove_index :members, :column => [:name]
    add_index :members, [:name]
    remove_index :bills, :column => [:name, :number]
    remove_index :acts, :column => [:name, :year]
  end
end
