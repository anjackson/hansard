require File.dirname(__FILE__) + '/../spec_helper'

describe LordsMembership do 

  describe 'when asked for start year' do
  
    it 'should return nil if there is no start date' do 
      membership = LordsMembership.new
      membership.start_year.should be_nil
    end
    
    it 'should return the year of the start date if there is one' do 
      membership = LordsMembership.new(:start_date => Date.new(1945, 4, 10))
      membership.start_year.should == 1945
    end
    
  end
  
  describe 'when asked for end year' do
  
    it 'should return nil if there is no end date' do 
      membership = LordsMembership.new
      membership.end_year.should be_nil
    end
    
    it 'should return the year of the end date if there is one' do 
      membership = LordsMembership.new(:end_date => Date.new(1945, 4, 10))
      membership.end_year.should == 1945
    end
    
  end
  
  describe 'when asked for members on date' do 
  
    it 'should ask for lords memberships whose dates include the date given' do 
      date = Date.new(1967, 5, 12)
      date_param_string = '(lords_memberships.start_date <= ? or lords_memberships.start_date is null) and 
      (lords_memberships.end_date >= ? or lords_memberships.end_date is null)'
      LordsMembership.should_receive(:find).with(:all, :conditions => [date_param_string, date, date], 
                                                       :include => {:person => [:alternative_names, :alternative_titles]})
      LordsMembership.members_on_date(date)
    end
    
  end
  
  describe 'when asked to find duplicates for a year' do 

    it 'should look for memberships on the Dec 31 of that year' do 
      LordsMembership.should_receive(:members_on_date).with(Date.new(1974, 12,31)).and_return([])
      LordsMembership.find_duplicates(1974)
    end
  
    it 'should return any pair of people holding the same title on Dec 31 of that year' do
      person_one = mock_model(Person, :slug => 'person-one')
      person_two = mock_model(Person, :slug => 'person-two') 
      person_three = mock_model(Person, :slug => 'person-three') 
      lord_bognor_one = mock_model(LordsMembership, :person => person_one, 
                                                    :title => 'Bognor',
                                                    :degree => 'Lord')
      lord_bognor_two = mock_model(LordsMembership, :person => person_two, 
                                                    :title => 'Bognor',
                                                    :degree => 'Baron')
      not_lord_bognor = mock_model(LordsMembership, :person => person_three, 
                                                    :title => 'Bognor', 
                                                    :degree => 'Earl')
      LordsMembership.stub!(:members_on_date).and_return([lord_bognor_one, lord_bognor_two, not_lord_bognor])
      LordsMembership.find_duplicates(1974).should == [['person-two', 'person-one']]
    end

  end
  
  describe 'when asked to find memberships by years, degree and title' do 
    
    before do
      @attributes = {:start_date => Date.new(1977, 1, 23), 
                     :end_date => Date.new(1996, 4, 3), 
                     :title    => 'Bognor', 
                     :degree   => 'Earl'}
    end
    
    def expect_find_first(conditions)
      LordsMembership.stub!(:find)
      LordsMembership.should_receive(:find).with(:first, :conditions => conditions)
    end
  
    it 'should ask for the first membership with the same title and degree, and the same year as the start date passed and the same year as the end date or no end date' do 
      expect_find_first(["((title = ? and degree = ?) or name = ?) and year(start_date) = ? and (year(end_date) = ? or end_date is null)", 
                         'Bognor', 'Earl', 'Earl Bognor', 1977, 1996])
      LordsMembership.find_by_years_degree_and_title(@attributes)
    end
  
    it 'should ask for the first membership matching any of the alternative degrees and titles for the membership' do 
      alternative_degrees = ['Baron', 'Lord']
      LordsMembership.stub!(:alternative_degrees).and_return(alternative_degrees)
      alternative_degrees.each do |degree|
        expect_find_first(["((title = ? and degree = ?) or name = ?) and year(start_date) = ? and (year(end_date) = ? or end_date is null)", 
                         'Bognor', degree, "#{degree} Bognor", 1977, 1996])   
      end
      LordsMembership.find_by_years_degree_and_title(@attributes)
    end
    
    it 'should try a search without a place suffix' do 
      @attributes[:title] = 'Bognor of Bognor Regis'
      expect_find_first(["((title = ? and degree = ?) or name = ?) and year(start_date) = ? and (year(end_date) = ? or end_date is null)", 
                         'Bognor', 'Earl', 'Earl Bognor', 1977, 1996])
      LordsMembership.find_by_years_degree_and_title(@attributes)
    end
    
    describe 'when the attributes to be matched have no end date' do 
      
      it 'should search without an end date criteria' do 
        @attributes[:end_date] = nil
        expect_find_first(["((title = ? and degree = ?) or name = ?) and year(start_date) = ?", 
                           'Bognor', 'Earl', 'Earl Bognor', 1977])
        LordsMembership.find_by_years_degree_and_title(@attributes)
      end
      
      it 'should search for titles with the same beginning and a place suffix without an end date criteria' do 
        @attributes[:end_date] = nil
        expect_find_first(["((title like ? and degree = ?) or name like ?) and year(start_date) = ?", 
                           'Bognor of %', 'Earl', 'Earl Bognor of %', 1977])
        LordsMembership.find_by_years_degree_and_title(@attributes)
      end
       
    end
  
    describe 'when the title has no place suffix' do 
      
      it 'should look for titles that have the same beginning but have a place suffix' do 
        expect_find_first(["((title like ? and degree = ?) or name like ?) and year(start_date) = ? and (year(end_date) = ? or end_date is null)", 
                           'Bognor of %', 'Earl', 'Earl Bognor of %', 1977, 1996])
        LordsMembership.find_by_years_degree_and_title(@attributes)
      end
    
    end
    
  end
  
  describe 'when asked for members on date by person' do 
  
    it 'should return a list of a count and a list of [person, membership list] lists sorted by person lastname' do
      d_person = mock_model(Person, :lastname => 'Driver')
      m_person = mock_model(Person, :lastname => 'Minnie')
      d_membership = mock_model(LordsMembership, :person => d_person, :person_id => d_person.id)
      m_membership = mock_model(LordsMembership, :person => m_person, :person_id => m_person.id)
      second_m_membership = mock_model(LordsMembership, :person => m_person, :person_id => m_person.id)
      members = [m_membership, d_membership, second_m_membership] 
      LordsMembership.stub!(:members_on_date).and_return(members)
      expected = [2, [[d_person.id, [d_membership]], [m_person.id, [m_membership, second_m_membership]]]]
      LordsMembership.members_on_date_by_person(Date.new(1967, 5, 12)).should == expected
    end
    
    it 'should return an array containing zero and an empty list if there are no members' do 
      LordsMembership.stub!(:members_on_date).and_return([])
      LordsMembership.members_on_date_by_person(Date.new(2004, 1, 1)).should == [0, []]
    end

  end
  
  describe  ' when returning the count on a date' do 
  
    before do
      @date = Date.new(1846, 3, 18)
    end
    
    it 'should ask for any memberships whose date range encompasses the date' do 
      LordsMembership.stub!(:query_date_params).and_return('query_date_params')
      conditions = ['query_date_params', @date, @date]
      LordsMembership.should_receive(:find).with(:all, :conditions => conditions).and_return([])
      LordsMembership.count_on_date(@date)
    end
    
    it 'should return a count of the unique people associated with the memberships' do 
      membership_one = mock_model(LordsMembership, :person_id => 21)
      membership_two = mock_model(LordsMembership, :person_id => 21)
      membership_three = mock_model(LordsMembership, :person_id => 1)
      LordsMembership.stub!(:find).and_return([membership_one, membership_two, membership_three])
      LordsMembership.count_on_date(@date).should == 2
    end

  end
  
  describe 'when asked for memberships by name' do 
  
    before do
      @name = 'test name'
      @membership_lookups = {}
    end
    
    it 'should ask for a hash of the parts of the name' do 
      Person.should_receive(:name_hash).and_return({})
      LordsMembership.get_memberships_by_name(@name, @membership_lookups)
    end
    
    it 'should return an empty list if the name hash created does not have a lastname key' do 
      Person.stub!(:name_hash).and_return({})
      LordsMembership.get_memberships_by_name(@name, @membership_lookups).should == []
    end
    
    it 'should not return any membership that matches by title without place but does not match by place' do 
      Person.stub!(:name_hash).and_return({:lastname => 'roberts', 
                                                       :title => 'lord roberts of llandudno', 
                                                       :title_place => 'llandudno'})
      place_titles = LordsMembership.hash_of_lists
      place_titles['lord roberts of gwent'] << 53
      titles = LordsMembership.hash_of_lists
      titles['lord roberts'] << 54
      @membership_lookups = { :titles => titles, 
                              :place_titles => place_titles }
      LordsMembership.get_memberships_by_name(@name, @membership_lookups).should == [54]                                                                        
    end
    
    it 'should return a membership that matches by title without place' do 
      Person.stub!(:name_hash).and_return({:lastname => 'roberts', 
                                                       :title => 'lord roberts'})
      place_titles = LordsMembership.hash_of_lists
      place_titles['lord roberts of gwent'] << 53
      titles = LordsMembership.hash_of_lists
      titles['lord roberts'] << 54
      @membership_lookups = { :titles => titles, 
                             :place_titles => place_titles }
      LordsMembership.get_memberships_by_name(@name, @membership_lookups).should == [54] 
    end
    
    it 'should return a placeless title matching a title with a place if there are no place matches' do 
      Person.stub!(:name_hash).and_return({:lastname => 'roberts', 
                                                       :title => 'lord roberts of llandudno', 
                                                       :title_place => 'llandudno'})
      place_titles = LordsMembership.hash_of_lists
      titles = LordsMembership.hash_of_lists
      titles['lord roberts'] << 54
      titles['baron roberts'] << 54
      @membership_lookups = { :titles => titles, 
                            :place_titles => place_titles }
      LordsMembership.get_memberships_by_name(@name, @membership_lookups).should == [54]
    end

    it 'should try a version with "Baron"' do 
      Person.stub!(:name_hash).and_return({:lastname => 'roberts', 
                                                       :title => 'lord roberts'})
      place_titles = LordsMembership.hash_of_lists
      titles = LordsMembership.hash_of_lists
      titles['baron roberts'] << 54
      @membership_lookups = { :titles => titles, 
                           :place_titles => place_titles }
      LordsMembership.get_memberships_by_name(@name, @membership_lookups).should == [54] 
    end
  
  end
  
  describe 'when asked for degree and title' do 
  
    it 'should return "Baroness Nicholson of Winterbourne" for a membership with degree "Baroness" and title "Nicholson of Winterbourne"' do 
      membership = LordsMembership.new(:degree => 'Baroness', :title => "Nicholson of Winterbourne")
      membership.degree_and_title.should == 'Baroness Nicholson of Winterbourne'
    end
  
  end
  
  describe 'when asked for title versions of a title string' do 
    
    it 'should return "earl powis" and "earl of powis" for "Earl Powis"' do 
      LordsMembership.title_versions("Earl Powis").should == ['earl powis', 'earl of powis']
    end
    
  end
  
  describe 'when rendering json' do 
  
    before do 
      @model = LordsMembership.new(:person => Person.new)
    end
    
    it_should_behave_like 'a json-rendering model'
  
  end
end