class Votes < ActiveRecord::Base; end

class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.string  :type
      t.string  :name
      t.string  :constituency
      t.string  :column
      t.string  :image_src
      t.integer :division_id
    end
  end

  def self.down
    drop_table :votes
  end
end
