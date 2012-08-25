class UpdateUniqueConstraintOnLordsMemberships < ActiveRecord::Migration
  
  def self.up
    remove_index :lords_memberships, :name => :lords_memberships_unique_fields
    add_index :lords_memberships, [:person_id, :degree, :title, :number, :start_date], :name => :lords_memberships_unique_fields, :unique => true
  end

  def self.down
  end
  
end
