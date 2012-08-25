class CreateParserRunTable < ActiveRecord::Migration
  def self.up
    create_table :parser_runs, :force => true do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :parser_runs
  end
end
