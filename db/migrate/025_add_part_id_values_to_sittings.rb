class AddPartIdValuesToSittings < ActiveRecord::Migration
  def self.up
    Sitting.find(:all).each do |sitting|
      if /part_(\d+)/.match sitting.data_file.name
        sitting.part_id = $1
      else  
        sitting.part_id = 1
      end
      sitting.save!
    end
  end

  def self.down
    Sitting.find(:all).each do |sitting|
      sitting.part_id = nil
      sitting.save!
    end
  end
end
