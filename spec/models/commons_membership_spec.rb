require File.dirname(__FILE__) + '/../spec_helper'

describe CommonsMembership do 
  
  describe 'when asked for the person\'s name' do 
  
    it 'should return the name of the associated person' do 
      person = mock_model(Person, :name => 'test name')
      commons_membership = CommonsMembership.new(:person => person)
      commons_membership.person_name.should == 'test name'
    end
  
  end
  
  describe 'when asked for the constituency name' do 
  
    it 'should return the complete name of the associated constituency' do 
      constituency = mock_model(Constituency, :complete_name => 'test constituency')
      commons_membership = CommonsMembership.new(:constituency => constituency)
      commons_membership.constituency_name.should == 'test constituency'
    end
    
  end
  
  describe 'when asked for members on a date by constituency' do 
  
    it 'should return an array of a count and an array of constituency name and membership pairs ' do 
      constituency = mock_model(Constituency, :name => 'Hove')
      membership = mock_model(CommonsMembership, :constituency => constituency, 
                                                 :constituency_id => constituency.id)
      CommonsMembership.stub!(:find).and_return([membership])
      expected = [1,[[constituency.id, [membership]]]]
      CommonsMembership.members_on_date_by_constituency(Date.new(2004, 1, 1)).should == expected
    end
    
    it 'should return an array containing zero and an empty list if there are no members' do 
      CommonsMembership.stub!(:find).and_return([])
      CommonsMembership.members_on_date_by_constituency(Date.new(2004, 1, 1)).should == [0, []]
    end
    
  end
  
  describe " when asked for query date params" do 

    it 'should return a query string specifying a start date before the date (or no start date) and an end date after the date (or no end date)' do 
      CommonsMembership.query_date_params.should == "(commons_memberships.start_date <= ? or commons_memberships.start_date is null) and 
      (commons_memberships.end_date >= ? or commons_memberships.end_date is null)"
    end
  
  end

  describe  ' when returning the count on a date' do 
  
    it 'should ask for a count of any memberships whose date range encompasses the date' do 
      date = Date.new(1846, 3, 18)
      CommonsMembership.stub!(:query_date_params).and_return('query_date_params')
      conditions = ['query_date_params', date, date]
      CommonsMembership.should_receive(:count).with(:conditions => conditions)
      CommonsMembership.count_on_date(date)
    end

  end

  describe  " when adding a membership to membership lookups for a date" do 
  
    def should_add(hash, key, value)
      list = []
      @lookups[hash].should_receive(:[]).with(key).and_return(list)
      list.should_receive(:<<).with(value)
    end
  
    def should_not_add(hash, key)
      @lookups[hash].should_not_receive(:[]).with(key)
    end
  
    before do 
      @person = mock_model(Person, :firstname => 'Bob', 
                                   :lastname  => 'Member', 
                                   :alternative_names => [], 
                                   :office_holders => [], 
                                   :alternative_titles => [])
      @membership = mock_model(CommonsMembership, :person => @person, 
                                                  :id => 12, 
                                                  :constituency_id => 23)
      list = []
      mock_hash = mock('hash', :[] => list)
      @lookups = { :fullnames => mock_hash,
                   :initial_and_lastnames => mock_hash,
                   :lastnames => mock_hash, 
                   :constituency_ids => mock_hash, 
                   :office_names => mock_hash }
      @date = Date.new(1843, 12, 21)
    end
  
    it 'should add a "bob member" key to the fullnames hash pointing to the membership id for a membership for person "Bob Member"' do 
      should_add(:fullnames, 'bob member', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)
    end
  
    it 'should add a "b member" key to the initial_and_fullnames hash pointing to the membership id for a membership for person "Bob Member"' do 
      should_add(:initial_and_lastnames, 'b member', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)
    end
  
    it 'should not add a key to the initial_and_fullnames hash pointing to the membership id for a membership for person "Lord Member"' do 
      @person.stub!(:firstname).and_return(nil)
      should_not_add(:initial_and_lastnames, ' member')
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)
    end
  
    it 'should not add a key to the fullnames hash pointing to the membership id for a membership for person "Lord Member"' do 
      @person.stub!(:firstname).and_return('')
      should_not_add(:fullnames, ' member')
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)
    end
  
    it 'should add a "member" key to the lastnames hash pointing to the membership id for a membership for person "Bob Member"' do 
      should_add(:lastnames, 'member', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)  
    end
  
    it 'should add a key 23 to the constituency ids hash to the membership id for a membership for constituency 23' do 
      should_add(:constituency_ids, 23, 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)    
    end
  
    it 'should add a "robert amember" key to the fullnames hash, and key "amember" to the lastnames hash pointing to the membership id for a member with alternative name "Robert Amember" on the date' do 
      alternative_name = mock_model(AlternativeName, :firstname => 'Robert', 
                                                     :lastname => 'Amember',
                                                     :first_possible_date => @date - 1.day, 
                                                     :last_possible_date => @date + 1.day)
      @person.stub!(:alternative_names).and_return([alternative_name])
      should_add(:fullnames, 'robert amember', 12)
      should_add(:lastnames, 'amember', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)    
    end
  
    it 'should add a "double barrelled" key to the fullnames hash pointing to the membership id for a member with lastname "Double-Barrelled"' do 
      @person.stub!(:lastname).and_return("Double-Barrelled")
      should_add(:lastnames, 'double barrelled', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)
    end
  
    it 'should not add a "robert amember" key to the fullnames hash pointing to the membership id for a member with alternative name "Robert Amember" for a period outside the date' do 
      alternative_name = mock_model(AlternativeName, :firstname => 'Robert', 
                                                     :lastname => 'Amember',
                                                     :first_possible_date => @date + 1.day, 
                                                     :last_possible_date => @date + 2.days)
      @person.stub!(:alternative_names).and_return([alternative_name])
      should_not_add(:fullnames, 'robert amember')
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)    
    end
  
    it 'should add a key "prime minister" to the office names hash pointing to the membership id for a member holding the office "Prime Minister" on the date' do 
      office_holder = mock_model(OfficeHolder, :office => mock_model(Office, :name => 'Prime Minister'), 
                                               :start_date => @date - 1.day, 
                                               :end_date => @date + 1.day)
      @person.stub!(:office_holders).and_return([office_holder])
      should_add(:office_names, 'prime minister', 12)
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)    
    end
  
    it 'should not add a key "prime minister" to the office names hash pointing to the membership id for a member holding the office "Prime Minister" for a period outside the date' do 
      office_holder = mock_model(OfficeHolder, :office => mock_model(Office, :name => 'Prime Minister'), 
                                               :start_date => @date + 1.day, 
                                               :end_date => @date + 2.days)
      @person.stub!(:office_holders).and_return([office_holder])
      should_not_add(:office_names, 'prime minister')
      CommonsMembership.add_membership_to_lookups(@membership, @lookups, @date)    
    end
  end

  describe " when asked for membership lookups for a date" do 
  
    before do 
      CommonsMembership.stub!(:add_membership_to_lookups)
      @date = Date.new(1834, 11, 14)
    end
  
    it 'should create a hash of hashes with keys for fullnames, lastnames, office_names, initial_and_lastnames and constituency_ids' do 
      lookups = CommonsMembership.membership_lookups(@date)
      [:fullnames, :lastnames, :initial_and_lastnames, :office_names, :constituency_ids].each do |key|
        lookups.should have_key(key) 
      end
    end
  
    it 'should make the value of each key a hash of lists' do 
      CommonsMembership.stub!(:hash_of_lists).and_return('hash of lists')
      lookups = CommonsMembership.membership_lookups(@date)
      [:fullnames, :lastnames, :initial_and_lastnames, :office_names, :constituency_ids].each do |key|
        lookups[key].should == 'hash of lists'
      end
    end
  
  end

  describe ' when asked for a hash of lists' do 
  
    it 'should return a hash ' do 
      CommonsMembership.hash_of_lists.should be_a_kind_of(Hash)
    end
  
    it 'should return a hash where asking for an unknown key returns a list' do 
      hash = CommonsMembership.hash_of_lists
      hash['new key'].should == []
    end
  
  end

  describe 'when asked to find matches for a list of member attributes on a date' do 
  
    before(:each) do 
      @date = Date.new(1886, 3, 21)
      @attributes = {:att => :val}
      @attribute_list = [@attributes]
      @member = mock_model(CommonsMembership, :matches_attributes? => false)
      @member_list = [@member]
      CommonsMembership.stub!(:find_matches).and_return([])
      CommonsMembership.stub!(:members_on_date).and_return(@member_list)
    end
  
    it 'should ask for a list of memberships on the date' do 
      CommonsMembership.should_receive(:members_on_date).with(@date).and_return(@member_list)
      CommonsMembership.find_matches_on_date(@date, @attribute_list)
    end
  
    it 'should ask for matches between the attributes and the list of memberships based on lastname and constituency' do 
      CommonsMembership.should_receive(:find_matches).with(@attribute_list, 
                                                           @member_list, 
                                                           [:constituency, :lastname]).and_return([])
      CommonsMembership.find_matches_on_date(@date, @attribute_list)
    end
  
    it 'should delete any completely matched attribute hashes from the unmatched lists' do 
      @attribute_list.should_receive(:delete).with(@attributes)
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:constituency, :lastname]).and_return([[@member, @attributes]])
      CommonsMembership.find_matches_on_date(@date, @attribute_list)
    end
  
    it 'should ask for matches between the attributes and the memberships based on lastname' do 
      CommonsMembership.should_receive(:find_matches).with(@attribute_list, 
                                                           @member_list, 
                                                           [:lastname]).and_return([])
      CommonsMembership.find_matches_on_date(@date, @attribute_list)
    end
  
    it 'should delete any partially matched attribute hashes from the unmatched lists' do 
      @attribute_list.should_receive(:delete).with(@attributes)
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:lastname]).and_return([[@member, @attributes]])
      CommonsMembership.find_matches_on_date(@date, @attribute_list)
    end
  
    it 'should return a hash containing the complete and partial matches, and the unmatched members and attributes' do 
      complete_matches = ["complete"]
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:constituency, :lastname]).and_return(complete_matches)
      constituency_matches = ["constituency"]
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:constituency]).and_return(constituency_matches)
      lastname_matches = ["lastname"]
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:lastname]).and_return(lastname_matches)
                                                
      name_matches = ["name"]
      CommonsMembership.stub!(:find_matches).with(@attribute_list, 
                                                  @member_list, 
                                                  [:name]).and_return(name_matches)     
                                                     
      expected = { :complete_matches => complete_matches, 
                   :constituency_matches => constituency_matches,
                   :lastname_matches => lastname_matches, 
                   :name_matches => name_matches, 
                   :unmatched_members => @member_list,
                   :unmatched_attributes => @attribute_list}
      CommonsMembership.find_matches_on_date(@date, @attribute_list).should == expected
    end
  
  end

  describe 'when asked to find duplicates for a year' do 

    it 'should look for memberships on the Dec 31 of that year' do 
      CommonsMembership.should_receive(:members_on_date).with(Date.new(1974, 12,31)).and_return([])
      CommonsMembership.find_duplicates(1974)
    end
  
    it 'should return any constituency that has two representatives on Dec 31 of that year' do 
      leith = mock_model(Constituency, :name => 'Leith')
      other = mock_model(Constituency, :name => 'Not Leith')
      leith_one = mock_model(CommonsMembership, :constituency => leith)
      leith_two = mock_model(CommonsMembership, :constituency => leith)
      not_leith = mock_model(CommonsMembership, :constituency => other)
      CommonsMembership.stub!(:members_on_date).and_return([leith_one, leith_two, not_leith])
      CommonsMembership.find_duplicates(1974).should == [leith]
    end

  end

  describe 'when asked to find matches between a list of attribute hashes and a list of members based on some criteria' do 

    before do 
      @attribute_list = ['attribute hash']
      @member_list = ['membership']
      @criteria = ['criteria']
    end
  
    it 'should ask for matches with the membership list based on the criteria for each attribute hash' do 
      CommonsMembership.should_receive(:match_memberships).with('attribute hash', @member_list, @criteria)
      CommonsMembership.find_matches(@attribute_list, @member_list, @criteria)
    end
  
    it 'should delete any matches found' do 
      CommonsMembership.stub!(:match_memberships).and_return('membership')
      @member_list.should_receive(:delete).with('membership')
      CommonsMembership.find_matches(@attribute_list, @member_list, @criteria)
    end
  
    it 'should return a list of matches as membership, attribute lists' do 
      CommonsMembership.stub!(:match_memberships).and_return('membership')
      CommonsMembership.find_matches(@attribute_list, @member_list, @criteria).should == [['membership', 'attribute hash']]
    end
  
  end
  
  describe 'when asked to match attributes by overlap and name' do 
  
    before do 
      @person = Person.new(:lastname => 'Test')
      @membership = CommonsMembership.new(:start_date => Date.new(2001, 1, 2), 
                                          :end_date => Date.new(2003, 12, 1), 
                                          :person => @person)
    end
    
    it 'should return false if no start date is passed' do
      attributes = {:end_date => Date.new(2003, 1, 20)}
      @membership.match_by_overlap_and_name(attributes).should be_false
    end
    
    it 'should return false if the membership has no start date' do
      attributes = {:start_date => Date.new(2001, 1, 1), 
                    :end_date => Date.new(2003, 1, 20), 
                    :lastname => 'Test'}
      @membership.stub!(:start_date).and_return(nil)
      @membership.match_by_overlap_and_name(attributes).should be_false
    end
    
    describe 'when the full names do not match ' do
      
      before do 
        @attributes = {:start_date => Date.new(2001, 1, 1), 
                      :end_date => Date.new(2003, 1, 20), 
                      :lastname => 'Test'}
      end
      
      it 'should return true if the dates overlap and lastname matches' do 
        Person.stub!(:find_by_name_and_other_criteria).and_return([])
        @membership.stub!(:lastname_match).and_return(true)
        @membership.stub!(:date_overlap?).and_return(true)
        @membership.match_by_overlap_and_name(@attributes).should be_true
      end
      
      it 'should return false if the dates don\'t overlap and lastname matches' do 
        Person.stub!(:find_by_name_and_other_criteria).and_return([])
        @membership.stub!(:lastname_match?).and_return(true)
        @membership.stub!(:date_overlap?).and_return(false)
        @membership.match_by_overlap_and_name(@attributes).should be_false
      end
      
      it 'should return false if the dates overlap but the lastname does not match' do 
        Person.stub!(:find_by_name_and_other_criteria).and_return([])
        @membership.stub!(:lastname_match?).and_return(false)
        @membership.stub!(:date_overlap?).and_return(true)
        @membership.match_by_overlap_and_name(@attributes).should be_false
      end
      
    end
    
    describe 'when the full names match' do 
      
      before do 
        Person.stub!(:find_by_name_and_other_criteria).and_return([@person])
      end
    
      it 'should return true if the start date and end date are supplied and overlap with the membership start and end dates' do 
        attributes = {:start_date => Date.new(2001, 1, 1), 
                      :end_date => Date.new(2003, 1, 20), 
                      :lastname => 'Test'}
        @membership.match_by_overlap_and_name(attributes).should be_true
      end
      
      it 'should return true if the end date is not supplied and the membership has an end date and the membership end date is after the start date passed' do 
        attributes = {:start_date => Date.new(2001, 1, 1), 
                      :lastname => 'Test'}
        @membership.match_by_overlap_and_name(attributes).should be_true                 
      end
    
      it 'should return true if the end date is supplied and the membership has no end date and the end date supplied is after the membership start date' do 
        attributes = {:start_date => Date.new(2001, 1, 1), 
                      :end_date => Date.new(2003, 1, 20), 
                      :lastname => 'Test'}
        @membership.stub!(:end_date).and_return(nil)
        @membership.match_by_overlap_and_name(attributes).should be_true
      
      end
      
      it 'should return true if no end date is supplied and the membership has no end date' do 
        attributes = {:start_date => Date.new(2001, 1, 1), 
                      :lastname => 'Test'}
        @membership.stub!(:end_date).and_return(nil)
        @membership.match_by_overlap_and_name(attributes).should be_true
      end
    
    end
    
    it 'should return true if the dates overlap, the lastnames don\'t match, but an alternative lastname overlapping the period matches' do 
      attributes = {:start_date => Date.new(2001, 1, 1), 
                    :end_date => Date.new(2003, 1, 20), 
                    :lastname => 'Test'}
      @member.stub!(:lastname).and_return('No')
      @alternative_name = mock_model(AlternativeName, :lastname => 'Test', 
                                                      :first_possible_date => Date.new(2001, 1, 1),
                                                      :last_possible_date => Date.new(2003, 1, 20))
      @person.stub!(:alternative_names).and_return([@alternative_name])
      @membership.match_by_overlap_and_name(attributes).should be_true        
    end
    
    it 'should return false if the start date and end date are supplied and overlap with the membership dates but the lastnames do not match' do 
      attributes = {:start_date => Date.new(2001, 1, 1), 
                    :end_date => Date.new(2003, 1, 20), 
                    :lastname => 'No'}
      @membership.match_by_overlap_and_name(attributes).should be_false
    end
    
  end
  
  describe 'when rendering json' do 
  
    before do 
      @model = CommonsMembership.new(:person => Person.new, :constituency => Constituency.new)
    end
    
    it_should_behave_like 'a json-rendering model'
  
  end

  describe 'when asked to match attributes by year' do 

    before do 
      @membership = CommonsMembership.new(:start_date => Date.new(2001, 1, 2), 
                                          :end_date => Date.new(2003, 12, 1))
    end
  
    it 'should return true if the year of the start and end date attributes are the same as the membership start and end date' do 
      attributes = {:start_date => Date.new(2001, 1, 30), :end_date => Date.new(2003, 12, 24)}
      @membership.match_by_year(attributes).should be_true
    end
  
    it 'should return false if no start date is passed' do 
      attributes = {:end_date => Date.new(2003, 12, 24)}
      @membership.match_by_year(attributes).should be_false
    end
  
    it 'should return false if the start date has a different year' do 
      attributes = {:start_date => Date.new(2002, 1, 30), :end_date => Date.new(2003, 12, 24)}
      @membership.match_by_year(attributes).should be_false
    end
  
    it 'should return false if an end date is given and it has a different year' do 
      attributes = {:start_date => Date.new(2002, 1, 30), :end_date => Date.new(2004, 12, 24)}
      @membership.match_by_year(attributes).should be_false
    end
  
    it 'should return false if the end date is given and the membership has no end date' do 
      attributes = {:start_date => Date.new(2001, 1, 2), :end_date => Date.new(2003, 12, 1)}
      @membership.end_date = nil
      @membership.match_by_year(attributes).should be_false
    end
  
    it 'should return false if the membership has no start date' do 
      attributes = {:start_date => Date.new(2001, 1, 2), :end_date => Date.new(2003, 12, 1)}
      @membership.start_date = nil
      @membership.match_by_year(attributes).should be_false
    end
  end

  describe 'when asked if a hash of attributes matches a list of memberships' do 

    before do 
      @first_membership = mock_model(CommonsMembership, :matches_attributes? => false)
      @second_membership = mock_model(CommonsMembership, :matches_attributes? => false)
      @memberships = [@first_membership, @second_membership]
      @attributes = {}
      @criteria = [:constituency]
    end
  
    it 'should ask each of the memberships if it matches the criteria' do 
      @memberships.each do |membership| 
        membership.should_receive(:matches_attributes?).with(@attributes, @criteria) 
      end
      CommonsMembership.match_memberships(@attributes, @memberships, @criteria)
    end
  
    it 'should return the matching membership if there is only one' do 
      @second_membership.stub!(:matches_attributes?).and_return true
      CommonsMembership.match_memberships(@attributes, @memberships, @criteria).should == @second_membership    
    end
  
    it 'should return nil if there is more than one matching membership' do 
      @first_membership.stub!(:matches_attributes?).and_return true   
      @second_membership.stub!(:matches_attributes?).and_return true
      CommonsMembership.match_memberships(@attributes, @memberships, @criteria).should be_nil
    end
  
    it 'should return nil if there aren\'t any matching memberships' do 
      CommonsMembership.match_memberships(@attributes, @memberships, @criteria).should be_nil
    end
  
  end

  describe "when asked if a membership matches a hash of attributes" do 

    before do 
      @person = mock_model(Person)
      @constituency = mock_model(Constituency)
      @commons_membership = CommonsMembership.new(:person => @person, :constituency => @constituency, :start_date => Date.new(2003, 1, 1))
      @attributes = {:lastname => 'Jones', :constituency => "Southwark", :firstnames => "John Geoffrey"}
    end
  
    it 'should return true if constituency is specified as the only criteria and the constituency matches' do 
      @constituency.stub!(:match?).with(@attributes[:constituency]).and_return true
      @commons_membership.matches_attributes?(@attributes, [:constituency]).should be_true
    end
   
    it 'should return false if constituency is specified as the only criteria and the constituency does not match' do 
      @constituency.stub!(:match?).with(@attributes[:constituency]).and_return false
      @commons_membership.matches_attributes?(@attributes, [:constituency]).should be_false
    end
  
    it 'should return true if lastname is specified as the only criteria and the lastname of the person matches' do 
      @person.stub!(:lastname_match?).with(@attributes[:lastname], @commons_membership.start_date).and_return true
      @commons_membership.matches_attributes?(@attributes, [:lastname]).should be_true
    end
  
    it 'should return false if lastname is specified as the only criteria and the lastname of the person does not match' do 
      @person.stub!(:lastname_match?).with(@attributes[:lastname], @commons_membership.start_date).and_return false
      @commons_membership.matches_attributes?(@attributes, [:lastname]).should be_false
    end
  
    it 'should return true if lastname and constituency are both specified as criteria and both match' do 
      @person.stub!(:lastname_match?).with(@attributes[:lastname], @commons_membership.start_date).and_return true
      @constituency.stub!(:match?).with(@attributes[:constituency]).and_return true
      @commons_membership.matches_attributes?(@attributes, [:lastname, :constituency]).should be_true
    end
  
    it 'should return false if lastname and constituency are both specified as criteria and constituency does not match' do 
      @person.stub!(:lastname_match?).with(@attributes[:lastname], @commons_membership.start_date).and_return true
      @constituency.stub!(:match?).with(@attributes[:constituency]).and_return false
      @commons_membership.matches_attributes?(@attributes, [:lastname, :constituency]).should be_false
    end
  
    it 'should return false if lastname and constituency are both specified as criteria and the lastname of the person does not match'  do 
      @person.stub!(:lastname_match?).with(@attributes[:lastname], @commons_membership.start_date).and_return false
      @constituency.stub!(:match?).with(@attributes[:constituency]).and_return true
      @commons_membership.matches_attributes?(@attributes, [:lastname, :constituency]).should be_false
    end
  
    it 'should return false if name is specified as the only criteria and the name of the person does not match' do 
      @person.stub!(:name_match?).with(@attributes[:firstnames], @attributes[:lastname], @commons_membership.start_date).and_return false
      @commons_membership.matches_attributes?(@attributes, [:name]).should be_false
    end
  
    it 'should return true if name is specified as the only criteria and the name of the person matches' do 
      @person.stub!(:name_match?).with(@attributes[:firstnames], @attributes[:lastname], @commons_membership.start_date).and_return true
      @commons_membership.matches_attributes?(@attributes, [:name]).should be_true
    end
  end

  describe ' when asked for memberships by name' do 
  
    it 'should remove any hyphens in lastnames' do 
      name = "Mr. LLOYD-GEORGE"
      lastnames = mock('hash')
      lastnames.should_receive(:[]).with('lloyd george').and_return([])
      CommonsMembership.get_memberships_by_name(name, {:fullnames => {}, 
                                                       :initials_and_lastnames => {}, 
                                                       :lastnames => lastnames})
    end
    
    it 'should not return any duplicate ids in the list' do 
      CommonsMembership.get_memberships_by_name('mr. a test', {:fullnames => {'a test' => [55]}, 
                                                       :initials_and_lastnames => {}, 
                                                       :lastnames => {'a test' => [55]}}).should == [55]
    end
  
    it 'should try looking for the firstname and lastname as a double-barrelled lastname' do
      name = 'Vice-Admiral Hughes Hallett'
      fullnames = mock('hash')
      lastnames = mock('hash')
      initial_and_lastnames = mock('hash')
      fullnames.stub!(:[]).with('hughes hallett').and_return([])
      initial_and_lastnames.stub!(:[]).with('h hallett').and_return([])
      lastnames.stub!(:[]).with('hallett').and_return([])
      lastnames.should_receive(:[]).with('hughes hallett').and_return([])
      CommonsMembership.get_memberships_by_name(name, {:fullnames => fullnames, 
                                                       :initial_and_lastnames => initial_and_lastnames, 
                                                       :lastnames => lastnames})
    end
   
  
    it 'should not raise an error if no lastname can be extracted from the name' do 
      name = 'test name'
      Person.stub!(:name_hash).and_return(:firstname => 'test')
      lambda{ CommonsMembership.get_memberships_by_name(name, {:fullnames => {}, 
                                                               :initials_and_lastnames => {}, 
                                                               :lastnames => {}}) }.should_not raise_error 
  
    
    end
  
  end
  
end