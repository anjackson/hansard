require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::PeeragesParser do
  
  before do 
    @parser = Hansard::PeeragesParser.new 
    @parser.stub!(:open_doc)
    @parser.stub!(:puts)
    @parser.stub!(:get_local_file)
  end
  
  describe 'when parsing' do 
    
    before do
      @membership_one = mock("membership")
      @membership_two = mock("membership")
      @people = {"1" => [@membership_one, @membership_two]}
      @parser.stub!(:new_people).and_return(@people)
      @parser.stub!(:save_person).and_return(1)
      @parser.stub!(:save_membership)
      @parser.stub!(:parse_file)
      @person = mock_model(Person)
      Person.stub!(:new).and_return(@person)
    end
    
    it 'should save the memberships associated with each new person identified' do 
      @parser.should_receive(:save_membership).with(@membership_one, 1)
      @parser.should_receive(:save_membership).with(@membership_two, 1)
      @parser.parse
    end
    
    it 'should save each new person identified' do
      @parser.should_receive(:save_person).with(@membership_one)
      @parser.parse
    end
    
    it 'should save the alternative titles' do 
      @parser.should_receive(:save_alternative_titles)
      @parser.parse
    end
  
  end
  
  describe 'when parsing a file' do 
  
    before do 
      @parser.stub!(:parse_memberships)
    end
    
    it 'should parse the memberships' do 
      @parser.should_receive(:parse_memberships).and_return([])
      @parser.parse_file ''
    end
    
    it 'should set the membership type to "Life peer" if the filename is "index_life_peer.htm"' do 
      @parser.parse_file 'test/index_life_peer.htm'
      @parser.peerage_type.should == 'Life peer'
    end
    
    it 'should set the membership type to "Law Lord" if the filename is index_law_lord.htm' do 
      @parser.parse_file 'test/index_law_lord.htm'
      @parser.peerage_type.should == 'Law Lord'
    end
    
    it 'should set the membership type to "Hereditary" if the filename is not "index_life_peer.htm"' do 
      @parser.parse_file 'test/index_baron.htm'
      @parser.peerage_type.should == 'Hereditary'
    end
  
  end
  
  describe 'when parsing memberships' do 
    
    before do
      @doc = Hpricot("<p><b></b>a line\r\n<br />another line</p><p></p>")
    end
    
    it 'should get memberships from sets of lines' do 
      @parser.should_receive(:get_memberships)
      @parser.parse_memberships(@doc)
    end
    
    it 'should look for <p> tags with <b> tags inside, split them on <br /> and parse the resulting list for memberships' do
      @parser.should_receive(:get_memberships).with(['<b></b>a line', 'another line'])
      @parser.parse_memberships(@doc)
    end
    
  end
  
  describe 'when getting memberships from sets of lines' do
   
    before do
      @lines = []
      @title_attributes = {:memberships => []}
      @parser.stub!(:parse_title_and_holders).and_return(@title_attributes)
      @parser.stub!(:filter_for_dates).and_return(@title_attributes)
      @parser.stub!(:handle_membership)
    end
  
    it 'should filter the memberships by inclusion in the dates covered by the application' do
      @parser.should_receive(:filter_for_dates).and_return(@title_attributes)
      @parser.get_memberships(@lines)
    end

    it 'should parse the list for titles and holders' do
      @parser.should_receive(:parse_title_and_holders).with(@lines).and_return({})
      @parser.get_memberships(@lines)
    end
    
    it 'should get the details of each person a membership is found for' do
      membership = {}
      @title_attributes[:memberships] << membership
      @parser.should_receive(:get_person_details).with(membership).and_return({})
      @parser.get_memberships(@lines)
    end
    
  end
  
  describe 'when handling memberships' do 

    before do 
      @membership = { :date_of_birth => Date.new(1955, 3, 23), 
                      :date_of_death => Date.new(1977, 4, 1),
                      :person_import_id => 'i40' }
      @title_attributes = {:title => 'title'}
      @parser.stub!(:get_degree_and_title).and_return(@membership)
      LordsMembership.stub!(:find_by_years_degree_and_title)
      @parser.stub!(:match_person)
      @parser.stub!(:add_to_new_people)
      @parser.stub!(:person_sits_in_lords?).and_return true
      @parser.stub!(:region_sits_in_lords?).and_return true
    end
    
    it 'should not try to match someone who has neither a date of birth nor a year of birth nor a date of death or year of death' do
      @membership[:date_of_birth] = nil
      @membership[:date_of_death] = nil
      @parser.should_not_receive(:match_person)
      @parser.handle_membership(@membership, @title_attributes)
    end
    
    it 'should not try to match someone who was born before 1910 and has neither a date of death nor a year of death' do
      @membership[:date_of_birth] = Date.new(1900, 1, 1)
      @membership[:date_of_death] = nil
      @parser.should_not_receive(:match_person)
      @parser.handle_membership(@membership, @title_attributes)
    end
    
    it 'should not try to match a membership for a person that cannot be matched by information about the person but who has another membership already in the application' do
      @parser.matches_by_membership = { 'i40' => true }
      @parser.should_not_receive(:match_person)
      @parser.handle_membership(@membership, @title_attributes)
    end
    
    it 'should get the degree and title of the membership' do 
      @parser.should_receive(:get_degree_and_title).with(@membership, 'title').and_return(@membership)
      @parser.handle_membership(@membership, @title_attributes)
    end
    
    it 'should try and match a person with a date of birth who is entitled to sit in the Lords' do 
      @parser.should_receive(:match_person)
      @parser.handle_membership(@membership, @title_attributes)
    end

    describe 'when the person is matched' do
      
      before do 
        @person = mock_model(Person, :import_id => 4)
        @parser.stub!(:match_person).and_return(@person)
      end
      
      it 'should add the new membership if the matched person has no existing Lords memberships' do 
        @person.stub!(:lords_memberships).and_return([])
        @parser.should_receive(:add_to_new_memberships)
        @parser.handle_membership(@membership, @title_attributes)
      end
      
      it 'should add the new membership if the matched person has existing Lords memberships matching the new one' do 
        memberships = mock('memberships', :empty? => false)
        @person.stub!(:lords_memberships).and_return(memberships)
        memberships.stub!(:find_by_years_degree_and_title).and_return('moo')
        @parser.should_not_receive(:add_to_new_memberships)
        @parser.handle_membership(@membership, @title_attributes)
      end
      
      it 'should set the person import id of the membership to the import id of the person' do 
        @person.stub!(:lords_memberships).and_return([])
        @parser.handle_membership(@membership, @title_attributes)
        @membership[:person_import_id].should == 4
      end
       
    end
    
    describe 'when the person is not matched' do
      
      before do 
        @parser.stub!(:match_person).and_return(nil)
      end
      
      it 'should add the membership to the list of new people if the membership itself does not match an existing membership' do 
        LordsMembership.stub!(:find_by_years_degree_and_title).and_return(nil)
        @parser.should_receive(:add_to_new_people)
        @parser.handle_membership(@membership, @title_attributes)
      end
      
      it 'should not add the membership to the list of new people if the membership matches an existing membership' do 
        LordsMembership.stub!(:find_by_years_degree_and_title).and_return(mock_model(LordsMembership))
        @parser.should_not_receive(:add_to_new_people)
        @parser.handle_membership(@membership, @title_attributes)
      end
      
    end

  end
  
  describe 'when asked to save alternative titles' do 
    
    before do 
      alternative_title_one = {:start_date => Date.new(1864, 6, 4),
                               :degree => 'Earl', 
                               :title => 'Balfour', 
                               :title_type => 'Peerage of Scotland'}
      alternative_title_two = {:start_date => Date.new(1824, 1, 23), 
                               :degree => 'Lord', 
                               :title => 'Westinghouse', 
                               :title_type => 'Peerage of Ireland'}
      @parser.stub!(:new_alternative_titles).and_return({1 => [alternative_title_one, alternative_title_two]})
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
      @parser.stub!(:last_alternative_title_id).and_return(5)
    end
    
    it 'should ask for the last alternative title id' do 
      @parser.should_receive(:last_alternative_title_id).and_return(4)
      @parser.save_alternative_titles
    end
  
    it 'should append a line to the file for each alternative title' do 
      @parser.save_alternative_titles
      lines = ["existing content", 
               "6\t1\t\tEarl\tBalfour\t\tPeerage of Scotland\t1864\t1864-06-04\t\t", 
               "7\t1\t\tLord\tWestinghouse\t\tPeerage of Ireland\t1824\t1824-01-23\t\t\n"]
      @string.should == lines.join("\n")
    end
  
  end
  
  describe 'when asked to save a membership' do 
    
    before do 
      @membership = {:start_date => Date.new(2004, 10, 21), 
                     :end_date => Date.new(2006, 7, 13), 
                     :degree => 'Baron', 
                     :title => 'Westminster', 
                     :peerage_type => 'Hereditary'}
      @parser.stub!(:last_lords_membership_id).and_return(5)
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
    end
    
    it 'should ask for the last lords membership id' do 
      @parser.should_receive(:last_lords_membership_id).and_return(4)
      @parser.save_membership(@membership, import_id=8)
    end
    
    it 'should append a line to the file' do 
      @parser.save_membership(@membership, import_id=8)
      @string.should == "existing content\n6\t8\t\tBaron\tWestminster\t\tHereditary\t2004\t2004-10-21\t2006\t2006-07-13\n"
    end
    
  end
  
  describe 'when asked to save a person' do 

     before do 
       @person = {:firstname => 'First', 
                  :lastname  => 'Last', 
                  :firstnames => 'Other',
                  :person_import_id => '10109391', 
                  :year_of_birth => 1901, 
                  :estimated_date_of_birth => true,
                  :date_of_death => Date.new(1986, 3, 21)}
       @string = "existing content\n"
       @fake_file = StringIO.new(@string, 'a')
       @parser.stub!(:open).and_yield(@fake_file)
     end

     it 'should write a line correctly to the file' do 
       @fake_file.should_receive(:write).with("10109391\tOther\tFirst\tLast\tMr\t1901\t\tFALSE\t1986\t1986-03-21\tTRUE\n")
       @parser.save_person(@person)
     end

     it 'should set the honorific to "Ms" for a female person' do 
       @person[:gender] = 'F'
       @parser.stub!(:last_people_id).and_return(3)
       @fake_file.should_receive(:write).with("10109391\tOther\tFirst\tLast\tMs\t1901\t\tFALSE\t1986\t1986-03-21\tTRUE\n")
       @parser.save_person(@person)
     end

  end
   
  describe 'when asked to clean a person import id' do 
    
    it 'should add 10000000 to the numerical part of the id' do
      @parser.clean_person_import_id('i109391').should == 10109391
    end
    
  end 
   
  describe 'when parsing titles and title holders' do 
    
    before do 
      @lines = ['<b>Lord Aberbrothwick</b>&nbsp;&nbsp;&nbsp;&nbsp;[Scotland, 1608]']
    end
    
    it 'should extract the title' do 
      @parser.parse_title_and_holders(@lines)[:title].should == 'Lord Aberbrothwick'
    end
    
    it 'should extract the region' do 
      @parser.parse_title_and_holders(@lines)[:region].should == 'Scotland'
    end
    
    it 'should extract the date the title was created' do 
      @parser.parse_title_and_holders(@lines)[:date_created].should == '1608'
    end
  
    it 'should extract the title from a line with extra place information' do 
      lines = ['<b>Lord Abercorn</b>, co. Linlithgow&nbsp;&nbsp;&nbsp;&nbsp;[Scotland, 1603]']
      @parser.parse_title_and_holders(lines)[:title].should == 'Lord Abercorn'
    end
    
    it 'should extract the title from a line with extra comments' do 
      lines = ['<b>Baroness Arlington</b>, of Arlington, Middlesex&nbsp;&nbsp;&nbsp;&nbsp;[England, 1665|suo jure,]']
      @parser.parse_title_and_holders(lines)[:title].should == 'Baroness Arlington'
    end
    
  end
  
  describe 'when filtering title memberships for dates' do 
  
    it 'should keep a membership ending after the first date covered by the application and starting before the last date ' do 
      membership = {:start_date => LAST_DATE - 1, 
                    :end_date => LAST_DATE + 1 }
      attributes = {:memberships => [membership]}
      @parser.filter_for_dates(attributes)[:memberships].should == [membership]
    end
    
    it 'should drop a membership starting after the last date covered by the application' do 
      membership = {:start_date => LAST_DATE + 1, 
                     :end_date => LAST_DATE - 1}
      attributes = {:memberships => [membership]}
      @parser.filter_for_dates(attributes)[:memberships].should == []
    end
    
    it 'should drop a membership ending before the first date covered by the application' do 
      membership = {:start_date => LAST_DATE + 1, 
                     :end_date => FIRST_DATE - 1}
      attributes = {:memberships => [membership]}
      @parser.filter_for_dates(attributes)[:memberships].should == []
    end
    
    
    it 'should drop a membership with no start_date' do 
      membership = {:start_date => nil, 
                     :end_date => FIRST_DATE + 1}
      attributes = {:memberships => [membership]}
      @parser.filter_for_dates(attributes)[:memberships].should == []
    end
    
    it 'should keep a membership starting before the last day covered by the application and having no end date' do 
      membership = {:start_date => LAST_DATE - 1, 
                    :end_date => nil }
      attributes = {:memberships => [membership]}
      @parser.filter_for_dates(attributes)[:memberships].should == [membership]
    end
  
  end
  
  describe 'when getting the degree and title for a person with a title' do 
  
    before do 
      @membership = {:gender => 'M'}
    end
    
    it 'should return "Baron" for "Baroness Abercromby of Aboukir and Tullibody" held by a male' do 
      title = 'Baroness Abercromby of Aboukir and Tullibody'
      @parser.get_degree_and_title(@membership, title)[:degree].should == 'Baron'
    end
    
    it 'should return "Baron" for "Baron Aberdare of Duffryn" held by a male' do 
      title = 'Baron Aberdare of Duffryn'
      @parser.get_degree_and_title(@membership, title)[:degree].should == 'Baron'
    end
    
    it 'should return "Lord" for "Lord Abercorn" held by a male' do 
      title = 'Lord Abercorn'
      @parser.get_degree_and_title(@membership, title)[:degree].should == 'Lord'
    end
    
  end
  
  describe 'when asked if a person holding a membership for a title can sit in the Lords' do 
    
    before do
      @membership = {:gender => 'F', :peerage_type => 'Hereditary'}
    end

    it 'should return true for a Life peer' do 
      @membership[:peerage_type] = 'Life peer'
      @parser.person_sits_in_lords?(@membership).should be_true
    end
    
    it 'should return true for a Law Lord' do 
      @membership[:peerage_type] = 'Law Lord'
      @parser.person_sits_in_lords?(@membership).should be_true
    end
    
    it 'should return true for a male person whose peerage starts before the 1999 Act' do 
      @membership[:gender] = 'M'
      @membership[:start_date] = @parser.hereditary_peers_abolition_date - 10
      @membership[:end_date] = @parser.hereditary_peers_abolition_date - 5
      @parser.person_sits_in_lords?(@membership).should be_true
    end
    
    it 'should return false for a female holding a title ending before the 1963 Peerage Act' do
      @membership[:start_date] = @parser.peerage_act_1963_date - 5
      @membership[:end_date] = @parser.peerage_act_1963_date - 1
      @parser.person_sits_in_lords?(@membership).should be_false
    end
    
    it 'should add a title held by a female ending before the 1963 Peerage Act as an alternative title' do 
      @membership[:start_date] = @parser.peerage_act_1963_date - 5
      @membership[:end_date] = @parser.peerage_act_1963_date - 1
      @parser.should_receive(:add_to_alternative_titles).with(@membership)
      @parser.person_sits_in_lords?(@membership)
    end
    
    describe 'when handling a title held by a female with a membership ending after the 1963 Peerage Act and a start date before the Act' do
    
      before do 
        @membership[:start_date] = @parser.peerage_act_1963_date - 5
        @membership[:end_date] = @parser.peerage_act_1963_date + 1
        @membership[:person_import_id] = 4
      end
      
      it 'should return true' do 
        @parser.person_sits_in_lords?(@membership).should be_true
      end
    
      it 'should set the start date to the date of the 1963 Peerage Act' do 
        @parser.person_sits_in_lords?(@membership)
        @membership[:start_date].should == @parser.peerage_act_1963_date
      end
    
      it 'should add the title with original dates as an alternative title ' do 
        @parser.person_sits_in_lords?(@membership)
        alternative_title = @parser.new_alternative_titles[@membership[:person_import_id]].first
        alternative_title[:start_date].should == @parser.peerage_act_1963_date - 5
      end
      
    end
    
    it 'should raise an error if the gender of the person is unknown' do
      @membership[:gender] = ''
      lambda{ @parser.person_sits_in_lords?(@membership) }.should raise_error('Gender of this person is not known')
    end
    
    describe 'when handling a person holding a hereditary peerage that starts after the 1999 House of Lords Act abolishing most hereditary peerages' do
    
      before do 
        @membership[:start_date] = @parser.hereditary_peers_abolition_date + 1
        @membership[:end_date] = @parser.hereditary_peers_abolition_date + 5
      end
      
      it 'should return false' do 
        @parser.person_sits_in_lords?(@membership).should be_false
      end
      
      it 'should add the membership as an alternative title' do 
        @parser.should_receive(:add_to_alternative_titles).with(@membership)
        @parser.person_sits_in_lords?(@membership)
      end
      
    end
    
    describe 'when handling a person holding a hereditary peerage that starts before the 1999 House of Lords Act abolishing most hereditary peerages' do
      
      before do 
        @membership[:start_date] = @parser.hereditary_peers_abolition_date - 2
        @membership[:end_date] = @parser.hereditary_peers_abolition_date + 5
        @membership[:person_import_id] = 7
      end
    
      it 'should return true ' do 
        @parser.person_sits_in_lords?(@membership).should be_true
      end
  
      it 'should set the end date to the date of effect of the Act' do 
        @parser.person_sits_in_lords?(@membership)
        @membership[:end_date].should == @parser.hereditary_peers_abolition_date
      end
      
      it 'should add the membership with original dates as an alternative title' do 
        @parser.person_sits_in_lords?(@membership)
        alternative_title = @parser.new_alternative_titles[@membership[:person_import_id]].first
        alternative_title[:end_date].should == @parser.hereditary_peers_abolition_date + 5     
      end

    end
  end
  
  describe 'when asked if a membership for a title sits in the Lords' do
    
    before do 
      @membership = {:person_import_id => 'i500'}
      @attributes = {}
    end
    
    it 'should return true if the peerage is a Life Peerage' do 
      @membership[:peerage_type] = 'Life peer'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
    
    it 'should return true if the peerage belongs to a Law Lord' do 
      @membership[:peerage_type] = 'Law Lord'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
  
    it 'should return true for a United Kingdom title' do 
      @attributes[:region] = 'United Kingdom'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
    
    it 'should return true for a Great British title' do 
      @attributes[:region] = 'Great Britain'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
    
    it 'should return true for an English title' do 
      @attributes[:region] = 'England'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
    
    it 'should return false for a Irish title' do 
      @attributes[:region] = 'Ireland'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_false
    end
    
    it 'should add the membership as an alternative title' do 
      @attributes[:region] = 'Ireland'
      @parser.should_receive(:add_to_alternative_titles).with(@membership)
      @parser.region_sits_in_lords?(@membership, @attributes)
    end
    
    it 'should return true for a Scottish title with a membership ending after the 1963 Peerage Act' do 
      @membership[:end_date] = @parser.peerage_act_1963_date + 1
      @membership[:start_date] = @parser.peerage_act_1963_date - 5
      @attributes[:region] = 'Scotland'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_true
    end
      
    it 'should return false for a Scottish title with a membership ending before 1963' do 
      @membership[:end_date] = @parser.peerage_act_1963_date - 1
      @attributes[:region] = 'Scotland'
      @parser.region_sits_in_lords?(@membership, @attributes).should be_false
    end
    
    it 'should add Scottish title with a membership ending before 1963 as an alternative title' do 
      @membership[:end_date] = @parser.peerage_act_1963_date - 1
      @attributes[:region] = 'Scotland'
      @parser.should_receive(:add_to_alternative_titles).with(@membership)
      @parser.region_sits_in_lords?(@membership, @attributes)
    end
    
    it 'should set the start date of a Scottish title with a membership ending after the 1963 Peerage Act and a start date before the Act to the date of the 1963 Peerage Act' do 
      @membership[:end_date] = @parser.peerage_act_1963_date + 1
      @membership[:start_date] = @parser.peerage_act_1963_date - 5
      @attributes[:region] = 'Scotland'
      @parser.region_sits_in_lords?(@membership, @attributes)
      @membership[:start_date].should == @parser.peerage_act_1963_date
    end
    
    it 'should add the original Scottish title as an alternative title with the original dates if the dates have been modified for the Lords membership' do
      @membership[:end_date] = @parser.peerage_act_1963_date + 1
      @membership[:start_date] = @parser.peerage_act_1963_date - 5
      @attributes[:region] = 'Scotland'
      @parser.region_sits_in_lords?(@membership, @attributes)
      alternative_title = @parser.new_alternative_titles[@membership[:person_import_id]].first
      alternative_title[:start_date].should == @parser.peerage_act_1963_date - 5
    end
    
    it 'should raise an error for any other region' do
      @attributes[:region] = 'Other'
      lambda{ @parser.region_sits_in_lords?(@membership, @attributes) }.should raise_error('Unexpected region: Other')
    end
    
  end
  
  describe 'when parsing membership lines' do
    
    before do 
      @line = '&nbsp; 1st:&nbsp<a href="p10940.htm#i109391">James Louis Hamilton</a> (5 May 1808-2 Mar 1825)'
      @attributes = {:region => 'England'}
    end
  
    it 'should get the name of the person' do 
      @parser.parse_membership_line(@line, @attributes)[:name].should == 'James Louis Hamilton'
    end
  
    it 'should get the firstname of the person' do 
      @parser.parse_membership_line(@line, @attributes)[:firstname].should == 'James'
    end
    
    it 'should get the lastname of the person' do 
      @parser.parse_membership_line(@line, @attributes)[:lastname].should == 'Hamilton'
    end
    
    it 'should get the firstnames of the person' do 
      @parser.parse_membership_line(@line, @attributes)[:firstnames].should == 'James Louis'
    end
    
    it 'should return nil for a line without dates within the application span' do
      line = '&nbsp; 1st:&nbsp<a href="p10940.htm#i109391">James Hamilton</a> (5 May 1608-2 Mar 1625)'
      @parser.parse_membership_line(line, @attributes).should be_nil
    end
    
    it 'should get the start date of the membership' do 
      @parser.parse_membership_line(@line, @attributes)[:start_date].should == Date.new(1808, 5, 5)
    end
    
    it 'should set the estimated start date flag for the membership to false' do 
      @parser.parse_membership_line(@line, @attributes)[:estimated_start_date].should be_false
    end
    
    it 'should get the end date of the membership' do 
      @parser.parse_membership_line(@line, @attributes)[:end_date].should == Date.new(1825, 3, 2)
    end
    
    it 'should set the estimated end date flag for the membership to false' do 
      @parser.parse_membership_line(@line, @attributes)[:estimated_end_date].should be_false
    end
    
    it 'should get the number of the title' do 
      @parser.parse_membership_line(@line, @attributes)[:number].should == '1st'
    end
    
    it 'should get the url for the person page' do 
      @parser.parse_membership_line(@line, @attributes)[:url].should == 'p10940.htm#i109391'
    end
    
    it 'should get the title type for the person page' do 
      @parser.parse_membership_line(@line, @attributes)[:title_type].should == 'Peerage of England'
    end
 
    it 'should set the end date to nil when there is no end date' do 
      line = '&nbsp; 4th:&nbsp<a href="p1602.htm#i16018">Henry Charles McLaren</a> (4 Feb 2003- )'
      @parser.parse_membership_line(line, @attributes)[:end_date].should be_nil
    end
    
    it 'should return nil where there are no dates' do 
      line = '&nbsp; 6th:&nbsp<a href="p4746.htm#i47454">John Dinham</a>'
      @parser.parse_membership_line(line, @attributes).should be_nil
    end
    
    it 'should handle a period as the first date' do 
      line = '&nbsp; 8th:&nbsp<a href="p7069.htm#i70690">William Knollys</a> (bt 1793-1813-20 Mar 1834)'
      @parser.parse_membership_line(line, @attributes)[:start_date].should == Date.new(1793, 1, 1)
    end
    
    it 'should set the type of the membership' do 
      @parser.stub!(:peerage_type).and_return('test type')
      @parser.parse_membership_line(@line, @attributes)[:peerage_type].should == 'test type'
    end
    
    it 'should set the person import id of the membership' do 
      @parser.parse_membership_line(@line, @attributes)[:person_import_id].should == 10109391
    end
    
    it 'should handle a line with an accented character in it' do 
      line = '&nbsp; 1st:&nbsp<a href="p11718.htm#i117173">Philibert Chandée</a> (6 Jan 1486- )'
      @parser.parse_membership_line(line, @attributes)
    end
    
    it 'should parse a line with' do 
      line = '&nbsp;&nbsp<a href="p7401.htm#i74005">Richard Gerald Lyon-Dalberg-Acton</a> (17 Apr 2000- )'
      @parser.parse_membership_line(line, @attributes)
    end
    
  end
  
  describe 'when parsing dates' do 
    
    describe 'when handling "circa" form dates' do 

      before do 
        @date_string = 'c 1670'
      end
      
      it 'should set the date to the last day of the year given for an end date for a date with only a year' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:end_date].should == Date.new(1670, 12, 31)
      end

      it 'should set an estimated end date flag' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:estimated_end_date].should be_true
      end
      
      it 'should set the date to the first day of the year given for a start date for a date with only a year' do 
        @parser.get_date_attributes(@date_string, :start_date, {})[:start_date].should == Date.new(1670, 1, 1)
      end

      it 'should set an estimated start date flag' do 
        @parser.get_date_attributes(@date_string, :start_date, {})[:estimated_start_date].should be_true
      end
      
      it 'should' do 
        date_string = 'c 8 Oct 1992'
        @parser.get_date_attributes(date_string, :start_date, {})[:estimated_start_date].should be_true
      end
      
    end
    
    describe 'when handling "before" form dates' do 

      before do 
        @date_string = 'b 1683'
      end
      
      it 'should set the date to the first day of the year given for a date with only a year' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:end_date].should == Date.new(1683, 1, 1)
      end

      it 'should set an estimated end date flag' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:estimated_end_date].should be_true
      end
      
    end
    
    describe 'when handling "after" form dates' do 
      
      before do 
        @date_string = 'a 1667'
      end
      
      it 'should set the date to the last day of the year given for a date with only a year' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:end_date].should == Date.new(1667, 12, 31)
      end

      it 'should set an estimated end date flag' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:estimated_end_date].should be_true
      end
      
      describe 'when handling partial dates with month' do 
      
        before do 
          @date_string = 'a Nov 1974'
        end
        
        it 'should set the estimated flag to true' do 
          @parser.get_date_attributes(@date_string, :end_date, {})[:estimated_end_date].should be_true
        end
      
      end
  
    end
    
    describe 'when handling "between" form dates' do 
    
      before do 
        @date_string = 'bt 1596-1597'
      end
      
      it 'should set the date to the first day of the first year for a start date'  do 
        @parser.get_date_attributes(@date_string, :start_date, {})[:start_date].should == Date.new(1596, 1, 1)
      end
      
      it 'should set the date to the last day of the last year for an end date' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:end_date].should == Date.new(1597, 12, 31)
      end
      
      it 'should set the estimation flag to true' do 
        @parser.get_date_attributes(@date_string, :end_date, {})[:estimated_end_date].should be_true
      end
      
    end
    
  end
  
  describe 'when parsing biographical information' do 
    
    before do 
      @bio_info = "M, #29222, b. 14 October 1770, d. 15 February 1843"
    end
    
    it 'should get the gender of the person' do 
      @parser.parse_biographical_info(@bio_info)[:gender].should == 'M'
    end
  
    it 'should get the date of birth of the person' do 
      @parser.parse_biographical_info(@bio_info)[:date_of_birth].should == Date.new(1770, 10, 14)
    end
    
    it 'should get the date of death of the person' do 
      @parser.parse_biographical_info(@bio_info)[:date_of_death].should == Date.new(1843, 2, 15)
    end
    
    it 'should set the estimation flag to false if a date of birth is given' do 
     @parser.parse_biographical_info(@bio_info)[:estimated_date_of_birth].should be_false
    end

    it 'should set the estimation flag to false if a date of death is given' do 
     @parser.parse_biographical_info(@bio_info)[:estimated_date_of_death].should be_false
    end

    it 'should set the date of death to nil if no date of death is given' do 
      bio_info = 'M, #16018, b. 26 May 1948'
      @parser.parse_biographical_info(bio_info)[:date_of_death].should be_nil
    end
    
    it 'should set the date of birth to nil if no date of birth is given' do 
      bio_info = 'F, #28, d. 11 February 1821'
      @parser.parse_biographical_info(bio_info)[:date_of_birth].should be_nil
    end
    
    it 'should set the date of birth and date of death to nil if neither is given' do 
      bio_info = 'M, #233985'
      @parser.parse_biographical_info(bio_info)[:date_of_birth].should be_nil
    end
    
    it 'should set the year of death if one is given' do 
      bio_info = 'M, #13538, b. 2 December 1939, d. 1993'
      @parser.parse_biographical_info(bio_info)[:year_of_death].should == 1993
    end 
    
    it 'should set the estimation flag if only the year of death is given' do 
      bio_info = 'M, #13538, b. 2 December 1939, d. 1993'
      @parser.parse_biographical_info(bio_info)[:estimated_date_of_death].should be_true
    end
    
    it 'should set the year of birth if one is given' do 
       bio_info = 'M, #197460, b. 1881, d. 1964'
        @parser.parse_biographical_info(bio_info)[:year_of_birth].should == 1881
    end
     
    it 'should set the estimation flag if only the year of birth is given' do 
       bio_info = 'M, #197460, b. 1881, d. 1964'
       @parser.parse_biographical_info(bio_info)[:estimated_date_of_birth].should be_true
    end
    
  end
  
end