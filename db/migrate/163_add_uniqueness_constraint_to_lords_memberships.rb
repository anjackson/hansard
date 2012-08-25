class AddUniquenessConstraintToLordsMemberships < ActiveRecord::Migration
  def self.up
    add_index :lords_memberships, [:person_id, :degree, :title, :number], :name => :lords_memberships_unique_fields, :unique => true
  end

  def self.down

    remove_index :lords_memberships, :name => :lords_memberships_unique_fields
  end
end
