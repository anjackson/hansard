class Consolidated < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    abcs = ActiveRecord::Base.configurations
    
    ActiveRecord::Base.connection.recreate_database(abcs["#{RAILS_ENV}"]["database"])
    ActiveRecord::Base.connection.execute('USE ' + abcs["#{RAILS_ENV}"]["database"])
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
    IO.readlines("db/consolidated.sql").join.split("\n\n").each do |table|
      ActiveRecord::Base.connection.execute(table)
    end
  end

  def self.down
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    abcs = ActiveRecord::Base.configurations
    ActiveRecord::Base.connection.recreate_database(abcs["#{RAILS_ENV}"]["database"])
    ActiveRecord::Base.connection.execute('USE ' + abcs["#{RAILS_ENV}"]["database"])
    ActiveRecord::Base.connection.initialize_schema_migrations_table
  end
end
