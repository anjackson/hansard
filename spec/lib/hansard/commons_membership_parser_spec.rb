require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsMembershipParser do 

  before do 
    @parser = Hansard::CommonsMembershipParser.new 'test/path'
  end
  
  describe 'when asked to convert a string to a date' do 
  
    it 'should return nil for an empty string' do 
      @parser.to_date("").should be_nil
    end
    
    it 'should return nil for the string "c 1747"' do 
      @parser.to_date("c 1747").should be_nil
    end
    
    it 'should return the date "16 Mar 1768" for "16 Mar 1768"' do 
      @parser.to_date("16 Mar 1768").should == Date.new(1768, 3, 16)
    end
    
  end
  
  describe 'when asked if multiple people match a membership' do 
    
    it 'should return true if there is one person found matching the name and exact date of death and one person found matching the name and estimated death year' do 
      Person.stub!(:find_all_by_name_and_date_of_death_exact).and_return(['a person'])
      Person.stub!(:find_all_by_name_and_death_year_estimated).and_return(['a person'])
      @parser.multiple_people?({}).should be_true
    end
    
    it 'should return false if there is only one person found matching the name and exact date of death' do 
      Person.stub!(:find_all_by_name_and_death_year_estimated).and_return(['a person'])
      @parser.multiple_people?({}).should be_false      
    end
    
  
  end
  
  describe 'when asked for the last commons membership id' do 
    
    it 'should return the first tab-separated element of the last line in the file converted to an integer' do 
      lines = ["1000\t1200\t24\n", "1001\t1200\t24\n"]
      mock_file = mock('file')
      @parser.stub!(:open).and_return(mock_file)
      mock_file.stub!(:readlines).and_return(lines)
      @parser.last_commons_membership_id.should == 1001
    end
  
  end
  
  describe 'when asked to save a person' do 
    
    before do 
      @person = {}
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
    end
  
    it 'should ask for the last people id' do 
      @parser.should_receive(:last_people_id).and_return(3)
      @parser.save_person(@person)
    end
  
  end
  
  describe 'when asked to save a membership' do 
    
    before do 
      @membership = {:start_date => Date.new(2004, 10, 21), 
                     :end_date => Date.new(2006, 7, 13)}
      @constituency = mock_model(Constituency, :import_id => 7)
      @person = mock_model(Person, :import_id => 8)
      @parser.stub!(:last_commons_membership_id).and_return(5)
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
    end
    
    it 'should ask for the last commons membership id' do 
      @parser.should_receive(:last_commons_membership_id).and_return(4)
      @parser.save_membership(@membership, @constituency, @person)
    end
    
    it 'should append a line to the file' do 
      @parser.save_membership(@membership, @constituency, @person)
      @string.should == "existing content\n6\t8\t7\t2004\t2004-10-21\t\t2006\t2006-07-13\n"
    end
    
  end
  
  describe 'when asked to clean element contents' do 
  
    it 'should return "William\nTyrwhitt-Drake" for "William\240\r\nTyrwhitt-Drake"' do 
      text = "<element>William\240\r\nTyrwhitt-Drake</element>"
      element = Hpricot(text).at('element')
      @parser.clean_element_contents(element).should == "William Tyrwhitt-Drake"
    end
    
  end
  
  describe 'when asked if a row is empty' do 
    
    it 'should return true for a row where all cells are empty' do 
      text = "<tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'></td>
       <td class=xl3921364></td>
       <td class=xl5021364></td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl5621364></td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.empty_row?(element).should be_true
    end
    
    it 'should return false for a row where not all cells are empty' do 
      text = "<tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'>21 Nov 1810</td>
       <td class=xl3921364></td>
       <td class=xl5721364 x:str=\"William Tyrwhitt-Drake  \">William
       Tyrwhitt-Drake<span style=\"mso-spacerun: yes\">  </span></td>
       <td class=xl3921364>21 Oct 1785</td>
       <td class=xl3921364>21 Dec 1848</td>
       <td class=xl5621364 x:num>63</td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.empty_row?(element).should be_false      
    end
  
  end
  
  describe 'when asked to return a date for a year' do 
    
    describe 'if there was a single election in that year' do 
      
      it 'should return the date of the election' do 
        election = mock_model(Election, :date => Date.new(1976, 1, 21))
        Election.stub!(:find_all_by_year).and_return([election])
        @parser.date_for_year(1976).should == election.date
      end
      
    end
  
    describe 'if there was more than one election in that year' do 
    
      it 'should return the date of the last election in that year' do
        first_election = mock_model(Election, :date => Date.new(1976, 1, 21))
        second_election = mock_model(Election, :date => Date.new(1976, 12, 21))
        Election.stub!(:find_all_by_year).and_return([first_election, second_election])
        @parser.date_for_year(1976).should == second_election.date
      end
      
    end
    
    describe 'if there were no elections in that year' do 
    
      it 'should return the last day of the year' do 
        Election.stub!(:find_all_by_year).and_return([])
        @parser.date_for_year(1976).should == Date.new(1976, 12, 31)
      end
      
    end
    
  end
  
  describe 'when parsing' do 
  
    it 'should handle the constituency text if some is parsed from the row' do 
      @parser.stub!(:constituency_text).and_return('text')
      @parser.should_receive(:handle_constituency_start_text).with('text')
      @parser.parse('<tr><td></td></tr>')
    end
  
    it 'should handle the constituency end text if some is parsed from the row' do 
      @parser.stub!(:constituency_text).and_return(nil)
      @parser.stub!(:constituency_end_text).and_return('text')     
      @parser.should_receive(:handle_constituency_end_text).with('text')
      @parser.parse('<tr><td></td></tr>')
    end
    
    it 'should handle the row as a membership row if it does not contain constituency or constituency end text' do 
  
      @parser.should_receive(:handle_membership_row)
      @parser.parse('<tr><td></td></tr>')
    end
    
    it 'should handle the start of a constituency at the end of some constituency text' do 
      @parser.stub!(:constituency_text).and_return(nil)
      @parser.stub!(:constituency_end_text).and_return(nil)
      @parser.in_constituency_start = true
      @parser.should_receive(:handle_constituency_start)
      @parser.parse('<tr><td></td></tr>')
    end
    
    it 'should handle the end of a constituency at the end of some constituency end text' do 
      @parser.stub!(:constituency_text).and_return(nil)
      @parser.stub!(:constituency_end_text).and_return(nil)
      @parser.in_constituency_end = true
      @parser.should_receive(:handle_constituency_end)
      @parser.parse('<tr><td></td></tr>')
    end
    
    it 'should remove any empty html comment strings' do 
      @parser.parse('<!-------->')
      @parser.html.to_s.should == ''
    end
    
    it 'should remove any spans from the html' do 
      @parser.parse('<span></span>')
      @parser.html.to_s.should == ''
    end
    
  end
  
  describe 'when getting constituency classes' do 
    
    it 'should set a class defined in the style tag as having a yellow background as a constituency class' do
      text = '<style id="Acommons1_21364_Styles">
      <!--table
      .xl4121364
      	{padding-top:1px;
      	padding-right:1px;
      	font-family:Verdana, sans-serif;
      	mso-font-charset:0;
      	mso-number-format:"General_\)";
      	text-align:center;
      	vertical-align:bottom;
      	border:1.0pt solid windowtext;
      	background:yellow;
      	mso-pattern:auto none;
      	mso-protection:unlocked visible;
      	white-space:nowrap;}
      	-->
        </style>'
      @parser.html = Hpricot(text)
      @parser.get_constituency_classes
      @parser.constituency_classes.should == ['.xl4121364']
    end
    
    it 'should set a class defined in the style tag as not having a yellow background, but having a border and blue text as a constituency end class' do 
      text = '<style id="Acommons1_21364_Styles">
      <!--table
      .xl4621364
      	{padding-top:1px;
      	padding-right:1px;
      	mso-font-charset:0;
      	color:blue;
      	mso-number-format:"dd\\ mmm\\ yyyy";
      	text-align:center;
      	vertical-align:bottom;
      	border:1.0pt solid windowtext;
      	mso-background-source:auto;
      	mso-pattern:auto;
      	mso-protection:unlocked visible;
      	white-space:nowrap;}
      	-->
        </style>'
        @parser.html = Hpricot(text)
        @parser.get_constituency_classes
        @parser.constituency_end_classes.should == ['.xl4621364']
    end
    
  end
  
  describe 'when adding a membership to the list of memberships' do 
    
    before do 
      @parser.stub!(:clean_current_membership_name)
      @parser.stub!(:parse_current_membership_date)
      @parser.current_membership = {:name => ''}
    end
    
    it 'should clean the current membership name' do 
      @parser.should_receive(:clean_current_membership_name)
      @parser.add_membership_to_memberships
    end
    
    it 'should parse the dates for the start date, end date, date of birth and date of death values' do 
      @parser.should_receive(:parse_current_membership_date).with(:start_date)
      @parser.should_receive(:parse_current_membership_date).with(:end_date)
      @parser.should_receive(:parse_current_membership_date).with(:date_of_birth)
      @parser.should_receive(:parse_current_membership_date).with(:date_of_death) 
      @parser.add_membership_to_memberships           
    end
    
    describe 'when in a membership set' do 
      
      before do 
        @parser.in_membership_set = true
      end
      
      it 'should not treat the membership as a consecutive membership' do 
        @parser.should_not_receive(:handle_consecutive_membership)
        @parser.handle_membership_row('test row')
      end

      it 'should handle the membership as a one of a set' do 
        @parser.should_receive(:handle_concurrent_membership)
        @parser.add_membership_to_memberships
      end
    
    end
    
  end
  
  describe 'when handling a concurrent membership' do 
    
    it 'should give the current and last memberships a set key with the value being their start dates' do 
      @parser.memberships = [{:name => 'last membership', :start_date => Date.new(2004, 1, 1)}]
      @parser.current_membership = {:name => 'current membership', :start_date => Date.new(2004, 1, 1)}
      @parser.handle_concurrent_membership
      @parser.memberships.last[:set].should == Date.new(2004, 1, 1)
      @parser.current_membership[:set].should == Date.new(2004, 1, 1)
    end
    
  end
  
  describe 'when handling a consecutive membership' do 

    it 'should set the end date of the last membership to the start date of this membership if the last membership has the same constituency and no end date' do 
      @parser.stub!(:current_member_same_constituency).and_return(true)
      @parser.memberships = [{:name => 'last membership', :end_date => nil}]
      @parser.current_membership = {:name => 'current membership', :start_date => Date.new(1654, 1, 2)}
      @parser.handle_consecutive_membership
      @parser.memberships.last[:end_date].should == Date.new(1654, 1, 2)
    end
    
    describe 'when the last membership is one of a membership set' do 
    
      it 'should set the end date of any membership in that set to the start date of this membership if they have no end date and the same constituency' do 
        @parser.stub!(:current_member_same_constituency).and_return(true)
        first_membership = {:end_date => nil}
        set_membership_one = {:end_date => nil, :set => Date.new(1290, 1, 2)}
        set_membership_two = {:end_date => Date.new(1291, 4, 3), :set => Date.new(1290, 1, 2)}
        @parser.memberships = [first_membership, set_membership_one, set_membership_two]
        @parser.current_membership = {:start_date => Date.new(1300, 5, 5)}
        @parser.handle_consecutive_membership
        set_membership_one[:end_date].should == Date.new(1300, 5, 5)
        set_membership_two[:end_date].should == Date.new(1291, 4, 3)
        first_membership[:end_date].should be_nil
      end
    
    end

  end
  
  describe 'when handling a membership row' do
    
    it 'should not add any membership data to the current member if there is no current constituency' do 
      row = Hpricot('<tr><td></td></tr>').at('tr')
      @parser.stub!(:current_constituency).and_return(nil)
      @parser.should_not_receive(:add_membership_data_from_row)
      @parser.handle_membership_row('test row')
    end
    
    describe 'when the row has dates, and the current membership also has dates' do 
    
      before do 
        @parser.stub!(:current_constituency).and_return('test')
        @membership = {:name => 'test',
                       :date_of_birth => nil, 
                       :date_of_death => nil, 
                       :start_date => '1 Jan 2004', 
                       :constituency => 'test constituency'}
        @parser.current_membership = @membership
        @parser.stub!(:empty_row?).and_return(false)
        @parser.stub!(:row_data).and_return('row with dates')
        @parser.stub!(:has_dates?).with('row with dates').and_return(true)
        @parser.stub!(:has_dates?).with(@membership).and_return(true)
        @parser.stub!(:add_membership_data_from_row)
        @parser.stub!(:set_start_date_from_last)
      end
      
      it 'should add the current membership to the memberships list' do 
        @parser.should_receive(:add_membership_to_memberships)
        @parser.handle_membership_row('test row')
      end
      
      it 'should add data from the row to the new current membership' do 
        @parser.should_receive(:add_membership_data_from_row).with('test row')
        @parser.handle_membership_row('test row')
      end
      
      it 'should set the start date of the new current membership to the start date of the last one' do 
        @parser.should_receive(:set_start_date_from_last)
        @parser.handle_membership_row('test row')
      end
      
    end
    
    describe 'when the row has data and the current membership does not have dates' do 
      
      before do 
        @parser.stub!(:current_constituency).and_return('test')
        @membership = {:name => 'test',
                       :date_of_birth => nil, 
                       :date_of_death => nil, 
                       :start_date => '1 Jan 2004', 
                       :constituency => 'test constituency'}
        @parser.stub!(:current_membership).and_return(@membership)
        @parser.stub!(:empty_row?).and_return(false)
        @parser.stub!(:row_data).and_return('row with dates')
        @parser.stub!(:has_dates?).with('row with dates').and_return(true)
        @parser.stub!(:has_dates?).with(@membership).and_return(false)
      end
      
      it 'should add the row data to the current membership' do 
        @parser.should_receive(:add_membership_data_from_row).with('test row')
        @parser.handle_membership_row('test row')
      end
    
    end
    
    describe 'when there is a current membership with a name and the row being handled is empty' do 

      before do 
        @parser.stub!(:current_constituency).and_return('test')
        @membership = {:name => 'test',
                       :date_of_birth => nil, 
                       :date_of_death => nil, 
                       :start_date => '1 Jan 2004', 
                       :constituency => 'test constituency'}
        @parser.stub!(:current_membership).and_return(@membership)
        @parser.stub!(:empty_row?).and_return(true)
        @memberships = mock('memberships')
        @parser.stub!(:memberships).and_return(@memberships)
        @memberships.stub!(:<<)
        @memberships.stub!(:last).and_return(nil)
      end
      
      it 'should add the current member to its list of memberships' do 
        @memberships.should_receive(:<<).with(@membership)
        @parser.handle_membership_row('test row')
      end
      
      it 'should set the current member to an empty hash' do
        @parser.stub!(:new_membership).and_return({:new => :membership}) 
        @parser.should_receive(:current_membership=).with({:new => :membership})
        @parser.handle_membership_row('test row')
      end

      it 'should set the end date of the previous membership to the start date of this membership if the constituency for both is the same' do 
        previous_membership = {:name => 'test previous', 
                               :constituency => 'test constituency'}
        @memberships.stub!(:last).and_return(previous_membership)
        @parser.handle_membership_row('test row')
        previous_membership[:end_date].should == Date.new(2004, 1, 1)
      end
      
    end

  end
  
  describe 'when asked for constituency matches' do 
    
    before do 
      @parser.stub!(:parse)
      Constituency.stub!(:find_by_name_and_years).and_return([])
      @name = 'test constituency (more info)'
      @start_date = Date.new(1882, 1, 1)
      @end_date = Date.new(1883,1, 1)
    end
    
    it 'should parse its data file if not already parsed' do
      @parser.should_receive(:parse)
      @parser.calculate_constituency_matches
    end
  
    it 'should add a constituency from each parsed membership' do 
      membership_one = mock('membership')
      membership_two = mock('membership')
      @parser.parsed = true
      @parser.memberships = [membership_one, membership_two]
      @parser.should_receive(:add_constituency_match_from_parsed_membership).with(membership_one)
      @parser.should_receive(:add_constituency_match_from_parsed_membership).with(membership_two)
      @parser.calculate_constituency_matches
    end
    
    it 'should look for constituency matches by name and years' do
      constituency_key = [@name, @start_date, @end_date]
      @parser.constituencies = {constituency_key => [5]}
      Constituency.should_receive(:find_by_name_and_years).with({:name => @name, 
                                                                 :start_date => @start_date, 
                                                                 :end_date => @end_date}).and_return([])
      @parser.calculate_constituency_matches
    end
    
    it 'should ignore the constituency start year when matching if the start year is before 1833' do 
      start_date = Date.new(1600, 1, 1)
      constituency_key = [@name, start_date, @end_date]
      @parser.constituencies = {constituency_key => [5]}
      Constituency.should_receive(:find_by_name_and_years).with({:name => @name, 
                                                                 :end_date => @end_date}).and_return([])
      @parser.calculate_constituency_matches
    end
    
    
    it 'should look for constituency matches by cleaned up name and years if there are no matches by name and years' do 
      Constituency.stub!(:find_by_name_and_years).and_return([])
      constituency_key = [@name, @start_date, @end_date]
      @parser.constituencies = {constituency_key => [5]}
      Constituency.should_receive(:find_by_name_and_years).with({:name => 'test constituency', 
                                                                 :start_date => @start_date, 
                                                                 :end_date => @end_date}).and_return([])
      @parser.calculate_constituency_matches
    end
    
  end
  
  describe 'when cleaning a constituency name' do 
    
    it 'should return "Aldborough" for "Aldborough (Yorkshire)"' do 
      @parser.clean_constituency_name("Aldborough (Yorkshire)").should == "Aldborough"
    end
    
    it 'should return "Buteshire and Caithness" for "Buteshire & Caithness"' do 
      @parser.clean_constituency_name("Buteshire & Caithness").should == "Buteshire and Caithness"
    end
    
    it 'should return "BRISTOL SOUT HEAST" for "BRISTOL SOUTHEAST"' do 
      @parser.clean_constituency_name("BRISTOL SOUTHEAST").should == "BRISTOL SOUTH EAST"
    end
    
    it 'should return "COVENTRY NORTH WEST" for "COVENTRY NORTHWEST"' do 
      @parser.clean_constituency_name("COVENTRY NORTHWEST").should == "COVENTRY NORTH WEST"
    end
    
    it 'should return "LONGFORD" for "LONGFORD COUNTY"' do
      @parser.clean_constituency_name("LONGFORD COUNTY").should == "LONGFORD"
    end
    
    it 'should return "LANARKSHIRE NORTHERN" for "LANARKSHIRE NORTH"' do 
      @parser.clean_constituency_name("LANARKSHIRE NORTH").should == "LANARKSHIRE NORTHERN"
    end
    
    it 'should return "LANCASHIRE NORTH EASTERN" for "LANCASHIRE NORTH-EAST"' do 
      @parser.clean_constituency_name("LANCASHIRE NORTH-EAST").should == "LANCASHIRE NORTH EASTERN"
    end
    	
  end
  
  describe 'when matching memberships' do 
    
    before do 
      @commons_membership = mock_model(CommonsMembership)
      @membership = {:name => 'test membership', 
                     :start_date => Date.new(1855, 1, 1), 
                     :end_date => Date.new(1857, 1, 1)}
      @constituency = mock_model(Constituency, :commons_memberships => [@commons_membership])
      @commons_membership.stub!(:match_by_overlap_and_name)
    end
    
    it 'should return a membership if the constituency has a membership whose dates overlap the parsed one and whose person has the same lastname as that parsed' do 
      @commons_membership.stub!(:match_by_year).and_return(false)
      @commons_membership.stub!(:match_by_overlap_and_name).with(@membership).and_return(true)
      @parser.match_membership(@membership, @constituency).should == @commons_membership
    end
    
    it 'should return false if the membership ends before 1832' do 
      @membership[:end_date] = Date.new(1820, 1, 1)
      @parser.match_membership(@membership, @constituency).should be_false
    end
  
  end
  
  
  describe 'when adding memberships' do 
    
    it 'should try to add each of the parsed memberships where the start date is before 1900' do
      pre_1900_membership = {:name => 'test membership', :start_date => Date.new(1899, 12, 21)}
      post_1900_membership = {:name => 'test membership', :start_date => Date.new(1900, 1, 1)}
      @parser.stub!(:parse)
      @parser.memberships = [pre_1900_membership, post_1900_membership]
      @parser.should_receive(:add_membership).with(pre_1900_membership)
      @parser.should_not_receive(:add_membership).with(post_1900_membership)
      @parser.add_memberships
    end
    
    it 'should not try and match memberships if the constituency has not been matched' do 
      membership = {:name => 'test membership', :constituency => 'test constituency'}
      @parser.constituencies = {}
      @parser.should_not_receive(:match_membership)
      @parser.add_membership(membership)      
    end
    
    describe 'when the constituency has been matched' do 
    
      before do 
        @membership = {:name => 'test membership', 
                       :constituency => 'test constituency', 
                       :start_date => Date.new(1981, 1, 1), 
                       :end_date => Date.new(1982, 3, 4)}
        @parser.stub!(:constituency_matches).and_return({['test constituency', 1800, 1985] => 2})
        @constituency = mock_model(Constituency, :null_object => true)
        Constituency.stub!(:find_by_import_id).and_return(@constituency)
      end
      
      it 'should load the constituency model by import id if the constituency has been matched' do
        Constituency.should_receive(:find_by_import_id).with(2).and_return(@constituency)
        @parser.add_membership(@membership)
      end
    
      it 'should try and match the membership information and constituency with a commons membership in the database ' do
        @parser.should_receive(:match_membership).with(@membership, @constituency)
        @parser.add_membership(@membership)
      end
      
      describe 'when the membership cannot be matched with an existing membership' do 
      
        before do 
          @parser.stub!(:match_membership)
          @parser.stub!(:save_membership)
          @person = mock_model(Person, :null_object => true)
        end
        
        it 'should try and match the person exactly' do 
          Person.should_receive(:match_person_exact).with(@membership)
          @parser.add_membership(@membership)
        end
        
        it 'should save the membership with the constituency and person if the person is matched exactly' do 
          Person.stub!(:match_person_exact).and_return(@person)
          @parser.should_receive(:save_membership).with(@membership, @constituency, @person)
          @parser.add_membership(@membership)
        end
      
        it 'should try and match the person loosely if an exact match fails' do
          Person.stub!(:match_person_exact).and_return(nil)
          Person.should_receive(:match_person_loose).with(@membership)
          @parser.add_membership(@membership)
        end
        
        it 'should not try a loose match if the exact match succeeds' do 
          Person.stub!(:match_person_exact).and_return(@person)
          Person.should_not_receive(:match_person_loose)
          @parser.add_membership(@membership)
        end
        
        it 'should save the membership with the constituency and person if the person is matched loosely' do 
          Person.stub!(:match_person_loose).and_return(@person)
          @parser.should_receive(:save_membership).with(@membership, @constituency, @person)
          @parser.add_membership(@membership)
        end
      
        describe 'when the person does not exist already' do 
      
          before do 
            Person.stub!(:match_person_loose)
            Person.stub!(:match_person_exact)
          end
          
          it 'should add an item to the hash of new people representing this person' do 
            @membership[:firstname] = 'test'
            @membership[:firstnames] = 'test testy'
            @membership[:lastname] = 'membership'
            @membership[:honorific] = 'Mr'
            @membership[:year_of_birth] = 1965
            @membership[:date_of_birth] = Date.new(1965, 1, 2)
            @membership[:year_of_death] = 1994
            @membership[:date_of_death] = Date.new(1994, 1, 2)
            @parser.add_membership(@membership)
            @parser.new_people.should ==  {["test testy", 'test', 'membership', 
                                            1965, Date.new(1965, 1, 2), 1994, Date.new(1994, 1, 2)] => 
                                          [@membership.merge(:constituency_model=>@constituency)]}
          end
          
        end
      
      end
    
    end
    
  end
  
  describe 'when asked to find a constituency in the loaded constituency matches for a membership' do
    
    before do 
      @membership = {:constituency => 'test constituency', 
                     :start_date => Date.new(1885, 1, 1), 
                     :end_date => Date.new(1896, 11, 5)}
    end
    
    it 'should return nil if the membership is missing a start date' do 
      @membership[:start_date] = nil
      @parser.find_constituency(@membership).should be_nil
    end
      
    it 'should return nil if the membership is missing an end date' do 
      @membership[:end_date] = nil
      @parser.find_constituency(@membership).should be_nil
    end
    
    it 'should return a constituency that matches by name and dates' do 
      @parser.stub!(:constituency_matches).and_return({['test constituency', 1800, 1900] => 5})
      @parser.find_constituency(@membership).should == 5
    end
    
    it 'should clean up bad bracket syntax in the constituency' do 
      @parser.stub!(:constituency_matches).and_return({['LONDON (MIDDLESEX)', 1800, 1900] => 5})
      @membership[:constituency] = 'LONDON(MIDDLESEX)'
      @parser.find_constituency(@membership).should == 5
    end
    
  end
  
  describe 'when saving constituency matches' do 
  
    before do 
      @mock_file = mock('file', :write => true)
      @parser.stub!(:open).and_yield(@mock_file)
      @parser.stub!(:last_constituency_id).and_return(2)
      @first_constituency = mock_model(Constituency, :name => 'first constituency', 
                                                     :import_id => 7, 
                                                     :start_year => 1832, 
                                                     :end_year => 1900)
      @second_constituency = mock_model(Constituency, :name => 'second constituency', 
                                                      :import_id => 12, 
                                                      :start_year => 1832, 
                                                      :end_year => 1900)
      @parser.constituencies = {['test constituency', Date.new(1801, 1, 1), Date.new(1820, 4, 5)] => []}
    end
    
    it 'should not save constituencies that begin after 1900' do 
      @parser.constituencies = {['test constituency', Date.new(1901, 1, 1), Date.new(1920, 4, 5)] => []}
      @mock_file.should_not_receive(:write)
      @parser.save_constituency_matches
    end
    
    it 'should write a new constituency record for a constituency with no matches to existing constituencies' do 
      @mock_file.should_receive(:write).with("3\tTest Constituency\t1801\t1820\n")
      @parser.save_constituency_matches
    end
    
    it 'should not write a new constituency record for a constituency that ends after 1832' do 
      @parser.constituencies = {['test constituency', Date.new(1841, 1, 1), Date.new(1850, 4, 5)] => []}
      @mock_file.should_not_receive(:write).with("3\tTest Constituency\t1841\t1850\n")
      @parser.save_constituency_matches
    end
    
    it 'should write a constituency match record for a constituency with no matches to existing constituencies' do 
      @mock_file.should_receive(:write).with("test constituency\t1801\t1820\tTest Constituency\t3\n")
      @parser.save_constituency_matches
    end
    
    it 'should not write a new constituency record for a constituency ending after 1830 with matches' do 
      
      @parser.constituencies = {['test constituency', 
                                 Date.new(1820, 1, 1), 
                                 Date.new(1833, 4, 5)] => [@first_constituency]}
      @mock_file.should_not_receive(:write).with("3\tTest Constituency\t1801\t1820\n")
      @parser.save_constituency_matches
    end
    
    it 'should write a new constituency record for a constituency ending before 1830 with matches' do 
      
      @parser.constituencies = {['test constituency', 
                                 Date.new(1801, 1, 1), 
                                 Date.new(1820, 4, 5)] => [@first_constituency]}
      @mock_file.should_receive(:write).with("3\tTest Constituency\t1801\t1820\n")
      @parser.save_constituency_matches
    end
    
    it 'should write a constituency match record for a constituency with matches to only one existing constituency' do 
      @parser.constituencies = {['test constituency', 
                                 Date.new(1801, 1, 1), 
                                 Date.new(1833, 4, 5)] => [@first_constituency]}
      @mock_file.should_receive(:write).with("test constituency\t1801\t1833\tfirst constituency\t7\n")
      @parser.save_constituency_matches
    end
    
    it 'should not write a constituency match record or a new constituency record for a constituency ending after 1832 with matches to more than one existing constituency' do 
      @parser.constituencies =  {['test constituency', 
                                  Date.new(1801, 1, 1), 
                                  Date.new(1833, 4, 5)] => [@first_constituency, @second_constituency]}
      @mock_file.should_not_receive(:write)
      @parser.save_constituency_matches 
    end
    
    it 'should not write a match record if the constituency to be matched has a start year after 1832 and it does not match the start date of the prospective match' do 
      @first_constituency.stub!(:start_year).and_return(1840)
      @parser.constituencies = {['test constituency', 
                                 Date.new(1844, 1, 1), 
                                 Date.new(1855, 4, 5)] => [@first_constituency]}
      @mock_file.should_not_receive(:write).with("test constituency\t1844\t1855\tfirst constituency\t7\n")
      @parser.save_constituency_matches
    end
    
    it 'should exclude any matches with a compass direction (North, South etc.) mismatch' do 
      matches = []
      @parser.constituencies = {['test constituency', 
                                 Date.new(1801, 1, 1), 
                                 Date.new(1820, 4, 5)] => matches}
      @parser.should_receive(:exclude_compass_mismatches).with('test constituency', matches).and_return([])
      @parser.save_constituency_matches
    end
     
  end
  
  describe 'when asked to exclude compass mismatches from a list of constituency matches' do 
    
    it 'should exclude a match where the name has "South" in it and the match does not' do 
      match = mock_model(Constituency, :name => 'Morden')
      @parser.exclude_compass_mismatches('Morden South', [match]).should == []
    end
    
    it 'should exclude a match where the match has "South" in it and the name does not' do
      match = mock_model(Constituency, :name => 'Morden North')
      @parser.exclude_compass_mismatches('Morden South', [match]).should == []
    end
    
    it 'should not exclude a match if both the name and the match contain "North"' do 
      match = mock_model(Constituency, :name => 'Morden North')
      @parser.exclude_compass_mismatches('Morden North', [match]).should == [match]
    end

    it 'should not exclude a match if neither the match or the name contain "North"' do 
      match = mock_model(Constituency, :name => 'Morden')
      @parser.exclude_compass_mismatches('Morden', [match]).should == [match]
    end
    
  end
  
  describe 'when loading constituency matches' do 
    
    it 'should parse each line of the constituency file' do
      @lines = [1, 2, 3, 4, 5]
      File.stub!(:new).and_return(@lines)
      @parser.should_receive(:parse_constituency_match_line).exactly(5).times
      @parser.load_constituency_matches
    end
    
    it 'should add a key value pair to constituency_matches for each line' do 
      line = "test constituency\t2004\t2005\texisting constituency\t5"
      File.stub!(:new).and_return([line])
      @parser.load_constituency_matches
      @parser.constituency_matches.should == {['test constituency', 
                                               2004, 
                                               2005] => 5}
    end
    
  end
  
  describe 'when adding a constituency match from a parsed membership' do 
    
    before do 
      @constituency_info = ['test constituency', Date.new(1883, 1, 1), Date.new(1884, 12, 31)]
      @constituency = mock_model(Constituency, :name => 'test constituency')
      @existing_membership = mock_model(CommonsMembership, :constituency => @constituency,
                                                          :start_date => Date.new(1884, 4, 10), 
                                                          :end_date => Date.new(1884, 12, 1))
      @existing_membership.stub!(:match_by_year).and_return(true)
      person = mock_model(Person, :commons_memberships => [@existing_membership])
      @parser.stub!(:match_people).and_return([person])
      @parser.constituencies = {@constituency_info => []}
    end
    
    it 'should match the person who has the membership with known people' do 
      membership = {:test => :membership}
      @parser.should_receive(:match_people).with(membership).and_return([])
      @parser.add_constituency_match_from_parsed_membership(membership)
    end
    
    it 'should add a constituency match for each person matched with a known membership starting before 1920 matching the parsed membership that is within the constituency dates' do 
      parsed_membership = {:constituency => 'test constituency'}
      @parser.add_constituency_match_from_parsed_membership(parsed_membership)
      @parser.constituencies.should == { @constituency_info => [@constituency] }
    end
    
    it 'should not add constituency matches for memberships starting after 1920' do 
      @existing_membership.stub!(:start_date).and_return(Date.new(1923, 1, 4))
      parsed_membership = {:constituency => 'test constituency'}
      @parser.add_constituency_match_from_parsed_membership(parsed_membership)
      @parser.constituencies.should == {@constituency_info => []}
    end
  
  end
  
  describe 'when asked for a fuzzy name match' do 
  
    it 'should return true for "LANARKSHIRE SOUTH" and "LANARK SOUTH"' do 
      @parser.fuzzy_name_match("LANARKSHIRE SOUTH", "LANARK SOUTH").should be_true
    end
    
    it 'should return true for "LANARK SOUTH" and "LANARKSHIRE SOUTH"' do 
      @parser.fuzzy_name_match("LANARK SOUTH", "LANARKSHIRE SOUTH").should be_true
    end
    
    it 'should return true for "SOUTH LANARKSHIRE" and "LANARK SOUTH"' do 
      @parser.fuzzy_name_match("SOUTH LANARKSHIRE", "LANARK SOUTH").should be_true
    end
     
  end
  
  describe 'when asked to match constituency information to a membership' do 
  
    before do 
      @constituency = mock_model(Constituency, :name => 'test constituency')
      @constituency_info = ['test constituency', Date.new(1883, 1, 1), Date.new(1884, 12, 31)]
      @membership = mock_model(CommonsMembership, :constituency => @constituency,
                                                  :start_date => Date.new(1884, 4, 10), 
                                                  :end_date => Date.new(1884, 12, 1))
    end
    
    it 'should return false unless there is a fuzzy name match between the constituency and the prospective match' do 
      @parser.stub!(:fuzzy_name_match).and_return(false)
      @parser.match_constituency(@constituency_info, @membership).should be_false
    end
    
    it 'should return false if the constituency ends before the membership starts' do 
      @parser.stub!(:fuzzy_name_match).and_return(true)
      @constituency_info = ['test constituency', Date.new(1883, 1, 1), Date.new(1883, 12, 31)]
      @parser.match_constituency(@constituency_info, @membership).should be_false
    end
    
    it 'should return false if the membership ends before the constituency starts' do 
      @parser.stub!(:fuzzy_name_match).and_return(true)
      @constituency_info = ['test constituency', Date.new(1885, 1, 1), Date.new(1885, 12, 31)]
      @parser.match_constituency(@constituency_info, @membership).should be_false
    end
    
    it 'should return true if there is a fuzzy name match and the constituency and member dates overlap' do 
      @parser.stub!(:fuzzy_name_match).and_return(true)
      @parser.match_constituency(@constituency_info, @membership).should be_true
    end
    
    it 'should return true for a name "LONDON (MIDDLESEX)" (1660-03-27 - 1950-02-23) and a membership for "City of London" between 1892-07-04 and 1906-02-14' do 
      constituency = mock_model(Constituency, :name => 'City of London')
      membership = mock_model(CommonsMembership, :constituency => constituency, 
                                                 :start_date => Date.new(1892, 7, 4), 
                                                 :end_date => Date.new(1906, 2, 14))
      constituency_info = ["LONDON (MIDDLESEX)", Date.new(1660, 3, 27), Date.new(1950, 2, 23)]
      @parser.match_constituency(constituency_info, membership).should be_true
    end
    
  end
  
  describe 'when adding name parts to a membership' do 

    it 'should add firstname "George" and lastname "Hall" when parsed name is "George Henry Hall,later Viscount Hall"' do 
      name = 'George Henry Hall,later Viscount Hall'
      attributes = {:name => name}
      @parser.add_name_parts(attributes)
      attributes.should == {:firstname => 'George', :lastname => 'Hall', :firstnames => 'George Henry', :name => name, :honorific => nil}
    end

    it 'should add firstname "Priscilla" and lastname "Grant" when parsed name is "Priscilla Jean Fortescue Grant (later Buchan),later Baroness Tweedsmuir"' do 
      name = 'Priscilla Jean Fortescue Grant (later Buchan),later Baroness Tweedsmuir'
      attributes = {:name => name}
      @parser.add_name_parts(attributes)
      attributes.should == {:firstname => 'Priscilla', :lastname => 'Grant', :firstnames => 'Priscilla Jean Fortescue', :name => name, :honorific => nil}
    end
    
  end
  
  describe 'when asked to filter memberships for dates' do 

    before do 
      @too_early = { :start_date => FIRST_DATE - 5, :end_date => FIRST_DATE - 4 }
      @too_late = { :start_date => LAST_DATE + 3, :end_date => LAST_DATE + 5 }
      @inside = { :start_date => FIRST_DATE + 5, :end_date => LAST_DATE - 4 }
      @early_overlapping = { :start_date => FIRST_DATE - 4, :end_date => FIRST_DATE + 4 }
      @late_overlapping = { :start_date => LAST_DATE - 3, :end_date => LAST_DATE + 4 }
      @no_start_date = { :start_date => nil, :end_date => LAST_DATE - 3 }
      @no_end_date = { :start_date => FIRST_DATE + 4, :end_date => nil }
      @memberships = [@too_early, 
                      @too_late, 
                      @inside, 
                      @early_overlapping, 
                      @late_overlapping, 
                      @no_start_date, 
                      @no_end_date]
      @parser.memberships = @memberships
      @filtered_memberships = @parser.filter_memberships_for_dates
    end

    it 'should remove a membership that ends before the period covered by the application starts' do
      @filtered_memberships.include?(@too_late).should be_false
    end
    
    it 'should remove a membership that begins after the period covered by the application ends' do 
      @filtered_memberships.include?(@too_early).should be_false
    end
    
    it 'should not remove a membership within the period covered by the application' do 
      @filtered_memberships.include?(@inside).should be_true
    end
    
    it 'should not remove a membership that starts before the period covered by the application but ends within it' do 
      @filtered_memberships.include?(@early_overlapping).should be_true
    end
    
    it 'should not remove a membership that ends after the period covered by the application but starts within it' do 
      @filtered_memberships.include?(@late_overlapping).should be_true
    end
    
    it 'should remove memberships without a start date' do 
      @filtered_memberships.include?(@no_start_date).should be_false
    end
    
  end
  
  describe 'when cleaning the name from the current membership' do
  
    it 'should clean the end date from the name "Thomas Tyrwhitt-Drake (to 1832)"' do 
      @parser.current_membership = {:name => 'Thomas Tyrwhitt-Drake (to 1832)', 
                                    :end_date => nil}
      @parser.clean_current_membership_name
      @parser.current_membership.should == {:name => "Thomas Tyrwhitt-Drake", 
                                            :end_date => "1832-12-31" }
    end
    
    it 'should clean the end date from the name "John Steel(to Apr 1868)"' do 
      @parser.current_membership = {:name => 'John Steel(to Apr 1868)', 
                                    :end_date => nil}
      @parser.clean_current_membership_name
      @parser.current_membership.should == {:name => "John Steel", 
                                            :end_date => "1868-04-30" }
    end
    
    it 'should clean the end date from the name "Sir Thomas Erskine Perry (to 9 Aug 1859)"' do 
      @parser.current_membership = {:name => 'Sir Thomas Erskine Perry (to 9 Aug 1859)', 
                                    :end_date => nil}
      @parser.clean_current_membership_name
      @parser.current_membership.should == {:name => "Sir Thomas Erskine Perry", 
                                            :end_date => "1859-08-09" }
    end
    
    it 'should clean the extra text from the name "William Beckett-Denison For further information on this MP, see the note at the foot of this page."' do 
      @parser.current_membership = {:name => 'William Beckett-Denison For further information on this MP, see the note at the foot of this page.', 
                                    :end_date => nil}
      @parser.clean_current_membership_name
      @parser.current_membership.should == {:name => 'William Beckett-Denison', 
                                            :end_date => nil}
    end
    
    it 'should clean the extra text from the name "Aylesbury Nugent [ I ]"' do 
      @parser.current_membership = {:name => 'Aylesbury Nugent [ I ]', 
                                    :end_date => nil}
      @parser.clean_current_membership_name
      @parser.current_membership.should == {:name => 'Aylesbury Nugent', 
                                            :end_date => nil}
    end
    
  end
  
  describe 'when handling the end of a constituency' do 
  
    describe 'when the constituency end text is "REPRESENTATION REDUCED TO ONE MEMBER 1868"' do 
   
      it 'should not set the current constituency to nil' do
        @parser.constituency_end = "REPRESENTATION REDUCED TO ONE MEMBER 1868"
        @parser.should_not_receive(:current_constituency=)
        @parser.handle_constituency_end
      end
    
    end
    
    describe 'when the constituency end text is "NAME ALTERED TO "HORSHAM & WORTHING" 1918,BUT REVERTED 1945"' do 
    
      before do 
        @parser.constituency_end = '"NAME ALTERED TO "HORSHAM & WORTHING" 1918,BUT REVERTED 1945"'
        @parser.current_constituency = 'test constituency'
      end
      
      it 'should not set the current constituency to nil' do   
        @parser.should_not_receive(:current_constituency=).with(nil)
        @parser.handle_constituency_end
      end
  
      it 'should set the current constituency end to 31 Dec 1918' do 
        @parser.should_receive(:set_constituency_end_date).with(Date.new(1918, 12, 31))
        @parser.handle_constituency_end
      end
         
      it 'should add the current constituency to the current constituencies' do 
        @parser.handle_constituency_end
        @parser.constituencies.should == {["test constituency", nil, Date.new(1918, 12, 31)] => []}
      end
      
      it 'should set the constituency current constituency to the constituency name' do 
        @parser.handle_constituency_end
        @parser.current_constituency.should == 'test constituency'
      end
      
      it 'should set the new current constituency start date to 1 Jan 1945' do 
        @parser.handle_constituency_end
        @parser.current_constituency_start_date.should == Date.new(1945, 1, 1)
      end
      
    end
    
    describe 'when the constituency end text is "NAME ALTERED TO "LONDON & WESTMINSTER SOUTH" FEB 1974 BUT ALTERED BACK IN 1997"' do 
    
      it 'should not set the current constituency to nil' do 
        @parser.current_constituency = 'test constituency'
        @parser.stub!(:current_constituency=)
        @parser.constituency_end = 'NAME ALTERED TO "LONDON & WESTMINSTER SOUTH" FEB 1974 BUT ALTERED BACK IN 1997'
        @parser.should_not_receive(:current_constituency=).with(nil)
        @parser.handle_constituency_end
      end
      
    end

    describe 'when the constituency end text is "CONSTITUENCY ABOLISHED 1918"' do 
      
      before do 
        @parser.constituency_end = "CONSTITUENCY ABOLISHED 1918"
        @parser.current_constituency = 'test constituency'
        @parser.stub!(:current_constituency=)
      end
      
      it 'should set the current constituency to nil if the text is "CONSTITUENCY ABOLISHED 1918"' do 
        @parser.should_receive(:current_constituency=).with(nil)
        @parser.handle_constituency_end
      end
    
      it 'should not set the constituency interval flag' do 
        @parser.should_not_receive(:constituency_interval=)
        @parser.handle_constituency_end
      end
      
    end
    
    describe 'when the constituency end text is "CONSTITUENCY ABOLISHED 1922, BUT REVIVED 1983"' do 
      
      before do 
        @parser.constituency_end = "CONSTITUENCY ABOLISHED 1922, BUT REVIVED 1983"
        @parser.current_constituency = 'test constituency'
      end
      
      it 'should not set the current constituency to nil' do 
        @parser.should_not_receive(:current_constituency=).with(nil)
        @parser.handle_constituency_end
      end
      
      it 'should set the constituency end date' do 
        @parser.should_receive(:set_constituency_end_date)
        @parser.handle_constituency_end
      end
      
    end
    
    describe 'when the constituency end text is " SPLIT INTO 4 DIVISIONS 1885 SEE "ANTRIM EAST","ANTRIM MID", "ANTRIM NORTH" AND "ANTRIM SOUTH". CONSTITUENCIES REUNITED 1922"' do 
    
      before do 
        @parser.constituency_end = 'SPLIT INTO 4 DIVISIONS 1885 SEE "ANTRIM EAST","ANTRIM MID", "ANTRIM NORTH" AND "ANTRIM SOUTH". CONSTITUENCIES REUNITED 1922'
        @parser.current_constituency = 'test constituency'
      end
      
      it 'should not set the current constituency to nil' do 
        @parser.should_not_receive(:current_constituency=).with(nil)
        @parser.handle_constituency_end
      end
      
      it 'should set the constituency end date' do 
        @parser.should_receive(:set_constituency_end_date)
        @parser.handle_constituency_end
      end
      
    end
    
  end
  
  describe 'when parsing lines with two memberships starting on the same date' do 
  
    it 'should not set the end date of the first membership to the same date as the start date' do 
      text = "<tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'>23 Jun 1790</td>
       <td class=xl3921364></td>
       <td class=xl5721364>George Harry Grey,Baron Grey,later</td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl5621364></td>
      </tr>

      <tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'></td>
       <td class=xl3921364></td>
       <td class=xl5721364>Earl of Stamford</td>
       <td class=xl3921364>31 Oct 1765</td>
       <td class=xl3921364>26 Apr 1845</td>
       <td class=xl5621364 x:num>79</td>

      </tr>
      <tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'></td>
       <td class=xl3921364></td>
       <td class=xl5721364>Thomas Grenville</td>
       <td class=xl3921364>31 Dec 1755</td>
       <td class=xl3921364>17 Dec 1846</td>

       <td class=xl5621364 x:num>90</td>
      </tr>
      <tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3921364 style='height:12.75pt'></td>
       <td class=xl3921364></td>
       <td class=xl5021364></td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>

       <td class=xl5621364></td>
      </tr>
      "
      @parser.current_constituency = 'test constituency'
      @parser.stub!(:filter_memberships_for_dates)
      memberships = @parser.parse(text)
      memberships.first[:end_date].should be_nil
    end
  
    it 'should extract ambiguous name entries correctly ' do 
      pending do 
        text = "<tr height=17 style='height:12.75pt'>
          <td height=17 class=xl349329 style='height:12.75pt'>3 May 1831</td>
          <td class=xl349329></td>

          <td class=xl389329>Sir Henry Pollard Willoughby,3rd baronet</td>
          <td class=xl349329>17 Nov 1796</td>
          <td class=xl349329>23 Mar 1865</td>
          <td class=xl369329>68</td>
         </tr>
         <tr height=17 style='height:12.75pt'>
          <td height=17 class=xl349329 style='height:12.75pt'></td>

          <td class=xl349329></td>
          <td class=xl389329>Charles Compton Cavendish,later</td>
          <td class=xl349329></td>
          <td class=xl349329></td>
          <td class=xl369329></td>
         </tr>
         <tr height=17 style='height:12.75pt'>
          <td height=17 class=xl349329 style='height:12.75pt'></td>

          <td class=xl349329></td>
          <td class=xl389329>Baron Chesham</td>
          <td class=xl349329>28 Aug 1793</td>
          <td class=xl349329>10 Nov 1863</td>
          <td class=xl369329 x:num>70</td>
         </tr>
         <tr height=17 style='height:12.75pt'>

          <td height=17 class=xl349329 style='height:12.75pt'></td>
          <td class=xl349329></td>
          <td class=xl359329></td>
          <td class=xl349329></td>
          <td class=xl349329></td>
          <td class=xl369329></td>
         </tr>
        "
        @parser.current_constituency = 'test constituency'
        @parser.stub!(:filter_memberships_for_dates)
        memberships = @parser.parse(text)
        henry_willoughby = {:constituency => "test constituency",
                            :end_date => nil,
                            :name => "Sir Henry Pollard Willoughby,3rd baronet",
                            :firstname => 'Henry', 
                            :lastname => 'Willoughby',
                            :date_of_birth => Date.new(1796, 11, 17),
                            :date_of_death => Date.new(1865, 3, 23),
                            :start_date => Date.new(1831, 5, 3)}
                          
        charles_cavendish = {:constituency => "test constituency",
                             :end_date => nil,
                             :firstname => 'Charles', 
                             :lastname => 'Cavendish',
                             :name => "Charles Compton Cavendish,laterBaron Chesham",
                             :date_of_birth => Date.new(1793, 8, 28),
                             :date_of_death => Date.new(1863, 11, 10),
                             :start_date => Date.new(1831, 5, 3)}
        memberships.should == [henry_willoughby, charles_cavendish]
      end
    end
    
    it 'should extract two separate memberships with the same start date' do 
      text = '<tr height=17 style=\'height:12.75pt\'>

       <td height=17 class=xl3921364 style=\'height:12.75pt\'><span
       style="mso-spacerun: yes"> </span>1 Nov 1806</td>
       <td class=xl3921364></td>
       <td class=xl5721364>Henry Fynes<span style="mso-spacerun: yes">  </span>(to
       1826)</td>
       <td class=xl3921364>14 Jan 1781</td>
       <td class=xl3921364>24 Oct 1852</td>

       <td class=xl5621364 x:num>71</td>
      </tr>
      <tr height=17 style=\'height:12.75pt\'>
       <td height=17 class=xl3921364 style=\'height:12.75pt\'></td>
       <td class=xl3921364></td>
       <td class=xl5721364>Gilbert Jones</td>
       <td class=xl3921364><span style="mso-spacerun: yes">    </span>c 1758</td>

       <td class=xl3921364><span style="mso-spacerun: yes"> </span>7 Sep 1830</td>
       <td class=xl5621364></td>
      </tr>
      <tr height=17 style=\'height:12.75pt\'>
       <td height=17 class=xl3921364 style=\'height:12.75pt\'></td>
       <td class=xl3921364></td>
       <td class=xl5021364></td>
       <td class=xl3921364></td>

       <td class=xl3921364></td>
       <td class=xl5621364></td>
      </tr>
      <tr height=17 style=\'height:12.75pt\'>
       <td height=17 class=xl3921364 style=\'height:12.75pt\'>12 Oct 1812</td>
       <td class=xl3921364></td>
       <td class=xl5721364>Henry Dawkins</td>
       <td class=xl3921364><span style="mso-spacerun: yes">       </span>1765</td>

       <td class=xl3921364>25 Oct 1852</td>
       <td class=xl5621364 x:num>87</td>
      </tr>
      <tr height=17 style=\'height:12.75pt\'>
       <td height=17 class=xl3921364 style=\'height:12.75pt\'></td>
       <td class=xl3921364></td>
       <td class=xl5021364></td>
       <td class=xl3921364></td>

       <td class=xl3921364></td>
       <td class=xl5621364></td>
      </tr>
      '
      @parser.current_constituency = 'test constituency'
      @parser.stub!(:filter_memberships_for_dates)
      memberships = @parser.parse(text)
      henry_fynes = {:name => 'Henry Fynes', 
                     :firstname => 'Henry', 
                     :firstnames => 'Henry',
                     :lastname => 'Fynes',
                     :honorific => nil,
                     :constituency => 'test constituency', 
                     :set => Date.new(1806, 11, 1),
                     :start_date => Date.new(1806, 11, 1), 
                     :end_date => Date.new(1826, 12, 31), 
                     :date_of_birth => Date.new(1781, 1, 14), 
                     :date_of_death => Date.new(1852, 10, 24),
                     :year_of_birth => nil,
                     :year_of_death => nil}
      gilbert_jones = {:constituency => "test constituency",
                       :name => "Gilbert Jones",
                       :firstname => 'Gilbert', 
                       :firstnames => 'Gilbert',
                       :lastname => 'Jones', 
                       :honorific => nil,
                       :set => Date.new(1806, 11, 1),
                       :date_of_birth => nil,
                       :end_date => Date.new(1812, 10, 12),
                       :date_of_death => Date.new(1830, 9, 7),
                       :start_date => Date.new(1806, 11, 1),
                       :year_of_birth=>1758,
                       :year_of_death => nil}
      henry_dawkins = {:constituency => "test constituency",
                       :name => "Henry Dawkins",
                       :firstnames => "Henry",
                       :firstname => 'Henry', 
                       :lastname => 'Dawkins',
                       :honorific => nil,
                       :date_of_birth => nil,
                       :end_date => nil,
                       :date_of_death => Date.new(1852, 10, 25), 
                       :start_date => Date.new(1812, 10, 12),
                       :year_of_birth=>1765,
                       :year_of_death => nil}               
      memberships.should == [henry_fynes, gilbert_jones, henry_dawkins]
    end
  
  end

  describe 'when parsing an example file' do 
    
    before do 
      @parser = Hansard::CommonsMembershipParser.new data_file_path('commons_memberships.html')
      Election.stub!(:find_all_by_year).and_return([])
      Election.stub!(:find_all_by_year).with(1950).and_return([mock_model(Election, :date => Date.new(1950, 12, 31))])
      Election.stub!(:find_all_by_year).with(1918).and_return([mock_model(Election, :date => Date.new(1918, 12, 31))])
      Election.stub!(:find_all_by_year).with(1832).and_return([mock_model(Election, :date => Date.new(1832, 12, 31))])
      @memberships = @parser.parse
    end
  
    it 'should extract all the memberships correctly' do 
      
      def date_or_nil value
        value.blank? ? nil : Date.parse(value)
      end
      
      def integer_or_nil value
        value.blank? ? nil : value.to_i
      end
      
      expected_memberships = [                     
        ['William Lehman Ashmead Bartlett Burdett-Coutts', '1918-12-14', '1921-08-25', '', '1921-07-28', 'ABBEY', '1851', ''],
        ['John Sanctuary Nicholson', '1921-08-25', '1924-03-19', '1863-05-19', '1924-02-21', 'ABBEY', '', ''],
        ['Otho William Nicholson', '1924-03-19', '1932-07-12', '1891-11-30', '1978-06-29', 'ABBEY', '', ''],
        ['Sir Sidney Herbert', '1932-07-12', '1939-05-17', '1890-07-29', '1939-03-22', 'ABBEY' , '', ''],
        ['Sir William Harold Webbe', '1939-05-17', '1950-12-31', '1885-09-30', '1965-04-22', 'ABBEY', '', '' ],
        ['John Edwards', '1918-12-14', '1922-11-15', '', '1960-05-23', 'ABERAVON (GLAMORGANSHIRE)', '1882', ''],
        ['James Ramsay Macdonald', '1922-11-15', '1929-05-30', '1866-10-12', '1937-11-09', 'ABERAVON (GLAMORGANSHIRE)', '', ''],
        ['William George Cove', '1929-05-30', '1959-10-08', '1888-05-21', '1963-03-15', 'ABERAVON (GLAMORGANSHIRE)', '', ''],
        ['John Morris,later Baron Morris of Aberavon', '1959-10-08', '2001-06-07', '1931-11-05', '', 'ABERAVON (GLAMORGANSHIRE)', '', ''],
        ["Hywel Francis",'2001-06-07', '', '1946-06-06', '',"ABERAVON (GLAMORGANSHIRE)", '', ''],
        ['William Frederic Lawrence', '1885-11-25', '1906-01-16', '1844-12-29', '1935-01-15', 'ABERCROMBY (LIVERPOOL)', '', ''],
        ['John Edward Bernard Seely,later Baron Mottistone', '1906-01-16', '1910-01-18', '1868-05-31', '1947-11-07', 'ABERCROMBY (LIVERPOOL)', '', ''],
        ['Richard Godolphin Walmesley Chaloner, later Baron Gisborough', '1910-01-18', '1917-06-28', '1856-10-12', '1938-01-23', 'ABERCROMBY (LIVERPOOL)', '', ''],
        ['Edward Montagu Cavendish Stanley,Baron Stanley', '1917-06-28', '1918-12-31', '1894-07-09', '1938-10-16', 'ABERCROMBY (LIVERPOOL)', '', ''],
        ['Thomas Drake Tyrwhitt-Drake', '1795-06-04', '1810-12-31', '1749-01-14', '1810-10-18', 'AMERSHAM (BUCKINGHAMSHIRE)', '', ''],
        ['Charles Drake Garrard', '1796-05-26', '1805-01-31', '1755-12-23', '1817-07-17', 'AMERSHAM (BUCKINGHAMSHIRE)', '', ''],
        ['Thomas Tyrwhitt-Drake', '1805-01-31', '1832-12-31', '1783-03-16', '1852-03-23', 'AMERSHAM (BUCKINGHAMSHIRE)', '', ''],
        ['William Tyrwhitt-Drake', '1810-11-21', '1832-12-31', '1785-10-21', '1848-12-21', 'AMERSHAM (BUCKINGHAMSHIRE)', '', ''],
      ]
      
      expected_memberships = expected_memberships.map do |line|
        a = {:name => line[0], 
         :start_date => date_or_nil(line[1]),
         :end_date => date_or_nil(line[2]),
         :date_of_birth => date_or_nil(line[3]), 
         :date_of_death => date_or_nil(line[4]), 
         :constituency => line[5], 
         :year_of_birth => integer_or_nil(line[6]), 
         :year_of_death => integer_or_nil(line[7])}
        @parser.add_name_parts(a)
        a
      end
      
      @memberships.should == expected_memberships 
    end
    
    it 'should extract all the constituencies correctly' do 
      constituencies = @parser.constituencies
      constituencies.should == {["ABBEY", Date.new(1918, 12, 14), Date.new(1950, 12, 31)] => [],
                                ["ABERAVON (GLAMORGANSHIRE)", Date.new(1918, 12, 14), nil] => [],
                                ["ABERCROMBY (LIVERPOOL)", Date.new(1885, 11, 25), Date.new(1918, 12, 31)] => [],
                                ["AMERSHAM (BUCKINGHAMSHIRE)", Date.new(1660, 4, 1), Date.new(1832, 12, 31)] => []}                       
    end
    
    it 'should extract 18 memberships' do
      @memberships.size.should == 18
    end
    
    it 'should set the constituency classes to ".xl4121364", ".xl4721364" and ".xl5521364"' do
      @parser.constituency_classes.should == ['.xl4121364', '.xl4721364', '.xl5521364'] 
    end
    
    it 'should set the constituency end classes to ".xl4621364", ".xl4821364", ".xl4921364", ".xl5121364" and ".xl5821364"' do 
      @parser.constituency_end_classes.should == [".xl4621364", ".xl4821364", ".xl4921364", ".xl5121364", ".xl5821364"]
    end
  
  end
  
  describe 'when adding an end date for a constituency from constituency end text' do 
  
    it 'should add the date of the 1918 election for text "CONSTITUENCY ABOLISHED 1918"' do 
      election = mock_model(Election, :date => Date.new(1918, 12, 14))
      Election.stub!(:find_all_by_year).and_return([election])
      @parser.constituency_end_date("CONSTITUENCY ABOLISHED 1918").should == Date.new(1918, 12, 14)
    end
    
    it 'should add the date of the 1832 election for text "CONSTITUENCY DISENFRANCHISED 1832"' do 
      election = mock_model(Election, :date => Date.new(1832, 12, 10))
      Election.stub!(:find_all_by_year).and_return([election])
      @parser.constituency_end_date("CONSTITUENCY DISENFRANCHISED 1832").should == Date.new(1832, 12, 10)     
    end
    
  end
  
  describe 'when setting the end date for a constituency' do 
    
    it 'should not throw an error if there is no last membership' do 
      @parser.memberships = []
      lambda{ @parser.set_constituency_end_date(Date.new(2003, 1, 12)) }.should_not raise_error
    end
    
    it 'should not set the end date on the last membership if the constituency is different' do
      different_constituency_membership = {:constituency => 'a', :end_date => nil}
      @parser.memberships = [different_constituency_membership]
      @parser.current_constituency = 'b'
      @parser.set_constituency_end_date(Date.new(2003, 1, 12))
      different_constituency_membership[:end_date].should be_nil
    end
    
    it 'should set the end date of the last membership to the end date of the constituency' do 
      membership = {:constituency => 'a', :end_date => nil}
      @parser.memberships = [membership]
      @parser.current_constituency = 'a'
      @parser.set_constituency_end_date(Date.new(2003, 1, 12))
      membership[:end_date].should == Date.new(2003, 1, 12)
    end
  
  end
  
  describe 'when asked for the constituency text from a row' do 
  
    before do 
      @parser.constituency_classes = ['.xl4721364', '.xl4121364', '.xl5521364' ]
    end
  
    it 'should return the text from a constituency cell ' do
      text = "<tr height=18 style='height:13.5pt'>
       <td height=18 class=xl3721364 style='height:13.5pt'></td>
       <td class=xl3721364></td>
       <td class=xl4721364><span style=\"mso-spacerun: yes\"></span>ALL SAINTS
       (BIRMINGHAM)</td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl4421364></td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.constituency_text(element).should == 'ALL SAINTS (BIRMINGHAM)'
    end
    
    it 'should return nil from a commons membership row' do 
      text = "<tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3721364 style='height:12.75pt'>15 Oct 1964</td>
       <td class=xl3721364></td>
       <td class=xl4221364>Alastair Brian Walden</td>
       <td class=xl3921364><span style=\"mso-spacerun: yes\"> </span>8 Jul 1932</td>
       <td class=xl3921364></td>
       <td class=xl4421364></td>
      </tr"
      element = Hpricot(text).at('tr')
      @parser.constituency_text(element).should be_nil
    end
  
  end
  
  
  describe 'when asked for the constituency end text from a row' do 
  
    before do 
      @parser.constituency_end_classes = ['.xl4621364', '.xl5821364', '.xl3721364' ]
    end
    
    it 'should return the text from a cell with class "xl4621364" ' do
      text = "<tr height=18 style='height:13.5pt'>
       <td height=18 class=xl3721364 style='height:13.5pt'><span
       style=\"mso-spacerun: yes\"> </span></td>
       <td class=xl3721364></td>
       <td class=xl4621364 x:str=\" CONSTITUENCY ABOLISHED 1950 \"><span
       style=\"mso-spacerun: yes\"></span>CONSTITUENCY ABOLISHED 1950</td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl4421364></td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.constituency_end_text(element).should == 'CONSTITUENCY ABOLISHED 1950'
    end
    
    it 'should return the text from a cell with class "xl5821364"' do 
      text = "<tr height=18 style='height:13.5pt'>
       <td height=18 class=xl3921364 style='height:13.5pt'></td>
       <td class=xl3921364></td>
       <td class=xl5821364 x:str=\" CONSTITUENCY DISENFRANCHISED 1832 \"><span
       style=\"mso-spacerun: yes\"></span>CONSTITUENCY DISENFRANCHISED 1832</td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl5621364></td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.constituency_end_text(element).should == 'CONSTITUENCY DISENFRANCHISED 1832'
    end
    
    it 'should return the text from a cell with class "xl3721364"' do 
      text = "<tr height=18 style='height:13.5pt'>
       <td height=18 class=xl3721364 style='height:13.5pt'></td>
       <td class=xl3721364></td>
       <td class=xl4621364><span style=\"mso-spacerun: yes\"></span>CONSTITUENCY ABOLISHED FEB 1974</td>
       <td class=xl3921364></td>
       <td class=xl3921364></td>
       <td class=xl4421364></td>
      </tr>"
      element = Hpricot(text).at('tr')
      @parser.constituency_end_text(element).should == 'CONSTITUENCY ABOLISHED FEB 1974'
    end
  
    it 'should return nil from a commons membership row' do 
      text = "<tr height=17 style='height:12.75pt'>
       <td height=17 class=xl3721363 style='height:12.75pt'>15 Oct 1964</td>
       <td class=xl3721363></td>
       <td class=xl4221364>Alastair Brian Walden</td>
       <td class=xl3921364><span style=\"mso-spacerun: yes\"> </span>8 Jul 1932</td>
       <td class=xl3921364></td>
       <td class=xl4421364></td>
      </tr"
      element = Hpricot(text).at('tr')
      @parser.constituency_end_text(element).should be_nil
    end
  
  end
  
end
