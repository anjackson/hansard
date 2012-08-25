namespace :temp do
  
  desc 'clear people matches, reload reference data and rematch people'
  task :reload_people => [:environment, :reload_people_reference_data, :rematch_people_for_sittings, :populate_people_counts] do 
    puts "Rematched people - don't forget to reindex"
  end
  
  desc 'load people data into db set up for members'
  task :reload_people_reference_data => [:environment] do 
    Constituency.delete_all
    Office.delete_all
    OfficeHolder.delete_all
    ConstituencyAlias.delete_all
    Person.delete_all
    CommonsMembership.delete_all
    Election.delete_all
    AlternativeName.delete_all
    Rake::Task["hop:populate_constituencies"].invoke
    Rake::Task["hop:populate_people"].invoke
    Rake::Task["hop:populate_commons_memberships"].invoke
    Rake::Task["hop:populate_lords_memberships"].invoke
    Rake::Task["hop:populate_elections"].invoke
    Rake::Task["hop:populate_offices"].invoke
    Rake::Task["hop:populate_office_holders"].invoke
    Rake::Task["hop:populate_alternative_names"].invoke
    Rake::Task["commons_library:populate_constituencies"].invoke
    Rake::Task["commons_library:populate_constituency_aliases"].invoke
    Rake::Task["commons_library:populate_people"].invoke
    Rake::Task["commons_library:populate_commons_memberships"].invoke
    Rake::Task["commons_library:populate_lords_memberships_from_file"].invoke
    Rake::Task["commons_library:populate_office_holders"].invoke
  end
  
  parse_processes.times do |index|
    
    task "match_people_#{index}".to_sym => [:environment] do 
      offset = ENV['OFFSET'].to_i.nonzero? || calculate_process_thread_offset(@max_id, parse_processes, index)
      limit = calculate_process_thread_limit(@max_id, parse_processes, index)
      command = "rake RAILS_ENV=#{ENV['RAILS_ENV']} temp:rematch_person_batch OFFSET=#{offset} LIMIT=#{limit}"
      run_in_shell(command, index)
    end
    
    multitask :rematch_people => ["temp:match_people_#{index}"] 
  end
   
  desc 'Match people to contributions'
  task :rematch_people_for_sittings => [:environment] do 
    @max_id = Sitting.count_by_sql("select max(id) as id from sittings")
    Rake::Task['temp:rematch_people'].invoke
  end

  task :rematch_person_batch => [:environment, "solr:disable_save"] do
    if ENV['OFFSET'] and ENV['LIMIT']
      OFFSET = ENV['OFFSET'] 
      LIMIT = ENV['LIMIT']
    else
      puts ''; puts 'usage: rake temp:rematch_person_batch OFFSET=offset LIMIT=limit'; puts ''
    end
    match_people(offset, limit)
  end
  
  task :populate_people_counts => [:environment] do 
    process_people do |person|
      person.contribution_count = person.calculate_contribution_count
      person.membership_count = person.calculate_membership_count
      person.save!
    end
  end
  
  task :fix_zero_start_columns => [:environment] do 
    sittings = Sitting.find_all_by_start_column('0')
    sittings.each do |sitting|
      data_file = sitting.data_file
      doc = data_file.hpricot_doc
      columns = doc.search('col')
      if columns.size > 1
        old_start_column = columns[0].inner_text
        puts "Column was extracted from #{old_start_column}"
        if old_start_column == '0'
          new_start_column = columns[1].inner_text
          puts "Sitting id: #{sitting.id}"
          puts "Setting start column to: #{new_start_column}"
          sitting.start_column = new_start_column
          sitting.save!
        end
      end
    end
  end
  
end