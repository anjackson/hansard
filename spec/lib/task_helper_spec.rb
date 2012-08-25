require File.dirname(__FILE__) + '/../spec_helper'

describe "TaskHelper" do 

  before :all do
    self.class.send(:include, TaskHelper)
  end
  
  describe "generally" do

    it 'should respond to "populate_table_from_sql_file"' do
      self.respond_to?(:populate_table_from_sql_file).should be_true
    end

    it 'should populate a table from a sql file' do
      TIMINGS = []
      stub!(:puts)
      test_db_config = {'test' => {'username' => 'test',
                                   'password' => 'passwd',
                                   'database' => 'test_database'}}
      Contribution.stub!(:configurations).and_return(test_db_config)
      should_receive(:system).with("mysql -u test -ppasswd  test_database < #{RAILS_ROOT}/reference_data/hop_data/contributions.sql")
      populate_table_from_sql_file("Contribution", 'hop_data')
    end
    
    it 'should respond to "dump_table_to_sql_file"' do 
      self.respond_to?(:dump_table_to_sql_file).should be_true
    end
    
    it 'should be able to dump a table to a sql file' do 
      stub!(:puts)
      test_db_config = {'test' => {'username' => 'test',
                                   'password' => 'passwd',
                                   'database' => 'test_database'}}
      Contribution.stub!(:configurations).and_return(test_db_config)
      should_receive(:system).with("mysqldump -u test -ppasswd  test_database contributions > #{RAILS_ROOT}/reference_data/hop_data/contributions.sql")
      dump_table_to_sql_file("Contribution", 'hop_data')
    end

  end

  describe "when cleaning data" do
    
    it 'should return 1865 for the year "1865"' do
      clean_year("1865").should == 1865
    end

    it 'should return nil for a blank year' do
      clean_year("").should be_nil
    end

    it 'should return 2003-05-06 for U.K. format date "06/05/2003"' do
      clean_date('06/05/2003').should == Date.new(2003, 5, 6)
    end

    it 'should return nil for a blank date' do
      clean_date('').should be_nil
    end

    it 'should return "abc" for text ""abc""' do
      clean_text('"abc"').should == 'abc'
    end

    it 'should return empty text for empty text' do
      clean_text('').should == ''
    end

  end

  describe "when processing models" do

    it 'should print an exception string and backtrace if an exception occurs' do
      stub!(:puts)
      contribution = mock_model(Contribution)
      Contribution.stub!(:find).with(:all, :conditions => ["id > ?", contribution.id], :limit => 300).and_return([])
      Contribution.stub!(:find).with(:all, :conditions => ["id > ?", 0], :limit => 300).and_return([contribution])
      exception = Exception.new("A test exception")
      exception.stub!(:backtrace).and_return("backtrace")

      should_receive(:puts).with('A test exception')
      should_receive(:puts).with('backtrace')
      should_receive(:puts).with('continuing ...')

      process_model(Contribution, "id > ?", 300){ |contribution| raise exception }
    end

    it 'should ask for instances of the model using the condition and limit' do
      stub!(:puts)
      Contribution.should_receive(:find).with(:all, :conditions => ["id > ?", 0], :limit => 300).and_return([])
      process_model(Contribution, "id > ?", 300)
    end

    it 'should yield instances of the model to the caller\'s block' do
      stub!(:puts)
      contribution = mock_model(Contribution)
      Contribution.stub!(:find).with(:all, :conditions => ["id > ?", contribution.id], :limit => 300).and_return([])
      Contribution.stub!(:find).with(:all, :conditions => ["id > ?", 0], :limit => 300).and_return([contribution])
      contribution.should_receive(:test)
      process_model(Contribution, "id > ?", 300) do |contribution|
        contribution.test
      end
    end

  end

  describe "when processing models" do

    before :each do
      @models = []
      @condition = "test condition"
    end

    def expect_process_model(model_class, condition)
      should_receive(:process_model).with(model_class, condition).and_yield(mock_model(model_class))
    end

    it 'should yield contributions when given a condition and a block and asked to process contributions' do
      expect_process_model(Contribution, @condition)
      process_contributions(@condition){ |model_instance| @models << model_instance }
      @models.size.should == 1
    end

    it 'should yield sections when given a condition and a block and asked to process sections' do
      expect_process_model(Section, @condition)
      process_sections(@condition){ |model_instance| @models << model_instance }
      @models.size.should == 1
    end

    it 'should yield divisions when given a condition and a block and asked to process divisions' do
      expect_process_model(Division, @condition)
      process_divisions(@condition){ |model_instance| @models << model_instance }
      @models.size.should == 1
    end

    it 'should yield sittings and set a default batch size of 20 when given a condition and a block and asked to process sittings' do
      should_receive(:process_model).with(Sitting, @condition, 20).and_yield(mock_model(Sitting))
      process_sittings(@condition){ |model_instance| @models << model_instance }
      @models.size.should == 1
    end

    it 'should yield offices when given a condition and a block and asked to process offices' do
      expect_process_model(Office, @condition)
      process_offices(@condition){ |model_instance| @models << model_instance }
      @models.size.should == 1
    end

  end
  
  describe 'when matching people' do 
  
    it 'should ask for sittings with an id greater than the offset and less than or equal to the limit' do 
      should_receive(:process_sittings).with("id > 19 and id <= 20 and id > ?")
      match_people(19, 20)
    end
    
  end
  
  describe 'when calculating the offset to use in processing records in a process thread' do 
    
    it 'should return 1 for process 0 of 4 with max_id of 19' do 
      calculate_process_thread_offset(19, 4, 0).should == 0
    end
    
    it 'should return 4 for process 1 of 4 with max_id of 19' do 
      calculate_process_thread_offset(19, 4, 1).should == 4
    end
    
    it 'should return 8 for process 2 of 4 with max_id of 19' do 
      calculate_process_thread_offset(19, 4, 2).should == 8
    end
    
    it 'should return 12 for process 3 of 4 with max_id of 19' do 
      calculate_process_thread_offset(19, 4, 3).should == 12
    end
    
  end

  describe 'when calculating the limit to use in processing records in a process thread' do 
  
    it 'should return 4 for process 0 of 4 with max_id of 19' do 
      calculate_process_thread_limit(19, 4, 0).should == 4
    end
    
    it 'should return 8 for process 1 of 4 with max_id of 19' do 
      calculate_process_thread_limit(19, 4, 1).should == 8
    end
    
    it 'should return 12 for process 2 of 4 with max_id of 19' do 
      calculate_process_thread_limit(19, 4, 2).should == 12
    end
    
    it 'should return 19 for process 3 of 4 with max_id of 19' do
      calculate_process_thread_limit(19, 4, 3).should == 19
    end
    
  end

  describe " when creating parliament sessions from attributes" do

    before :all do
      @attribute_list = [{:session_start_year => 1901,
                          :session_end_year   => 1902,
                          :source_file_name   => 'S40001P0'}]
    end

    it 'should find or create a parliament session by start and end year for every line' do
      ParliamentSession.should_receive(:find_or_create_by_start_year_and_end_year).with(1901, 1902)
      create_parliament_sessions_from_attributes(@attribute_list)
    end

    it 'should set the session on the volume extracted from the data file, if that data file has been loaded' do
      parliament_session = mock_model(ParliamentSession)
      ParliamentSession.stub!(:find_or_create_by_start_year_and_end_year).and_return(parliament_session)
      volume = mock_model(Volume)
      source_file = mock_model(SourceFile, :volume => volume)
      SourceFile.stub!(:find_by_name).with('S40001P0').and_return(source_file)
      volume.should_receive(:update_attribute).with(:parliament_session_id, parliament_session.id)
      create_parliament_sessions_from_attributes(@attribute_list)
    end

  end

  describe " when parsing lines from a parliament sessions file" do

    it 'should correctly create a hash of attributes for a multi-year session' do
      line = "Parliamentary Debates	Commons & Lords	1803 - Feb 1820	1	1		S1V0001P0	1803-1804"
      attributes = { :source_file_name      => 'S1V0001P0',
                     :session_start_year    => 1803,
                     :session_end_year      => 1804}
      parse_parliament_session_line(line).should == attributes
    end

    it 'should correctly create a hash of attributes for a single year session' do
      line = "Parliamentary Debates	Commons & Lords	1803 - Feb 1820	1	1		S1V0001P0	1803"
      attributes = { :source_file_name      => 'S1V0001P0',
                     :session_start_year    => 1803,
                     :session_end_year      => 1803}
      parse_parliament_session_line(line).should == attributes
    end

  end
  
  describe 'when parsing lines from a peerage file' do 
    
    it 'should correctly create a hash of attributes' do 
      line = '2	9	3rd	Baron	Abercromby	3rd Baron Abercromby	Hereditary	1843		1866	1866-02-11'
      attributes = {:import_id        => 2, 
                    :person_import_id => 9, 
                    :number           => "3rd",
                    :degree           => "Baron", 
                    :title            => 'Abercromby', 
                    :name             => "3rd Baron Abercromby", 
                    :membership_type  => 'Hereditary', 
                    :start_year       => 1843, 
                    :start_date       => nil, 
                    :end_year         => 1866,
                    :end_date         => Date.new(1866, 2, 11)}
      parse_peerage_line(line).should == attributes
    end
    
  end
  
  describe 'when parsing lines from a HoPT peerage file' do 
  
    it 'should correctly create a hash of attributes' do 
      line = '2	9	"3rd"	"Baron"	"Abercromby"	"3rd Baron Abercromby"	"Hereditary"	"1843"'	
      attributes = {:import_id        => 2, 
                    :person_import_id => 9, 
                    :number           => "3rd",
                    :degree           => "Baron", 
                    :title            => 'Abercromby', 
                    :name             => "3rd Baron Abercromby", 
                    :type             => 'Hereditary', 
                    :year             => 1843}
      parse_hop_peerage_line(line).should == attributes     
    end
  
  end
  
  describe 'when getting peerage attributes' do 

    before do   
      stub!(:puts)
      @data_source = mock_model(DataSource)
      @person = mock_model(Person, :id => 233, :date_of_death => Date.new(1922, 3, 4), :estimated_date_of_death => true)
      Person.stub!(:find_by_import_id).and_return(@person)
      @line = "461	2474	26th	Earl of	Crawford and Balcarres	26th Earl of Crawford and Balcarres	Hereditary	1880"
    end
    
    it 'should parse the line into attributes' do 
      should_receive(:parse_peerage_line).with(@line).and_return({})
      get_peerage_attributes(@line, @data_source)
    end

    it 'should return nil attributes parsed have no start year' do 
      stub!(:parse_peerage_line).and_return({})
      get_peerage_attributes(@line, @data_source).should == [nil, nil]
    end
    
    it 'should create an estimated start date from the start year' do 
      stub!(:parse_peerage_line).and_return({:start_year => 'test'})
      stub!(:estimate_date).and_return({:start_date => Date.new(2001, 1, 1)})
      should_receive(:estimate_date).with({:start_year => 'test'}, :start_date, :start_year, :estimated_start_date, true).and_return({})
      get_peerage_attributes(@line, @data_source)
    end
    
    it 'should create an estimated end date from the end year' do 
      stub!(:parse_peerage_line).and_return({:start_year => 'test'})
      stub!(:estimate_date).and_return({:end_year => 'test'})
      should_receive(:estimate_date).with({:end_year => 'test'}, :end_date, :end_year, :estimated_end_date, false).and_return({:start_date => Date.new(2001, 1, 1)})
      get_peerage_attributes(@line, @data_source)
    end
    
    it 'should ask for a person by import id' do 
      Person.should_receive(:find_by_import_id).with(2474)
      get_peerage_attributes(@line, @data_source)
    end

  end

  
  describe 'when creating an alternative title from a line of data' do 
  
    before do 
      @data_source = mock_model(DataSource)
      @attributes = { :import_id => 461,
                     :person_id =>  233, 
                     :number    => '26th', 
                     :degree    => 'Earl of',
                     :estimated_start_date => true,
                     :start_date => Date.new(1880, 1, 1),
                     :estimated_end_date => true, 
                     :end_date  => Date.new(1922, 3, 4),
                     :title     => 'Crawford and Balcarres', 
                     :name      => '26th Earl of Crawford and Balcarres', 
                     :membership_type => 'Peerage of Scotland', 
                     :data_source_id => @data_source.id}
      stub!(:get_peerage_attributes).and_return([nil, @attributes])
    end
    
    it 'should ask for the peerage attributes' do 
      should_receive(:get_peerage_attributes)
      create_alternative_title_from_line(@line, @data_source)
    end
    
    it 'should not create a lords membership if the person cannot be found' do 
      AlternativeTitle.should_not_receive(:create!)
      create_alternative_title_from_line(@line, @data_source)
    end

    it 'should update an existing lords membership if one is found' do 
      stub!(:get_peerage_attributes).and_return([mock_model(Person), @attributes])
      title = mock_model(AlternativeTitle)
      AlternativeTitle.stub!(:find).and_return(title)
      title.should_receive(:update_attributes).with(@attributes)
      create_alternative_title_from_line(@line, @data_source)
    end

    it 'should correctly create a lords membership from a line' do 
      stub!(:get_peerage_attributes).and_return([mock_model(Person), @attributes])
      AlternativeTitle.should_receive(:create!).with(@attributes)
      create_alternative_title_from_line(@line, @data_source)
    end
    
    it 'should set the title type of the alternative title to the membership type parsed' do 
      stub!(:get_peerage_attributes).and_return([mock_model(Person), @attributes])
      AlternativeTitle.stub!(:create!).with(@attributes)
      create_alternative_title_from_line(@line, @data_source)
      @attributes[:title_type].should == 'Peerage of Scotland'
    end

  end
  
  describe 'when creating a lords membership from a line of data' do 
  
    before do 
      @data_source = mock_model(DataSource)
      @attributes = { :import_id => 461,
                     :person_id =>  233, 
                     :number    => '26th', 
                     :degree    => 'Earl of',
                     :estimated_start_date => true,
                     :start_date => Date.new(1880, 1, 1),
                     :estimated_end_date => true, 
                     :end_date  => Date.new(1922, 3, 4),
                     :title     => 'Crawford and Balcarres', 
                     :name      => '26th Earl of Crawford and Balcarres', 
                     :membership_type => 'Hereditary', 
                     :data_source_id => @data_source.id}
      stub!(:get_peerage_attributes).and_return([nil, @attributes])
    end
    
    it 'should ask for the peerage attributes' do 
      should_receive(:get_peerage_attributes)
      create_lords_membership_from_line(@line, @data_source)
    end
    
    it 'should not create a lords membership if the person cannot be found' do 
      LordsMembership.should_not_receive(:create!)
      create_lords_membership_from_line(@line, @data_source)
    end

    it 'should update an existing lords membership if one is found' do 
      stub!(:get_peerage_attributes).and_return([mock_model(Person), @attributes])
      membership = mock_model(LordsMembership)
      LordsMembership.stub!(:find).and_return(membership)
      membership.should_receive(:update_attributes).with(@attributes)
      create_lords_membership_from_line(@line, @data_source)
    end

    it 'should correctly create a lords membership from a line' do 
      stub!(:get_peerage_attributes).and_return([mock_model(Person), @attributes])
      LordsMembership.should_receive(:create!).with(@attributes)
      create_lords_membership_from_line(@line, @data_source)
    end

  end

  describe " when parsing lines from a library office holder file" do
    
    it 'should correctly create a hash of attributes' do
      line = "1960-07-27	1963-10-19	E. Heath	Lord Privy Seal	"
      attributes = { :start_date => Date.new(1960, 7, 27),
                     :end_date => Date.new(1963, 10, 19),
                     :holder => 'E. Heath',
                     :office => 'Lord Privy Seal',
                     :updated_on => nil }
      parse_library_office_holder_line(line).should == attributes
    end

  end

  describe "TaskHelper", " when loading lines from a file" do

    before :each do
      @lines = [1, 2, 3, 4, 5]
      File.stub!(:new).and_return(@lines)
      @data_source = mock_model(DataSource)
    end

    it 'should create a person from every line in a person file' do
      @lines.each{ |line| should_receive(:create_person_from_line).with(line, @data_source) }
      load_people_from_file '', '', @data_source
    end

    it 'should create an office holder from every line in an office holder file' do
      @lines.each{ |line| should_receive(:create_office_holder_from_line).with(line, @data_source) }
      load_office_holders_from_file '', '', @data_source
    end

    it 'should create a commons membership from every line in a commons membership file' do
      @lines.each{ |line| should_receive(:create_commons_membership_from_line).with(line, @data_source) }
      load_commons_memberships_from_file '', '', @data_source
    end
    
    it 'should create an alternative title from every line in a commons membership file' do
      @lines.each{ |line| should_receive(:create_alternative_title_from_line).with(line, @data_source) }
      load_alternative_titles_from_file '', '', @data_source
    end

    it 'should create a constituency from every line in a constituency file' do
      @lines.each{ |line| should_receive(:create_constituency_from_line).with(line, @data_source) }
      load_constituencies_from_file '', '', @data_source
    end
  
    it 'should parse attributes from each line (except the header) in a parliament sessions file' do
      stub!(:create_parliament_sessions_from_attributes)
      @lines[1..@lines.size].each{ |line| should_receive(:parse_parliament_session_line).with(line) }
      load_parliament_sessions_from_file '', '', @data_source
    end

    it 'should create parliament sessions using the attributes parsed from a parliament sessions file' do
      stub!(:parse_parliament_session_line).and_return("a")
      should_receive(:create_parliament_sessions_from_attributes).with(["a", "a", "a", "a"])
      load_parliament_sessions_from_file '', '', @data_source
    end

  end

  describe "when parsing constituencies from a line of data" do 
  
    it 'should correctly create a hash of attributes' do 
      line = "339	Inverness East, Nairn and Lochaber	1997	2005"
      attributes = { :import_id  => 339,
                     :name       => "Inverness East, Nairn and Lochaber",
                     :start_year => 1997,
                     :end_year   =>	2005 }
      parse_constituencies_line(line).should == attributes
    end
  
  end
  
  describe "when creating a constituency model from a line of data" do 

    before do 
      Constituency.stub!(:create!)
      @data_source = mock_model(DataSource)
      @line = "339	Inverness East, Nairn and Lochaber	1997	2005"
      @attributes = { :name => "Inverness East, Nairn and Lochaber", 
                     :start_year => 1997,
                     :end_year => 2005, 
                     :import_id => 339, 
                     :data_source_id => @data_source.id}
    end

    it 'should parse the line into attributes' do 
      should_receive(:parse_constituencies_line).with(@line).and_return({})
      create_constituency_from_line(@line, @data_source)
    end
  
    it 'should correctly create a constituency from a line' do  
      Constituency.should_receive(:create!).with(@attributes)
      create_constituency_from_line(@line, @data_source)
    end
  
    it 'should not create a constituency for a constituency whose name is [Constituency unknown]' do 
      line = "1948	[Constituency unknown]"
      Constituency.should_not_receive(:create!)
      create_constituency_from_line(line, @data_source)
    end
  
    it 'should set the area type for a constituency like "Carlow [county]"' do 
      line = "1949	Carlow [county]	1832	1922"
      attributes = { :name => "Carlow", 
                     :area_type => "county", 
                     :start_year => 1832, 
                     :end_year => 1922, 
                     :import_id => 1949, 
                     :data_source_id => @data_source.id }
      Constituency.should_receive(:create!).with(attributes)
      create_constituency_from_line(line, @data_source)    
    end
  
    it 'should set the region for a constituency "Newport [Shropshire]"' do 
      line = "1954	Newport [Shropshire]	1885	1918"
      attributes = { :name => "Newport", 
                     :region => "Shropshire", 
                     :import_id => 1954, 
                     :start_year => 1885, 
                     :end_year => 1918, 
                     :data_source_id => @data_source.id }
      Constituency.should_receive(:create!).with(attributes)
      create_constituency_from_line(line, @data_source)
    end
  
    it 'should update an existing constituency if one exists with the same import id rather than creating a new constituency' do 
      existing_constituency = mock_model(Constituency, :update_attributes => true)
      Constituency.stub!(:find_by_import_id).and_return(existing_constituency)
      existing_constituency.should_receive(:update_attributes).with(@attributes)
      create_constituency_from_line(@line, @data_source)
    end
  
  end

  describe " when creating a commons membership model from a line of data" do

    before do
      @data_source = mock_model(DataSource)
      @membership_line = "7768	7779	1258	1929	1929-05-30	1	1945	1945-07-05	1"
      @attributes = { :import_id               => 7768,
                     :person_import_id        => 7779,
                     :constituency_import_id  => 1258,
                     :start_year              => 1929,
                     :start_date              => Date.new(1929, 5, 30),
                     :end_year                => 1945,
                     :end_date                => Date.new(1945, 7, 5) }
      stub!(:parse_members_line).and_return(@attributes)
      @constituency = mock_model(Constituency)
      Constituency.stub!(:find_by_import_id).and_return @constituency
      @person = mock_model(Person)
      Person.stub!(:find_by_import_id).and_return @person
      CommonsMembership.stub!(:create)
      @expected_attributes = { :import_id => 7768,
                               :person_id => @person.id,
                               :constituency_id => @constituency.id,
                               :data_source_id => @data_source.id,
                               :start_date => Date.new(1929, 5, 30),
                               :end_date => Date.new(1945, 7, 5),
                               :estimated_start_date=>false,
                               :estimated_end_date=>false
                             }
    end

    it 'should correctly create a hash of attributes from a line' do
      parse_members_line(@membership_line).should == @attributes
    end

    it 'should not create a membership if the start date is after the last date defined in the application' do
      stub!(:parse_members_line).and_return(:start_date => LAST_DATE + 1)
      CommonsMembership.should_not_receive(:create)
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should ask for the person and constituency for this membership by their import ids' do
      Person.should_receive(:find_by_import_id).with(@attributes[:person_import_id])
      Constituency.should_receive(:find_by_import_id).with(@attributes[:constituency_import_id])
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should not create a membership if the person is not found' do
      Person.stub!(:find_by_import_id).and_return nil
      CommonsMembership.should_not_receive(:create)
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should not create a membership if the constituency is not found' do
      Constituency.stub!(:find_by_import_id).and_return nil
      CommonsMembership.should_not_receive(:create)
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should create a membership model with start date estimated from start year if not available' do
      stub!(:estimate_date).and_return(@attributes)
      should_receive(:estimate_date).with(@attributes,
                                          :start_date,
                                          :start_year,
                                          :estimated_start_date,
                                          start=true).and_return({})
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should create a membership model with end date estimated from end year if not available' do
      stub!(:estimate_date).and_return(@attributes)
      should_receive(:estimate_date).with(@attributes,
                                          :end_date,
                                          :end_year,
                                          :estimated_end_date,
                                          start=false).and_return({})
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should look for an existing commons membership with the same person, constituency and start date or end date ' do
      CommonsMembership.should_receive(:find).with(:first, 
                                                   :conditions => ['person_id = ? and constituency_id = ? and (start_date = ? or end_date = ?)', 
                                                                   @person.id, @constituency.id, Date.new(1929, 5, 30), Date.new(1945, 7, 5)])
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should update the attributes of the existing commons membership if one exists' do
      commons_membership = mock_model(CommonsMembership)
      CommonsMembership.stub!(:find).and_return(commons_membership)
      commons_membership.should_receive(:update_attributes).with(@expected_attributes)
      create_commons_membership_from_line(@membership_line, @data_source)
    end

    it 'should create a membership model for the person, constituency and data source if none exists' do
      CommonsMembership.stub!(:find).and_return(nil)
      CommonsMembership.should_receive(:create).with(@expected_attributes)
      create_commons_membership_from_line(@membership_line, @data_source)
    end

  end

  describe " when parsing lines from a file describing people" do

    it 'should correctly create a hash of attributes (mapping "exact date" booleans to their opposite as "estimated date")' do
      person_line = "1782	Robert Uniake	Robert	Penrose-Fitzgerald	Sir	1839		FALSE	1919	1919-07-10	TRUE"
      attributes = { :import_id => 1782,
                     :full_firstnames => "Robert Uniake",
                     :firstname => "Robert",
                     :lastname => "Penrose-Fitzgerald",
                     :honorific => "Sir",
                     :year_of_birth => 1839,
                     :date_of_birth => nil,
                     :estimated_date_of_birth => true,
                     :year_of_death => 1919,
                     :date_of_death => Date.new(1919, 7, 10),
                     :estimated_date_of_death => false }
      parse_people_line(person_line).should == attributes
    end

  end

  describe "when estimating dates" do

    before :each do
      @data_source = mock_model(DataSource)
    end

    it 'should estimate a start date as the first of the year if the real date is not available and set the estimation flag' do
      attributes = { :year_of_birth => 1839 }
      expected = { :date_of_birth => Date.new(1839, 1, 1),
                   :estimated_date_of_birth => true }
      estimate_date(attributes, :date_of_birth, :year_of_birth, :estimated_date_of_birth, start=true).should == expected
    end

    it 'should set the estimation flag to false if the exact start date is available' do
      attributes = { :year_of_birth => 1839,
                     :date_of_birth => Date.new(1839, 6, 5) }
      expected = { :date_of_birth => Date.new(1839, 6, 5),
                   :estimated_date_of_birth => false }
      estimate_date(attributes, :date_of_birth, :year_of_birth, :estimated_date_of_birth, start=true).should == expected
    end

    it 'should estimate a end date as the end of the year if the real date is not available and set the estimation flag' do
      attributes = { :year_of_death => 1839 }
      expected = { :date_of_death => Date.new(1839, 12, 31),
                   :estimated_date_of_death=> true }
      estimate_date(attributes, :date_of_death, :year_of_death, :estimated_date_of_death, start=false).should == expected
    end

    it 'should set the estimation flag to false if the exact end date is available' do
      attributes = { :year_of_death => 1839,
                     :date_of_death => Date.new(1839, 6, 5) }
      expected = { :date_of_death => Date.new(1839, 6, 5),
                   :estimated_date_of_death => false }
      estimate_date(attributes, :date_of_death, :year_of_death, :estimated_date_of_death, start=false).should == expected
    end

  end

  describe " when creating a person model from a line of data" do

    before :each do
      @data_source = mock_model(DataSource)
      stub!(:parse_people_line).and_return({})
      stub!(:estimate_date).and_return({})
      Person.stub!(:create!)
    end

    it 'should create a person model with birth date estimated from years if not available' do
      should_receive(:estimate_date).with({}, :date_of_birth, :year_of_birth, :estimated_date_of_birth, start=true).and_return({})
      create_person_from_line('', @data_source)
    end

    it 'should create a person model with dates estimated from years, where there is no know date of death but a year of death is provided' do
      should_receive(:estimate_date).with({}, :date_of_death, :year_of_death, :estimated_date_of_death, start=false).and_return({})
      create_person_from_line('', @data_source)
    end

  end

  describe " when getting an office start date from a year " do
    
    it 'should return the first of the year if the office is not a cabinet office' do
      office_start_date_from_year(1955, false).should == Date.new(1955, 1, 1)
    end

    it 'should return the date of the election that year if the office is a cabinet office and there is only one election that year' do
      election = mock_model(Election, :date => Date.new(1955, 12, 23))
      Election.stub!(:find).with(:all, :conditions => ['YEAR(date) = ?', 1955]).and_return([election])
      office_start_date_from_year(1955, true).should == Date.new(1955, 12, 23)
    end

    it 'should return the first of the year if the office is a cabinet office and there is more than one election that year' do
      election_one = mock_model(Election, :date => Date.new(1955, 6, 5))
      election_two = mock_model(Election, :date => Date.new(1955, 12, 23))
      Election.stub!(:find).with(:all, :conditions => ['YEAR(date) = ?', 1955]).and_return([election_one, election_two])
      office_start_date_from_year(1955, true).should == Date.new(1955, 1, 1)
    end

    it 'should return the first of the year if the office is a cabinet office and there are no elections that year' do
      Election.stub!(:find).with(:all, :conditions => ['YEAR(date) = ?', 1955]).and_return([])
      office_start_date_from_year(1955, true).should == Date.new(1955, 1, 1)
    end

  end

  describe " when getting an office end date from a year " do


    it 'should return the last of the year if the office is not a cabinet office' do
      office_end_date_from_year(1955, false).should == Date.new(1955, 12, 31)
    end

    it 'should return the date of the dissolution for the election that year if the office is a cabinet office and there is only one election that year' do
      election = mock_model(Election, :dissolution_date => Date.new(1955, 12, 23))
      Election.stub!(:find).with(:all, :conditions => ['YEAR(dissolution_date) = ?', 1955]).and_return([election])
      office_end_date_from_year(1955, true).should == Date.new(1955, 12, 23)
    end

    it 'should return the last of the year if the office is a cabinet office and there is more than one election that year' do
      election_one = mock_model(Election, :dissolution_date => Date.new(1955, 6, 5))
      election_two = mock_model(Election, :dissolution_date => Date.new(1955, 12, 23))
      Election.stub!(:find).with(:all, :conditions => ['YEAR(dissolution_date) = ?', 1955]).and_return([election_one, election_two])
      office_end_date_from_year(1955, true).should == Date.new(1955, 12, 31)
    end

    it 'should return the last of the year if the office is a cabinet office and there are no elections that year' do
      Election.stub!(:find).with(:all, :conditions => ['YEAR(dissolution_date) = ?', 1955]).and_return([])
      office_end_date_from_year(1955, true).should == Date.new(1955, 12, 31)
    end

  end

  def office_holder_line
    "2998	105	1981-1983"
  end

  describe " when parsing an office holders line " do

    it 'should correctly create a hash of attributes' do
      attributes = { :person_import_id => 2998,
                     :office_import_id => 105,
                     :dates => '1981-1983' }
      parse_office_holders_line(office_holder_line).should == attributes
    end

  end

  describe " when creating an office holder model from a line" do

    before :each do
      @data_source = mock_model(DataSource)
      OfficeHolder.stub!(:create!)
      @person = mock_model(Person)
      @office = mock_model(Office, :cabinet => false)
      Person.stub!(:find_by_import_id).and_return(@person)
      Office.stub!(:find_by_import_id).and_return(@office)
      stub!(:years_from_dates).and_return([[1981, 1983]])
      @expected_attributes = { :estimated_end_date => true,
                               :end_date => Date.new(1983, 12, 31),
                               :office_id => @office.id,
                               :confirmed => true,
                               :data_source_id => @data_source.id,
                               :person_id => @person.id,
                               :estimated_start_date => true,
                               :start_date => Date.new(1981, 1, 1) }
    end

    it 'should get a start and end year from the dates string' do
      should_receive(:years_from_dates).and_return([[1981, 1983]])
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should ask for the person and office referenced using their import ids' do
      Person.should_receive(:find_by_import_id).with(2998)
      Office.should_receive(:find_by_import_id).with(105)
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should not create or update an office holder model id the person and office cannot be found' do
      stub!(:years_from_dates)
      Person.stub!(:find_by_import_id)
      Office.stub!(:find_by_import_id)
      OfficeHolder.should_not_receive(:create!)
      OfficeHolder.should_not_receive(:find)
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should create an estimated start date from the start year if there is no start date' do
      should_receive(:office_start_date_from_year).with(1981, false).and_return(Date.new(1981,1,1))
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should create an estimated end date from the end year if there is no end date' do
      should_receive(:office_end_date_from_year).with(1983, false)
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should should set the estimated start date flag to false if an exact date is supplied' do
      expected_start_attributes = { :start_date => Date.new(2004, 3, 3), 
                                    :estimated_start_date => false }
      stub!(:parse_office_holders_line).and_return(:start_date => Date.new(2004, 3, 3))
      OfficeHolder.should_receive(:create!).with(@expected_attributes.merge(expected_start_attributes))
      create_office_holder_from_line office_holder_line, @data_source
    end
  
    it 'should should set the estimated end date flag to false if an exact date is supplied' do
      expected_end_attributes = { :end_date => Date.new(2004, 3, 3), 
                                  :estimated_end_date => false }
      stub!(:parse_office_holders_line).and_return(:end_date => Date.new(2004, 3, 3))
      OfficeHolder.should_receive(:create!).with(@expected_attributes.merge(expected_end_attributes))
      create_office_holder_from_line office_holder_line, @data_source
    end
  
    it 'should look for an existing office holder with the same person, office and start year or end year' do
      stub!(:office_start_date_from_year).and_return(Date.new(1981, 1, 1))
      OfficeHolder.should_receive(:find).with(:first, :conditions => ['person_id = ? and office_id = ? and (YEAR(start_date) = ? or YEAR(end_date) = ?)', @person.id, @office.id, 1981, 1983])
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should update the attributes of the office holder if one exists' do
      office_holder = mock_model(OfficeHolder)
      OfficeHolder.stub!(:find).and_return(office_holder)
      office_holder.should_receive(:update_attributes).with(@expected_attributes)
      create_office_holder_from_line office_holder_line, @data_source
    end

    it 'should create a new office holder if none exists for the person, office and start date' do
      OfficeHolder.stub!(:find).and_return(nil)
      OfficeHolder.should_receive(:create!).with(@expected_attributes)
      create_office_holder_from_line office_holder_line, @data_source
    end

  end
  
  describe 'when extracting years from a date string' do 
  
    it 'should return [[nil, 2005]] from "-2005"' do 
      years_from_dates('-2005').should == [[nil, 2005]]
    end
    
    it 'should return [[nil, nil]] from ""' do 
      years_from_dates('').should == [[nil, nil]]
    end
    
    it 'should return [[2004, 2005]] from "2004-2005"' do 
      years_from_dates('2004-2005').should == [[2004, 2005]]
    end
    
    it 'should return [[2004, nil]] from "2004-"' do 
      years_from_dates('2004-').should == [[2004, nil]]
    end
    
    it 'should return [[2004, 2004]] from "2004"' do 
      years_from_dates('2004').should == [[2004, 2004]]
    end
  
    it 'should return [[1885, 1886], [1886, 1892], [1895, 1898]] from "1885-1886;1886-1892;1895-1898"' do 
      years_from_dates("1885-1886;1886-1892;1895-1898").should == [[1885, 1886], [1886, 1892], [1895, 1898]]
    end
    
    it 'should return [[1873, 1874], [1880, 1882]] from "1873-1874; 1880-1882"' do 
      years_from_dates("1873-1874; 1880-1882").should == [[1873, 1874], [1880, 1882]]
    end 
    
    it 'should return [[1924, 1924], [1929, 1930]] from "1924;1929-30"' do 
      years_from_dates("1924;1929-30").should == [[1924, 1924], [1929, 1930]]
    end
    
    it 'should return [[1873, 1874]] from "1873-4"' do 
      years_from_dates("1873-4").should == [[1873, 1874]]
    end
    
    it 'should return [[1924, 1924], [1931, 1935]] from "1924,1931-1935"' do
      years_from_dates("1924,1931-1935").should == [[1924, 1924], [1931, 1935]]
    end
    
    it 'should return [[1921, 1924], [1924, 1928]] from "1921-1924.1924-1928"' do 
      years_from_dates("1921-1924.1924-1928").should == [[1921, 1924], [1924, 1928]]
    end
    
    it 'should return [[1991, 1997]] from "1991-1997?"' do 
      years_from_dates("1991-1997?").should == [[1991, 1997]]
    end
    
    it 'should return [[1992, 1995]] from "1992-1994/5"' do 
      years_from_dates("1992-1994/5").should == [[1992, 1995]]
    end
    
    it 'should return [[nil, nil]] from "-"' do 
      years_from_dates("-").should == [[nil, nil]]
    end
    
  end

  describe "when asked for the number of seats for a year" do 

    it 'should return the number of seats for the largest year in the list smaller than the year given' do
      seats_for_year([[1801, 658], [1844, 656]], 1805).should == 658
      seats_for_year([[1801, 658], [1844, 656]], 1845).should == 656
    end
  end

end