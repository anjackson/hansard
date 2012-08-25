namespace :audit do

  def has_left?(attributes, date)
    leaving_reasons = ['died', 'resigned', 'life peerage']
    return false unless attributes[:transition_date] and attributes[:transition_reason]
    transition_date = Date.parse attributes[:transition_date]
    return true if leaving_reasons.include? attributes[:transition_reason].downcase and transition_date < date
    return false
  end

  def display_matches(match_hash, date)
    puts "Complete matches #{match_hash[:complete_matches].size}"
    puts ""
    match_hash[:complete_matches].each do |member, attributes|
      
      firstnames = "#{attributes[:firstnames]} <=> #{member.person.firstname}"
      constituencies = "#{attributes[:constituency]} <=> #{member.constituency.name}"
      p [attributes[:lastname],
         firstnames,
         constituencies].join(' | ')
    end
    puts ""

    puts "Lastname matches #{match_hash[:lastname_matches].size}"
    puts ""
    match_hash[:lastname_matches].each do |member, attributes|
      
      firstnames = "#{attributes[:firstnames]} <=> #{member.person.firstname}"
      constituencies = "#{attributes[:constituency]} <=> #{member.constituency.name}"
      p [attributes[:lastname],
         firstnames,
         constituencies].join(' | ')
    end
    puts ""
    
    puts "Name matches #{match_hash[:name_matches].size}"
    puts ""
    match_hash[:name_matches].each do |member, attributes|
      
      firstnames = "#{attributes[:firstnames]} <=> #{member.person.firstname}"
      constituencies = "#{attributes[:constituency]} <=> #{member.constituency.name}"
      p [attributes[:lastname],
         firstnames,
         constituencies].join(' | ')
    end
    puts ""

    puts "Constituency matches #{match_hash[:constituency_matches].size}"
    puts ""
    match_hash[:constituency_matches].each do |member, attributes|
      
      firstnames = "#{attributes[:firstnames]} <=> #{member.person.firstname}"
      lastnames = "#{attributes[:lastname]} <=> #{member.person.lastname}"
      p [member.constituency.name,
         firstnames, 
         lastnames].join(' | ')
    end
    puts ""

    puts "Unmatched attributes #{match_hash[:unmatched_attributes].size}"
    puts ""

    match_hash[:unmatched_attributes].each do |attributes|
      unless has_left?(attributes, date)
        # find people using the firstname and lastname
        p [attributes[:firstnames],
           attributes[:lastname],
           attributes[:constituency],
           "transition #{attributes[:transition_reason]}"].join(', ')
      end
    end
    puts ""

    puts "Unmatched members #{match_hash[:unmatched_members].size}"
    puts ""
    match_hash[:unmatched_members] = match_hash[:unmatched_members].sort {|a,b| a.person.lastname <=> b.person.lastname}
    match_hash[:unmatched_members].each do |membership|
      p [membership.person.name,
         membership.constituency.name, 
         membership.start_date, 
         membership.end_date].join(', ')
    end
    puts ""

    puts "Possible constituency aliases"
    puts ""
    match_hash[:lastname_matches].each do |member, attributes|
      constituency_alias = attributes[:constituency]
      name = member.constituency.name
      start_date = member.constituency.start_year ? Date.new(member.constituency.start_year) : FIRST_DATE
      end_date = member.constituency.end_year ? Date.new(member.constituency.end_year) : LAST_DATE
      puts [constituency_alias, name, start_date, end_date].join('\t')
    end
    puts ""

  end

  desc 'Find any new commons memberships or people from a source file'
  task :people_from_source_file => :environment do
    unless ENV['FILE']
      puts ''
      puts 'usage: rake audit:people_from_source_file FILE=filename'
      puts ''
      exit 0
    end

    source_file = SourceFile.find_by_name(ENV['FILE'])
    data_file = source_file.header_data_file
    date = source_file.start_date
    puts "Looking for new people in the house from #{date}"

    parser = Hansard::HeaderParser.new(nil, nil, nil)
    member_attributes = parser.extract_members(data_file.hpricot_doc)
    unless member_attributes.size > 600
      puts "Not enough members found: #{member_attributes.size}"
      exit 0
    end
    puts "Got #{member_attributes.size} members from header"
    match_hash = CommonsMembership.find_matches_on_date(date, member_attributes)
    
    display_matches(match_hash, date)
  end

  desc 'Check commons membership counts against total seat data'
  task :check_commons_membership_counts => :environment do
    seats_info = []
    File.new("#{RAILS_ROOT}/reference_data/seats.txt").each do |line|
      attributes = parse_seats_line(line)
      start_year = attributes[:dates].split('-').first.to_i
      start_year = FIRST_DATE.year if start_year < FIRST_DATE.year
      seats_info << [start_year, attributes[:seats]]
    end
   
    puts "Year\tSeats\tKnown Members in Seats\tDifference"
    FIRST_DATE.year.upto(LAST_DATE.year) do |year|
      test_date = Date.new(year, 12, 31)
      commons_membership_count = CommonsMembership.count_on_date(test_date)
      expected_seats = seats_for_year(seats_info, year)
      puts "#{year}\t#{expected_seats}\t#{commons_membership_count}\t#{expected_seats - commons_membership_count}"
    end
    
  end
  
  desc 'Check lords membership counts against total seat data'
  task :check_lords_membership_counts => :environment do
    seats_info = []
   
    puts "Year\tSeats\tKnown Members in Seats\tDifference"
    FIRST_DATE.year.upto(LAST_DATE.year) do |year|
      test_date = Date.new(year, 12, 31)
      lords_membership_count = LordsMembership.count_on_date(test_date)
      puts "#{year}\tUnknown\t#{lords_membership_count}\tUnknown"
    end
    
  end
  
  def parse_seats_line line
    d = line.split("\t")
    atts = { :dates => d[0],
             :seats => d[1].to_i }
  end

  desc 'Audit the possibly incorrectly dated xml files'
  task :dates => :environment do
    puts "Problem\tSuggested\tExtracted\tOriginal"
    SourceFile.find(:all).each do |source_file|
      next unless source_file.log
      source_file.log.each_line do |problem|
        if problem.starts_with?('Bad date')
          date_info = /format="(.*)">(.*)<\/date>\s*Suggested date: (.*)/.match(problem)
          if date_info
            extracted_date = date_info[1]
            original_date = date_info[2]
            suggested_date = date_info[3]
            puts "Bad date extraction\t#{suggested_date}\t#{extracted_date}\t#{original_date}\n"
          else
            puts "#{problem}\t\t\t\n"
          end
        end
      end
    end
  end

  def split
   @splitter = Hansard::Splitter.new((overwrite=true), true)
    per_source_file do |file|
      source_file = split_file file
    end
  end

  desc 'Audit source XML for possible problems'
  task :source_xml => :environment do
    split
    columns = ["File",
               "Missing columns",
               "Missing images",
               "Bad dates",
               "Missing session tag",
               "Bad session tag",
               "Unusual content in Oral Questions",
               "> 90 day gap between dates",
               "Dates outside session"]
    puts columns.join("\t")
    SourceFile.find(:all).each do |source_file|
      missing_cols = source_file.missing_columns.join(', ')
      missing_images = source_file.missing_images.join(', ')
      bad_dates = source_file.bad_dates.join(', ')
      missing_session = source_file.missing_session_tag? ? "yes" : ""
      bad_session = source_file.bad_session_tag
      oq_content = source_file.bad_oralquestions_content.join(', ')
      date_gaps = source_file.large_gaps_between_dates.join(', ')
      dates_outside_session = source_file.dates_outside_session.join(', ')
      values = [source_file.name,
                missing_cols,
                missing_images,
                bad_dates,
                missing_session,
                bad_session,
                oq_content,
                date_gaps,
                dates_outside_session]

      puts values.join("\t")
    end
  end

  def add_volume_to_series source_file, series_hash
    filename = File.basename(source_file, '.xml')
    volume_info = SourceFile.info_from_filename(filename)
    series_id = volume_info[:series].to_s
    series_id += volume_info[:house].at(0).upcase unless volume_info[:house] == 'both'
    series_hash[series_id] << [volume_info[:volume], volume_info[:part]]
  end

  def show_missing_volumes expected, volumes_present
    volumes_found = volumes_present.select{|volume, part| volume == expected }
    if volumes_found.empty?
      puts "Missing Volume #{expected}"
      @missing_count += 1
    end
    if volumes_found.size == 1 and volumes_found.first[1] == 2
      puts "Missing Volume #{expected} Part 1"
      @missing_count += 1
    end
    if volumes_found.size == 1 and volumes_found.first[1] == 1
      puts "Missing Volume #{expected} Part 2"
      @missing_count += 1
    end

  end

  desc 'Produce a list of missing volumes for a directory of source XML'
  task :volumes => :environment do
    unless ENV['DIR']
      puts ''
      puts 'usage: rake audit:volumes DIR=directory_path'
      puts ''
      exit 0
    end

    directory = ENV['DIR']
    series_hash = {}
    all_series = Series.find(:all)
    all_series.each { |series| series_hash[series.id_hash[:series]] = [] }
    Dir.glob(directory + "/*.xml").each { |source_file| add_volume_to_series source_file, series_hash }

    @missing_count = 0
    all_series.each do |series|
      puts series.name
      series_id = series.id_hash[:series]
      volumes_present = series_hash[series_id]
      volumes_expected = Range.new(1, series.last_volume)
      volumes_expected.each { |expected| show_missing_volumes expected, volumes_present }
    end
    puts "Total missing: #{@missing_count}"
  end

end
