require File.dirname(__FILE__) + '/../spec_helper'

describe Sitting do

  describe 'uri_component_to_sitting_model' do
    it 'should return HouseOfCommonsSitting when passed "commons"' do
      Sitting.uri_component_to_sitting_model('commons').should == HouseOfCommonsSitting
    end

    it 'should return HouseOfLordsSitting when passed "lords"' do
      Sitting.uri_component_to_sitting_model('lords').should == HouseOfLordsSitting
    end

    it 'should return WrittenAnswersSitting when passed "written_answers"' do
      Sitting.uri_component_to_sitting_model('written_answers').should == WrittenAnswersSitting
    end

    it 'should return WrittenStatementsSitting when passed "written_statements"' do
      Sitting.uri_component_to_sitting_model('written_statements').should == WrittenStatementsSitting
    end

    it 'should return WestminsterHallSitting when passed "westminster_hall"' do
      Sitting.uri_component_to_sitting_model('westminster_hall').should == WestminsterHallSitting
    end

    it 'should return GrandCommitteeReportSitting when passed "grand_committee_report"' do
      Sitting.uri_component_to_sitting_model('grand_committee_report').should == GrandCommitteeReportSitting
    end
  end

  describe "when sorting sittings by type" do
    before(:all) do
      @commons_wrans = mock_model(CommonsWrittenAnswersSitting)
      @lords_wrans = mock_model(LordsWrittenAnswersSitting)
      @commons_statements = mock_model(CommonsWrittenStatementsSitting)
      @lords_statements = mock_model(LordsWrittenStatementsSitting)
      @wrans = mock_model(WrittenAnswersSitting)
      @lords_report = mock_model(HouseOfLordsReport)
      @lords = mock_model(HouseOfLordsSitting)
      @commons = mock_model(HouseOfCommonsSitting)
      @westminster_hall = mock_model(WestminsterHallSitting)
      @grand_committee_report = mock_model(GrandCommitteeReportSitting)
      @sitting_list = [@commons_wrans, @lords_wrans, @wrans, @lords_report, @lords,
          @commons, @westminster_hall, @grand_committee_report, @commons_statements, @lords_statements]
    end

    it 'should sort sittings in the order commons, westminster hall, commons written answers, lords, grand committee report, lords written answers, lords reports, any other sitting' do
      Sitting.sort_by_type(@sitting_list).collect(&:class).collect(&:name).should == [
          @commons.class.name,
          @westminster_hall.class.name,
          @commons_wrans.class.name,
          @commons_statements.class.name,
          @lords.class.name,
          @grand_committee_report.class.name,
          @lords_wrans.class.name,
          @lords_statements.class.name,
          @lords_report.class.name,
          @wrans.class.name]
    end
  end

  describe 'when populating cached mention columns' do 
  
    def mock_act section_id, contribution_id, act_id
      mock_model(ActMention, :section_id => section_id, 
                             :contribution_id => contribution_id, 
                             :first_in_section= => nil, 
                             :mentions_in_section= => nil, 
                             :act_id => act_id,
                             :save! => nil)
    end
    
    before do 
      @sitting = Sitting.new
      @first_act_first_section_first_mention = mock_act(section_id = 1, contribution_id = 1, act_id = 1)
      @first_act_first_section_second_mention = mock_act(section_id = 1, contribution_id = 2, act_id = 1)
      @first_act_second_section_first_mention = mock_act(section_id = nil, contribution_id = 2, act_id = 1)
      @second_act_first_section_first_mention = mock_act(section_id = 1, contribution_id = 1, act_id = 2)                         
      unordered_mentions = [@first_act_second_section_first_mention, 
                            @second_act_first_section_first_mention, 
                            @first_act_first_section_second_mention, 
                            @first_act_first_section_first_mention]
      @sitting.stub!(:act_mentions).and_return(unordered_mentions)
    end
    
    it 'should mark the first mention of an act or bill in each section that has a contribution' do 
      @first_act_first_section_first_mention.should_receive(:first_in_section=).with(true)
      @sitting.populate_cached_mention_columns
    end
    
    it 'should mark the section title mention of an act or bill if there are no contribution mentions' do 
      @first_act_second_section_first_mention.should_receive(:first_in_section=).with(true)
      @sitting.populate_cached_mention_columns
    end
    
    it 'should correctly cache the number of mentions of each act or bill within a section' do 
      @first_act_first_section_first_mention.should_receive(:mentions_in_section=).with(2)
      @first_act_second_section_first_mention.should_receive(:mentions_in_section=).with(1)
      @sitting.populate_cached_mention_columns
    end
    
  end
  
  describe 'when populating people' do 
  
    before do 
      @sitting = Sitting.new
    end
    
    it 'should clear existing people' do 
      @sitting.people << Person.new
      @sitting.populate_people
      @sitting.people.should == []
    end
    
    it 'should create a unique list of people' do
      person = mock_model(Person)
      contribution_one = mock_model(Contribution, :person => person)
      contribution_two = mock_model(Contribution, :person => person) 
      @sitting.stub!(:contributions).and_return([contribution_one, contribution_two])
      @sitting.populate_people
      @sitting.people.should == [person]
    end
    
  end
  
  describe 'when asked for its series' do 
    
    it 'should return the series associated with its volume if it has one' do 
      sitting = Sitting.new
      sitting.stub!(:volume).and_return(mock_model(Volume, :series => 'series'))
      sitting.series.should == 'series'
    end
    
    it 'should return nil if it does not have a volume' do 
      sitting = Sitting.new
      sitting.series.should be_nil
    end
    
  end
  
  describe 'when asked for 3 days worth of sections from 10 years ago, counting back from a date' do 
  
    before do 
      @date = Date.new(2001, 3, 1)
    end
    
    it 'should ask for one section from 10 years ago on the date, one from 10 years before day before, and one from 10 years before the day before that ' do 
      Sitting.should_not_receive(:section_from_years_ago).with(10, @date + 1)
      Sitting.should_receive(:section_from_years_ago).with(10, @date)
      Sitting.should_receive(:section_from_years_ago).with(10, @date - 1)
      Sitting.should_receive(:section_from_years_ago).with(10, @date - 2)
      Sitting.sections_from_years_ago(10, @date, 3)
    end
    
    it 'should return the sections in reverse cronological order' do 
      Sitting.stub!(:section_from_years_ago).with(10, @date).and_return('date')
      Sitting.stub!(:section_from_years_ago).with(10, @date - 1).and_return('date minus one')
      Sitting.stub!(:section_from_years_ago).with(10, @date - 2).and_return('date minus two')
      Sitting.sections_from_years_ago(10, @date, 3).should == [["date", @date], 
                                                               ["date minus one", @date - 1],
                                                               ["date minus two", @date - 2]]
      
    end
    
    it 'should only include a section returned for multiple days for the first chronological date in which it appears' do 
      Sitting.stub!(:section_from_years_ago).and_return('section')
      Sitting.sections_from_years_ago(10, @date, 3).should == [['section', @date - 2]]
    end
    
  end
  
  describe 'when asked for a section from a number of years ago' do 
    
    before do 
      @section = mock_model(Section)
      @sitting = mock_model(Sitting, :longest_sections => [@section])
      Sitting.stub!(:find_closest_to).and_return(@sitting)
    end
    
    it 'should ask for the closest sitting to this day a number of years ago' do 
      Sitting.should_receive(:find_closest_to).with(Date.today.years_ago(10)).and_return(@sitting)
      Sitting.section_from_years_ago(10)
    end
    
    it 'should return nil if there are no sitings' do 
      Sitting.should_receive(:find_closest_to).with(Date.today.years_ago(10)).and_return(nil)
      Sitting.section_from_years_ago(10).should be_nil
    end
    
    it 'should ask for the longest section of that sitting' do 
      @sitting.should_receive(:longest_sections).with(1).and_return([@section])
      Sitting.section_from_years_ago(10)
    end
    
    it 'should return the longest section' do 
      Sitting.section_from_years_ago(10).should == @section
    end
    
    it 'should use a date passed to it instead of today if one is given' do
      date = Date.new(1922, 1, 1)
      Sitting.should_receive(:find_closest_to).with(date.years_ago(10)).and_return(@sitting)
      Sitting.section_from_years_ago(10, date)
    end
  
  end
  
  describe 'when asked for its n longest sections' do 
    
    before do 
      @sitting = Sitting.new
      sections = []
      5.times{ |index| sections << mock_model(Section, :word_count => index) }
      @sitting.stub!(:all_sections).and_return(sections)
    end
    
    it 'should return n sections' do
      @sitting.longest_sections(3).size.should == 3
    end
    
    it 'should return sections sorted in order of longest word count' do 
      sections = @sitting.longest_sections(5)
      sections.each_with_index do |section, index|
        if sections[index+1]
        (section.word_count > sections[index+1].word_count).should be_true
        end
      end
    end
    
  end
  
  describe 'on creation' do
    before(:each) do
      @volume = Volume.new
      # @volume.save!
      @sitting = Sitting.create :volume => @volume, :date => '2007-12-12'
      @top_section = Section.create(:sitting => @sitting)
      @child_section = Section.create(:sitting => @sitting, :parent_section => @top_section)
    end

    after do
      Volume.delete_all
      Sitting.delete_all
      Section.delete_all
    end

    it "should be valid" do
      @sitting.should be_valid
    end

    it "should have house coming from its class' house method" do
      Sitting.stub!(:house).and_return('House Name')
      sitting = Sitting.new
      sitting.house.should == 'House Name'
    end

    it 'should be associated with a volume' do
      @sitting.volume.should == @volume
    end

    it 'should return sections with no parent section for direct_descendents' do
      @sitting.direct_descendents(true).should == [@top_section]
    end

    it 'should return all sections with this sitting_id for all_sections' do
      @sitting.all_sections(true).should == [@top_section, @child_section]
    end

    it "should be able to tell if it is present on a date" do
      Sitting.respond_to?("present_on_date?").should == true
    end
  end

  describe ".find_in_resolution" do
    before do
      @date = Date.new(2006, 12, 18)
      @first_sitting = Sitting.new(:date => @date)
      @second_sitting = Sitting.new(:date => @date)
      @third_sitting = Sitting.new(:date => @date)
    end

    it "should ask for sittings on a date if passed a date and the resolution :day" do
      Sitting.should_receive(:find_all_present_on_date).and_return([@first_sitting, @second_sitting, @third_sitting])
      Sitting.find_in_resolution(@date, :day)
    end

    it 'should ask for sittings in the month if passed a date and the resolution :month' do
      Sitting.should_receive(:find_all_present_in_interval).with(Date.new(2006, 12, 1), Date.new(2006, 12, 31)).and_return([@first_sitting, @second_sitting, @third_sitting])
      Sitting.find_in_resolution(@date, :month)
    end

    it 'should ask for all sittings in the year if passed a date and the resolution :year' do
      Sitting.should_receive(:find_all_present_in_interval).with(Date.new(2006, 1, 1), Date.new(2006, 12, 31)).and_return([@first_sitting, @second_sitting, @third_sitting])
      Sitting.find_in_resolution(@date, :year)
    end

    it 'should return all sittings in the decade if passed a date and the resolution :decade' do
      Sitting.should_receive(:find_all_present_in_interval).with(Date.new(2000, 1, 1), Date.new(2009, 12, 31)).and_return([@first_sitting, @second_sitting, @third_sitting])
      Sitting.find_in_resolution(@date, :decade)
    end
  end

  describe ".find_section_by_column" do
    before do
      @sitting = Sitting.create(:date => Date.new(2006, 6, 6), :start_column => "44")
      @first_section = Section.new(:start_column => "44", :end_column => "54")
      @second_section = Section.new(:start_column => "55", :end_column => "85")
      @sitting.all_sections = [@first_section, @second_section]
    end

    after do
      Sitting.delete_all
      Section.delete_all
    end

    it 'should return the first section whose column range contains the column if no sections have sub-sections' do
      @sitting.find_section_by_column('57').should == @second_section
    end

    it 'should return the most specific section whose column range contains the column if sections have sub-sections' do
      more_specific_section = Section.new(:start_column => "56", :end_column => "58")
      @second_section.stub!(:sections).and_return([more_specific_section])
      @sitting.find_section_by_column('57').should == more_specific_section
    end

    it 'should return the high level section whose column range contains the column if no sub section contains the column' do
      more_specific_section = Section.new(:start_column => "58", :end_column => "62")
      @second_section.stub!(:sections).and_return([more_specific_section])
      @sitting.find_section_by_column('57').should == @second_section
    end
  end

  describe 'with contributions' do
   
    before(:all) do
      @sitting =Sitting.new :date => '2007-12-12'
      @section = Section.new
      @sitting.all_sections << @section
      @contribution_one = Contribution.new(:section => @section)
      @contribution_two = Contribution.new(:section => @section)
      @section.contributions = [@contribution_one, @contribution_two]
      @sitting.save!
    end

    it 'should be able to return the contributions' do
      expected = @sitting.all_sections.map{ |section| section.contributions }.flatten
      @sitting.contributions.should == expected
    end

  end
  
  describe 'when asked for the contributions associated with a person' do 
    
    it 'should return the contributions associated with that persons commons memberships' do 
      person = mock_model(Person, :commons_membership_ids => [1,2,3], :lords_membership_ids => [])
      person_contribution = mock_model(Contribution, :commons_membership_id => 3, :lords_membership_id => nil)
      other_person_contribution = mock_model(Contribution, :commons_membership_id => 5, :lords_membership_id => nil)
      sitting = Sitting.new
      sitting.stub!(:contributions).and_return([other_person_contribution, person_contribution])
      sitting.person_contributions(person).should == [person_contribution]
    end
  
    it 'should return the contributions associated with that persons lords memberships' do 
      person = mock_model(Person, :lords_membership_ids => [1,2,3], :commons_membership_ids => [])
      person_contribution = mock_model(Contribution, :lords_membership_id => 3, :commons_membership_id => nil)
      other_person_contribution = mock_model(Contribution, :lords_membership_id => 5, :commons_membership_id => nil)
      sitting = Sitting.new
      sitting.stub!(:contributions).and_return([other_person_contribution, person_contribution])
      sitting.person_contributions(person).should == [person_contribution]
    end
    
  end

  describe "when asked for people" do

    it 'should return the people associated with the memberships' do
      sitting = Sitting.new :date => '2007-12-12'
      person = Person.create!(:lastname => "test person for contributions")
      other_person = Person.create!(:lastname => "second test person for contributions")
      section = Section.new
      sitting.all_sections << section
      contribution_one = Contribution.new(:commons_membership => CommonsMembership.new(:person => person), :section => section)
      contribution_two = Contribution.new(:commons_membership => CommonsMembership.new(:person => other_person), :section => section)
      section.contributions = [contribution_one, contribution_two]
      sitting.save!
      sitting.people.should == [person, other_person]
    end
  end

  describe "column number" do
    it 'should be 24 for "24BD"' do
      Sitting.column_number("24BD").should == 24
    end

    it 'should be 24 for "24"' do
      Sitting.column_number("24").should == 24
    end

    it 'should be 24 for 24' do
      Sitting.column_number(24).should == 24
    end
  end

  describe 'extra column suffix' do
    before(:each) do

    end

    it 'should return "aa" for "444aa"' do
      Sitting.extra_column_suffix("444aa").should == 'aa'
    end

    it 'should return nil for "485WH"' do
      Sitting.extra_column_suffix('485WH').should be_nil
    end

    it 'should return nil for any pattern with a known sitting type suffix' do
      models = Dir.glob("#{RAILS_ROOT}/app/models/*.rb").map do |path|
        File.basename(path, ".rb").camelize.constantize
      end
      sitting_models = models.select{ |model| model.ancestors.include? Sitting }
      sitting_models.each do |sitting_model|
        Sitting.extra_column_suffix("333#{sitting_model.hansard_reference_suffix}").should be_nil
      end
    end
  end

  describe "normalized column" do
    before(:each) do
      Sitting.stub!(:hansard_reference_suffix).and_return("WS")
    end

    it 'should be "24WS" for a column "WS 24" in a sitting whose reference suffix is "WS"' do
      Sitting.normalized_column("WS 24").should == "24WS"
    end

    it 'should be "24WS" for a column "24" in a sitting whose reference suffix is "WS"' do
      Sitting.normalized_column("24").should == "24WS"
    end

    it 'should be "24WS" for a column 24 in a sitting whose reference suffix is "WS"' do
      Sitting.normalized_column(24).should == "24WS"
    end
  end

  describe "when asked if it has missing columns" do

    before do
      @sitting = Sitting.new(:start_column => '2', :end_column => '4')
      @sitting.stub!(:find_section_by_column).and_return(mock_model(Section))
    end

    it 'should return true if it cannot find a section for each column between its first and last columns' do
      @sitting.stub!(:find_section_by_column).and_return(nil)
      @sitting.missing_columns?.should be_true
    end

    it 'should return false if there is a section for each column between its first and last columns' do
      @sitting.missing_columns?.should be_false
    end

    it 'should return true if it has no start column' do
      @sitting.stub!(:start_column).and_return(nil)
      @sitting.missing_columns?.should be_true
    end

    it 'should return true if it has no end column' do
      @sitting.stub!(:end_column).and_return(nil)
      @sitting.missing_columns?.should be_true
    end
    
  end

  describe "when asked for date and column sort parameters" do
    it 'should return 1954-10-01, 3, 2 for a Commons written answers sitting with date 1954-10-01, start column "WA 3"' do
      date = Date.new(1954, 10, 1)
      sitting = CommonsWrittenAnswersSitting.new(:date => date, :start_column => "WA 3")
      sitting.date_and_column_sort_params.should == [date, 3, 2]
    end
  end

  describe 'when creating a hash of offices in the sitting' do
    it 'should create a new hash where unknown keys return a list' do
      sitting = Sitting.new
      sitting.create_offices_in_sitting['unknown key'].should == []
    end

    it 'should extract office and name parts from the chairman if there is one' do
      sitting = Sitting.new(:chairman => 'Mr. SPEAKER')
      Sitting.should_receive(:office_and_name).with('Mr. SPEAKER').and_return [nil, nil]
      sitting.create_offices_in_sitting
    end

    it 'should add any membership ids for the office part (if there is one) to the hash, keyed by "chairman"' do
      sitting = Sitting.new(:chairman => 'Mr. SPEAKER')
      Sitting.stub!(:office_and_name).with('Mr. SPEAKER').and_return ['SPEAKER', nil]
      sitting.should_receive(:membership_lookups).and_return({:office_names => {'speaker' => [21]}})
      sitting.create_offices_in_sitting['chairman'].should == [21]
    end

    it 'should add any membership ids for the name part (if theres no office) to the hash, keyed by "chairman"' do
      sitting = Sitting.new(:chairman => 'Mr. John Adams')
      sitting.stub!(:house).and_return('Lords')
      Sitting.stub!(:office_and_name).with('Mr. John Adams').and_return [nil, 'Mr. John Adams']
      sitting.should_receive(:membership_lookups).and_return({})
      LordsMembership.should_receive(:get_memberships_by_name).with('Mr. John Adams', {}).and_return([21])
      sitting.create_offices_in_sitting['chairman'].should == [21]
    end
  end

  describe 'when getting membership_lookups' do
    
    before do 
      @date = Date.new(1901, 12, 1)
      @sitting = Sitting.new(:date => @date)
      CommonsMembership.stub!(:membership_lookups).and_return({})
    end
    
    it 'should ask for the commons membership lookup hashes for the date if the sitting house is the Commons' do
      @sitting.stub!(:house).and_return('Commons')
      CommonsMembership.should_receive(:membership_lookups).with(@date)
      @sitting.membership_lookups
    end
    
    it 'should ask for the lords membership lookup hashes for the date if the sitting house is the Lords' do
      @sitting.stub!(:house).and_return('Lords')
      LordsMembership.should_receive(:membership_lookups).with(@date)
      @sitting.membership_lookups
    end
    
  end
  
  describe 'when asked for sittings for a year' do 
  
    it 'should ask for all sittings whose year is equal to the year given' do 
      Sitting.should_receive(:find).with(:all, :conditions => ['YEAR(date) = ?', 1992])
      Sitting.find_for_year(1992)
    end
    
  end

  describe 'when asked for the closest sitting to a date' do
    before do
      @date = Date.new(1899, 1, 21)
      Sitting.stub!(:find)
    end

    def stub_next(date, next_date)
      sitting = mock_model(Sitting, :date => next_date)
      Sitting.stub!(:find).with(:first,
                                :conditions => ['date >= ?', date],
                                :order => 'date asc').and_return(sitting)
    end

    def stub_previous(date, previous_date)
      sitting = mock_model(Sitting, :date => previous_date)
      Sitting.stub!(:find).with(:first,
                                :conditions => ['date < ?', date],
                                :order => 'date desc').and_return(sitting)
    end

    it 'should ask for the date of the first sitting on or after the date' do
      Sitting.should_receive(:find).with(:first,
                                         :conditions => ['date >= ?', @date],
                                         :order => 'date asc')
      Sitting.find_closest_to(@date)
    end

    it 'should return the sitting on the date passed to it if there is a sitting on that date' do
      stub_next(@date, @date)
      Sitting.find_closest_to(@date).date.should == @date
    end

    it 'should ask for the date of the last sitting before the date if there is no sitting on the date' do
      stub_next(@date, @date + 1)
      Sitting.find_closest_to(@date)
    end

    it 'should return a sitting from the first date with sittings before the date if that is the closest sitting date' do
      stub_next(@date, @date + 3)
      stub_previous(@date, @date - 2)
      Sitting.find_closest_to(@date).date.should == @date - 2
    end

    it 'should return a sitting from first date with sittings after the date if that is the closest sitting date' do
      stub_next(@date, @date + 2)
      stub_previous(@date, @date - 3)
      Sitting.find_closest_to(@date).date.should == @date + 2
    end
    
    it 'should not raise an error when passed a date time object' do 
      lambda{ Sitting.find_closest_to(Time.now - 100.years) }.should_not raise_error
    end
    
  end

  describe 'when finding division by division number' do
    before do
      @sitting = Sitting.new
      @sections = mock('sections')
      @sitting.should_receive(:all_sections).and_return @sections
    end

    it 'should return division if there is a match' do
      division = mock_model(Division, :division_id=>'division_1')
      @sections.should_receive(:collect).and_return [ [division] ]
      @sitting.find_division('division_1').should == division
    end

    it 'should return nil if there is no division match' do
      @sections.should_receive(:collect).and_return []
      @sitting.find_division('division_1').should be_nil
    end
  end

  describe 'when finding sitting and section' do
    it 'should find section using type, date and section slug' do
      type = mock('type')
      date_string = mock('date_string')
      date = mock('date', :to_date => mock('to_date', :to_s => date_string))
      slug = 'mediation-of-russia-'

      section = mock('section')
      sitting = mock('sitting')
      sitting.should_receive(:find_section_by_slug).with(slug).and_return section

      sittings = [sitting]
      sitting_model = mock('sitting model')
      sitting_model.should_receive(:find_all_by_date).with(date_string).and_return sittings
      Sitting.should_receive(:uri_component_to_sitting_model).with(type).and_return sitting_model

      Sitting.find_sitting_and_section(type, date, slug).should == [sitting, section]
    end
  end

  describe 'when finding section using slug' do
    it 'should find section in sections that matches slug' do
      slug = 'mediation-of-russia'
      all_sections = mock('all_sections')
      section = mock('section')
      all_sections.should_receive(:find_by_slug).with(slug, anything).and_return section
      sitting = Sitting.new
      sitting.should_receive(:all_sections).and_return(all_sections)
      sitting.find_section_by_slug(slug).should == section
    end
  end

  describe 'when asked for debates sections' do
    it 'should return sections in debates' do
      sections = mock('sections')
      debates = mock('debates', :sections => sections)
      sitting = Sitting.new
      sitting.should_receive(:debates).and_return debates
      sitting.debates_sections.should == sections
    end
  end

  describe 'when asked for debates sections count' do
    it 'should return count of sections in debates' do
      sitting = Sitting.new
      sitting.should_receive(:debates_sections).and_return []
      sitting.debates_sections_count.should == 0

      sitting = Sitting.new
      sitting.should_receive(:debates_sections).and_return [mock('section')]
      sitting.debates_sections_count.should == 1
    end
  end

  describe 'when asked for its type abbreviation' do 
    
    def expect_type_abbreviation(class_name, abbreviation, data_file_name = '')
      sitting = class_name.new(:data_file => mock_model(DataFile, :name => data_file_name))
      sitting.type_abbreviation.should == abbreviation
    end
    
    it 'should return "WH" for a WestminsterHallSitting' do 
      expect_type_abbreviation(WestminsterHallSitting, 'WH')
    end
    
    it 'should return "HOC" for a HouseOfCommonsSitting' do 
      expect_type_abbreviation(HouseOfCommonsSitting, 'HOC')
    end
    
    it 'should return "HOL" for a HouseOfLordsSitting' do 
      expect_type_abbreviation(HouseOfLordsSitting, 'HOL')
    end
     
    it 'should return "CWA" for a CommonsWrittenAnswersSitting' do 
      expect_type_abbreviation(CommonsWrittenAnswersSitting, 'CWA')
    end
    
    it 'should return "LWA" for a LordsWrittenAnswersSitting' do 
      expect_type_abbreviation(LordsWrittenAnswersSitting, 'LWA')
    end
    
    it 'should return "CWS" for a CommonsWrittenStatementsSitting' do 
      expect_type_abbreviation(CommonsWrittenStatementsSitting, 'CWS')
    end
    
    it 'should return "LWS" for a LordsWrittenStatementsSitting' do 
      expect_type_abbreviation(LordsWrittenStatementsSitting, 'LWS')
    end
    
    it 'should return "GCR" for a GrandCommitteeReportSitting' do 
      expect_type_abbreviation(GrandCommitteeReportSitting, 'GCR')
    end
    
    it 'should return "HOC2" for a HouseOfCommonsSitting whose data file name ends with "part_2"' do 
      expect_type_abbreviation(HouseOfCommonsSitting, 'HOC2', "housecommons_1805_06_05_part_2.xml")
    end
  
  end
  
  describe 'when asked for its short date' do 
  
    it 'should return "20040212" for date 12 Feb 2004' do 
      sitting = Sitting.new
      sitting.stub!(:date).and_return(Date.new(2004, 2, 12))
      sitting.short_date.should == '20040212'
    end
  
    it 'should return an empty string if there is no date' do
      sitting = Sitting.new
      sitting.stub!(:date).and_return(nil)
      sitting.short_date.should == ''    
    end
  
  end
  
end


