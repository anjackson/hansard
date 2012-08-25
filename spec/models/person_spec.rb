require File.dirname(__FILE__) + '/../spec_helper'

def get_person
  Person.new(:firstname => 'Peter', 
             :lastname  => 'Wimsey', 
             :honorific => 'Lord')
end

describe 'a method that requires attributes', :shared => true do 
  
  it 'should return an empty list if any required attribute is missing' do 
    @required_attributes.each do |required_attribute|
      expect_empty_if_nil(@attributes, required_attribute, @method, @response)
    end
  end
  
end

describe Person do 

  def expect_empty_if_nil(attributes, key, method, response = [])
    attributes[key] = nil
    Person.send(method, attributes).should == response
  end

  describe 'when rendering json' do 

    before do 
      @model = Person.new(:office_holders => [OfficeHolder.new(:person => Person.new)], 
                          :commons_memberships => [CommonsMembership.new(:constituency => Constituency.new)])
    end

    it_should_behave_like 'a json-rendering model'

  end

  describe 'when finding all people' do
  
    it 'should ask for all people with memberships ordered by lastname ascending' do 
      Person.should_receive(:find).with(:all, :conditions => ['membership_count > 0'], :order => 'lastname asc').and_return([])
      Person.find_all_sorted
    end
  
    it 'should sort any returned people by ascii alphabetical name' do
      om_name = mock_model(Person, :ascii_alphabetical_name => 'Omlaut', :lastname => 'Ömlaut')
      on_name = mock_model(Person, :ascii_alphabetical_name => 'Onlaut', :lastname => 'Onlaut')
      Person.stub!(:find).and_return([on_name, om_name])
      Person.find_all_sorted.should == [om_name, on_name]
    end
  
  end
  
  describe 'when asked to find people with concurrent memberships' do 
    
    it 'should find a person who has overlapping memberships' do 
      person = Person.create!(:firstname => 'test', :lastname => 'name')
      constituency = Constituency.create!(:name => 'test constituency')
      membership_one = CommonsMembership.create!(:person => person, 
                                                 :constituency => constituency,
                                                 :start_date => Date.new(1984, 4, 11), 
                                                 :end_date => Date.new(1985, 4, 11))
      membership_two = CommonsMembership.create!(:person => person, 
                                                 :constituency => constituency,
                                                 :start_date => Date.new(1985, 1, 10), 
                                                 :end_date => Date.new(1985, 6, 21))
      Person.find_with_concurrent_memberships.should == [person]
    end
    
  end
  
  describe 'when asked to find people by lastname and exact dates of birth and death' do 
    
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([])
      @required_attributes = [:date_of_birth, :lastname]
      @method = :find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact
      @response = []
    end  
    
    it_should_behave_like 'a method that requires attributes'
  
    it 'should ask for people matching the lastname and dates of birth and death whose dates are not estimated' do 
      Person.should_receive(:find).with(:all, :conditions => ['people.lastname = ? and 
                                                               people.date_of_birth = ? and 
                                                               people.estimated_date_of_birth = ? and
                                                               people.date_of_death = ? and 
                                                               people.estimated_date_of_death = ?'.squeeze(' '),
                                                               'b', Date.new(1900, 4, 2), 
                                                               false, Date.new(1933, 5, 24), false]).and_return([mock_model(Person, :null_object => true)])
      Person.find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact(@attributes)
    end
    
    describe 'if there is no date of death in the attributes to be matched' do 
    
      before do 
        @attributes[:date_of_death] = nil
      end
      
      it 'should ask for people matching the lastname and date of birth who have no date of death' do 
        Person.should_receive(:find).with(:all, :conditions => ['people.lastname = ? and 
                                                                 people.date_of_birth = ? and 
                                                                 people.estimated_date_of_birth = ? and
                                                                 people.date_of_death is NULL'.squeeze(' '),
                                                                 'b', Date.new(1900, 4, 2), 
                                                                 false]).and_return([mock_model(Person, :null_object => true)])
        Person.find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact(@attributes)
      end
      
    end
    
  end
  
  describe 'when asked to find people by name and exact date of birth' do 

    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([])
      @required_attributes = [:date_of_birth, :firstname, :lastname]
      @method = :find_all_by_name_and_date_of_birth_exact
      @response = []
    end  
    
    it_should_behave_like 'a method that requires attributes'
  
    it 'should ask for people matching the names and date of birth whose date of birth is not estimated' do 
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               people.date_of_birth = ? and 
                                                               people.estimated_date_of_birth = ?'.squeeze(' '),
                                                               'a', 'b', Date.new(1900, 4, 2), 
                                                               false]).and_return([mock_model(Person, :null_object => true)])
      Person.find_all_by_name_and_date_of_birth_exact(@attributes)                                                              
    end
    
    it 'should not return any people whose year of death does not match the year or death given if one is given' do 
      non_match = mock_model(Person, :date_of_death => Date.new(1923, 1, 12))
      Person.stub!(:find).and_return([non_match])
      Person.find_all_by_name_and_date_of_birth_exact(@attributes).should == []
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria).and_return([])
      Person.find_all_by_name_and_date_of_birth_exact(@attributes)
    end
  
  
  end
  
  describe 'when asked to find people by name and exact date of death' do 
  
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([])
      @required_attributes = [:date_of_death, :firstname, :lastname]
      @method = :find_all_by_name_and_date_of_death_exact
      @response = []
    end
    
    it_should_behave_like 'a method that requires attributes'

    it 'should ask for people matching the names and date of death (+/- 1 day) whose date of death is not estimated' do 
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               (people.date_of_death = ? or people.date_of_death = ? or people.date_of_death = ?) and 
                                                               people.estimated_date_of_death = ?'.squeeze(' '),
                                                               'a', 'b', Date.new(1933, 5, 24), Date.new(1933, 5, 25), Date.new(1933, 5, 23),
                                                               false]).and_return([mock_model(Person, :null_object => true)])
      Person.find_all_by_name_and_date_of_death_exact(@attributes)                                                              
    end
    
    it 'should not return any people whose year or birth does not match the year or birth given if one is given' do 
      non_match = mock_model(Person, :date_of_birth => Date.new(1899, 1, 12))
      Person.stub!(:find).and_return([non_match])
      Person.find_all_by_name_and_date_of_death_exact(@attributes).should == []
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria).and_return([])
      Person.find_all_by_name_and_date_of_death_exact(@attributes)
    end
  
  end
  
  describe 'when asked to find people by name, birth year and death year and estimated dates' do 
  
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([mock_model(Person)])
      @required_attributes = [:firstname, :firstnames, :lastname, :date_of_birth, :date_of_death]
      @method = :find_all_by_name_birth_and_death_years_estimated
      @response = []
    end
    
    it_should_behave_like 'a method that requires attributes'
    
    it 'should ask for people whose names match and whose years of birth and death match and whose dates of birth and death are estimated' do 
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_birth) = ? and 
                                                               YEAR(people.date_of_death) = ? and 
                                                               people.estimated_date_of_birth = ? and 
                                                               people.estimated_date_of_death = ?'.squeeze(' '), 
                            'a', 'b', 1900, 1933, true, true]).and_return([])
      Person.find_all_by_name_birth_and_death_years_estimated(@attributes)    
    end
    
    it 'should ask for people whose aliases match and whose years of birth and death match and whose dates of birth and death are estimated' do 
      Person.stub!(:find).and_return([])
      AlternativeName.stub!(:find).and_return([])
      AlternativeName.should_receive(:find).with(:all, :conditions => ['alternative_names.firstname = ? and 
                                                                        alternative_names.lastname = ? and 
                                                                        YEAR(people.date_of_birth) = ? and 
                                                                        YEAR(people.date_of_death) = ? and 
                                                                        people.estimated_date_of_birth = ? and 
                                                                        people.estimated_date_of_death = ?'.squeeze(' '),
                                      'a', 'b', 1900, 1933, true, true], :include => :person).and_return([])
      Person.find_all_by_name_birth_and_death_years_estimated(@attributes)
    end
    
    it 'should ask for all people whose name stripped of hyphens is the same as hyphen-stripped name, and whose birth and death year match and dates are estimated' do 
      Person.stub!(:find).and_return([])
      Person.should_receive(:find).with(:all, :conditions => ["REPLACE(CONCAT_WS(' ',people.full_firstnames, people.lastname), '-', ' ') = ? and 
                                            YEAR(people.date_of_birth) = ? and 
                                            YEAR(people.date_of_death) = ? and 
                                            people.estimated_date_of_birth = ? and 
                                            people.estimated_date_of_death = ?".squeeze(' '), 
                                            'a c b', 1900, 1933, true, true]).exactly(1).times.and_return([])
      Person.find_all_by_name_birth_and_death_years_estimated(@attributes) 
    end
    
    it 'should ask for people whose alternative name stripped of hyphens is the same as hyphen-stripped name, and whose birth and death year match and dates are estimated' do 
      Person.stub!(:find).and_return([])
      AlternativeName.stub!(:find).and_return([])
      AlternativeName.should_receive(:find).with(:all, :conditions => ["REPLACE(CONCAT_WS(' ',alternative_names.full_firstnames, alternative_names.lastname), '-', ' ') = ? and 
                                           YEAR(people.date_of_birth) = ? and 
                                           YEAR(people.date_of_death) = ? and 
                                           people.estimated_date_of_birth = ? and 
                                           people.estimated_date_of_death = ?".squeeze(' '), 
                                           'a c b', 1900, 1933, true, true], 
                                           :include => :person).and_return([])
      Person.find_all_by_name_birth_and_death_years_estimated(@attributes)
    end
    
    it 'should return matches of all types' do 
      person_match = mock_model(Person)
      alternative_name_person = mock_model(Person)
      alternative_name_match = mock_model(AlternativeName, :person => alternative_name_person)
      Person.stub!(:find).and_return([person_match])
      AlternativeName.stub!(:find).and_return([alternative_name_match])
      Person.find_all_by_name_birth_and_death_years_estimated(@attributes).should == [person_match, alternative_name_person] 
    end
    
  end
  
  describe 'when asked to confirm that a person is not present in the database' do 
  
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b'}
      Person.stub!(:find).and_return([mock_model(Person)])
      @required_attributes = [:lastname, :date_of_birth, :date_of_death]
      @method = :missing? 
      @response = false
    end
    
    it_should_behave_like 'a method that requires attributes'
  
    it 'should return false if there are people with the lastname' do 
      Person.stub!(:find).with(:all, :conditions => ["lastname = ?", @attributes[:lastname]]).and_return([mock_model(Person)])
      Person.missing?(@attributes).should be_false
    end
    
    it 'should return false if there are people with the lastname as an alternative name' do 
      AlternativeName.stub!(:find).with(:all, :conditions => ["lastname = ?", @attributes[:lastname]]).and_return([mock_model(Person)])
      Person.missing?(@attributes).should be_false
    end
    
    it 'should return false if there are people with the year of birth and year of death' do 
      Person.stub!(:find).with(:all, :conditions => ['YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 1900, 1933]).and_return([mock_model(Person)])
      Person.missing?(@attributes).should be_false
    end
    
    it 'should return true if there are no people with the lastname, year of birth or year of death' do 
      Person.stub!(:find).with(:all, :conditions => ['lastname = ?', 'b']).and_return([])
      AlternativeName.stub!(:find).with(:all, :conditions => ['lastname = ?', 'b']).and_return([])
      Person.stub!(:find).with(:all, :conditions => ['YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 1900, 1933]).and_return([])
      Person.missing?(@attributes).should be_true
    end
    
    describe 'when the type of match requested is loose' do 
    
      it 'should return false if no firstname is passed' do 
        @attributes[:firstname] = nil
        Person.missing?(@attributes, match=:loose).should be_false
      end
      
      it 'should return false if there are people by this first and last name' do 
        Person.stub!(:find).with(:all, :conditions => ['firstname = ? and lastname = ?', 'a', 'b']).and_return([mock_model(Person)])
        Person.missing?(@attributes, match=:loose).should be_false
      end
       
      it 'should return false if there are alternative names with this first and last name' do 
        AlternativeName.stub!(:find).with(:all, :conditions => ['firstname = ? and lastname = ?', 'a', 'b']).and_return([mock_model(Person)])
        Person.missing?(@attributes, match=:loose).should be_false
      end
      
      it 'should return true if there are no people with the names, and no people with the year of birth and death' do 
        Person.stub!(:find).with(:all, :conditions => ['firstname = ? and lastname = ?', 'a', 'b']).and_return([])
        AlternativeName.stub!(:find).with(:all, :conditions => ['firstname = ? and lastname = ?', 'a', 'b']).and_return([])
        Person.stub!(:find).with(:all, :conditions => ['YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 1900, 1933]).and_return([])
        Person.missing?(@attributes, match=:loose).should be_true
      end
    
    end
  
  end
  
  describe 'when asked to find people by name and estimated year of death' do 
    
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return(mock_model(Person))
      @method = :find_all_by_name_and_death_year_estimated
      @required_attributes = [:firstname, :firstnames, :lastname]
      @response = []
    end
    
    it_should_behave_like 'a method that requires attributes'
    
    it 'should return an empty array if there is no lastname' do 
      @attributes[:lastname] = nil
      Person.find_all_by_name_and_death_year_estimated(@attributes).should == []
    end
    
    it 'should return an empty array if there is no date of death' do 
      @attributes[:date_of_death] = nil
      Person.find_all_by_name_and_death_year_estimated(@attributes).should == []
    end
    
    it 'should ask for people matching the name and year of death whose date of death is estimated' do 
      Person.stub!(:find)
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_death) = ? and 
                                                               people.estimated_date_of_death = ?'.squeeze(' '),
                                        'a', 'b', 1933, true]).and_return(mock_model(Person, :null_object => true))
      Person.find_all_by_name_and_death_year_estimated(@attributes)
    end
    
    it 'should not return any people whose year or birth does not match the year or birth given if one is given' do 
      non_match = mock_model(Person, :date_of_birth => Date.new(1899, 1, 12))
      Person.stub!(:find).and_return([non_match])
      Person.find_all_by_name_and_death_year_estimated(@attributes).should == []
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria).and_return([])
      Person.find_all_by_name_and_death_year_estimated(@attributes)
    end
    
  end
  
  
  describe 'when asked to find people by name and estimated year of birth' do 
    
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :date_of_birth => Date.new(1900, 4, 2),
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([mock_model(Person)])
      @method = :find_all_by_name_and_birth_year_estimated
      @required_attributes = [:firstname, :firstnames, :lastname]
      @response = []
    end
    
    it_should_behave_like 'a method that requires attributes'
    
    it 'should return an empty array if there is no lastname' do 
      @attributes[:lastname] = nil
      Person.find_all_by_name_and_birth_year_estimated(@attributes).should == []
    end
    
    it 'should return an empty array if there is no date of birth' do 
      @attributes[:date_of_birth] = nil
      Person.find_all_by_name_and_birth_year_estimated(@attributes).should == []
    end
    
    it 'should ask for people matching the name and year of death whose date of death is estimated' do 
      Person.stub!(:find)
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_birth) = ? and 
                                                               people.estimated_date_of_birth = ?'.squeeze(' '),
                                        'a', 'b', 1900, true]).and_return(mock_model(Person, :null_object => true))
      Person.find_all_by_name_and_birth_year_estimated(@attributes)
    end
    
    it 'should not return any people whose year or birth does not match the year or birth given if one is given' do 
      non_match = mock_model(Person, :date_of_death => Date.new(1945, 1, 12))
      Person.stub!(:find).and_return([non_match])
      Person.find_all_by_name_and_birth_year_estimated(@attributes).should == []
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria).and_return([])
      Person.find_all_by_name_and_birth_year_estimated(@attributes)
    end
    
  end
  
  describe 'when asked to find people by name, birth year and date of death' do 
  
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :year_of_birth => 1901,
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([])
      @required_attributes = [:year_of_birth, :firstname, :lastname]
      @method = :find_all_by_name_birth_year_and_no_date_of_death
      @response = []
    end
  
    it_should_behave_like 'a method that requires attributes'
  
    it 'should ask for people that match the names, year of birth and have no date of death' do 
      @attributes.delete(:date_of_birth)
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_birth) = ? and 
                                                               people.date_of_death is NULL'.squeeze(' '), 
                                              'a', 'b', 1901]).and_return([])
      Person.find_all_by_name_birth_year_and_no_date_of_death(@attributes)
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria)
      Person.find_all_by_name_birth_year_and_no_date_of_death(@attributes)
    end
    
  end
  
  describe 'when asked to find people by name, birth year and date of death' do 
  
    before do 
      @attributes = {:date_of_death => Date.new(1933, 5, 24),
                     :year_of_birth => 1901,
                     :firstname => 'a', 
                     :lastname => 'b', 
                     :firstnames => 'a c'}
      Person.stub!(:find).and_return([])
      @required_attributes = [:year_of_birth, :date_of_death, :firstname, :lastname]
      @method = :find_all_by_name_birth_year_and_date_of_death
      @response = []
    end
  
    it_should_behave_like 'a method that requires attributes'
    
    it 'should ask for people matching the names, year of the date of birth and date of death if given a date of birth' do 
      @attributes[:date_of_birth] = Date.new(1900, 12, 10)
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_birth) = ? and 
                                                               people.date_of_death = ?'.squeeze(' '), 
                                              'a', 'b', 1900, Date.new(1933, 5, 24)]).and_return([])
      Person.find_all_by_name_birth_year_and_date_of_death(@attributes)
    end
    
    it 'should ask for people matching the names, year of birth and date of death if not given a date of birth' do 
      @attributes.delete(:date_of_birth)
      Person.should_receive(:find).with(:all, :conditions => ['people.firstname = ? and 
                                                               people.lastname = ? and 
                                                               YEAR(people.date_of_birth) = ? and 
                                                               people.date_of_death = ?'.squeeze(' '), 
                                              'a', 'b', 1901, Date.new(1933, 5, 24)]).and_return([])
      Person.find_all_by_name_birth_year_and_date_of_death(@attributes)
    end
    
    it 'should ask for people by all name versions' do 
      Person.should_receive(:find_by_name_and_other_criteria)
      Person.find_all_by_name_birth_year_and_date_of_death(@attributes)
    end
    
  end
  
  describe 'when asked to find people by names and years' do 
    
    it 'should return an empty array if there is no date of birth or year of birth specified' do 
      attributes = {:year_of_death => 1933}
      Person.find_all_by_names_and_years(attributes).should == []
    end
    
    it 'should ask for people with the year of birth, year of death, first name and lastname when given birth and death years' do 
      attributes = {:year_of_birth => 1922, 
                    :year_of_death => 1933, 
                    :firstname => 'John', 
                    :lastname => 'Doe'}
      Person.should_receive(:find).with(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 
          'John', 'Doe', 1922, 1933])
      Person.find_all_by_names_and_years(attributes)
    end
    
    it 'should ask for people with the year of birth, first name and lastname when given birth year' do 
      attributes = {:year_of_birth => 1922, 
                    :firstname => 'John', 
                    :lastname => 'Doe'}
      Person.should_receive(:find).with(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ?', 
          'John', 'Doe', 1922])
      Person.find_all_by_names_and_years(attributes)
    end
    
    it 'should ask for people with the year of birth, year of death, first name and lastname when given dates' do 
      attributes = {:date_of_birth => Date.new(1922, 5, 13), 
                    :date_of_death => Date.new(1933, 4, 22), 
                    :firstname => 'John', 
                    :lastname => 'Doe'}
      Person.should_receive(:find).with(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 
          'John', 'Doe', 1922, 1933])
      Person.find_all_by_names_and_years(attributes)
    end
    
    it 'should ask for people with the year of birth, first name and lastname when given birth date' do 
      attributes = {:date_of_birth => Date.new(1922, 5, 13), 
                    :firstname => 'John', 
                    :lastname => 'Doe'}
      Person.should_receive(:find).with(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ?', 
          'John', 'Doe', 1922])
      Person.find_all_by_names_and_years(attributes)
    end
    
  end

  describe 'when asked for its name' do 
  
    it 'should return a name in the form "Lord Peter Wimsey"' do 
      get_person.name.should == 'Lord Peter Wimsey'
    end
    
    it 'should return "Earl of Ancram" for a person with honorific "Earl of", first name "Michael" and lastname "Ancram"' do 
      person = Person.new(:firstname => "Michael", :lastname => "Ancram", :honorific => "Earl of")
      person.name.should == "Earl of Ancram"
    end
  
  end

  describe 'when asked for its alphabetical name' do 

    it 'should return a name in the form "Wimsey, Lord Peter"' do 
      get_person.alphabetical_name.should == 'Wimsey, Peter (Lord)'
    end
  
  end

  describe "finding partial matches" do
  
    it 'should ask by default for 5 people whose lowercase lastname is like the lowercase last part of the partial provided (split by dashes)' do
      Person.should_receive(:find).with(:all, {:conditions => ["LOWER(lastname) LIKE ?", '%wimsey%' ],
                        :order => "lastname ASC", :limit => 5})
      Person.find_partial_matches('lord-peter-wimsey')
    end

    it 'should ask by default for 5 people whose lowercase lastname is like the lowercase last part of the partial provided (split by spaces)' do
      Person.should_receive(:find).with(:all, {:conditions => ["LOWER(lastname) LIKE ?", '%wimsey%' ],
                        :order => "lastname ASC", :limit => 5})
      Person.find_partial_matches('Lord Peter Wimsey')
    end
  
    it 'should ask for 10 people matching the criteria if a limit of 10 is supplied' do 
      Person.should_receive(:find).with(:all, {:conditions => ["LOWER(lastname) LIKE ?", '%wimsey%' ],
                        :order => "lastname ASC", :limit => 10})
      Person.find_partial_matches('Lord Peter Wimsey', limit=10)
    end

  end

  describe "when asked for ascii alphabetical name" do 

    it 'should return "Omlaut" for alphabetical name "Ömlaut"' do 
      person = Person.new(:lastname => "Ömlaut")
      person.ascii_alphabetical_name.should == 'Omlaut'
    end
  
    it 'should return "Bob" for "Bob"' do 
      person = Person.new(:lastname => 'Bob')
      person.ascii_alphabetical_name.should == 'Bob'
    end
  
  end

  describe "when asked if a name is a match" do 

    before(:each) do 
      Person.stub!(:match_form).with("first").and_return("first match form")
      Person.stub!(:match_form).with("last").and_return("last match form")
      Person.stub!(:match_form).with("FIRST").and_return("first match form")
      Person.stub!(:match_form).with("LAST").and_return("last match form")
      Person.stub!(:match_form).with("ANY").and_return("any match form")
      date = Date.new(2004, 1, 1)
    end
  
    it 'should remove a "Rt. Hon. " prefix from the firstnames passed to it' do 
      Person.stub!(:match_form)
      Person.should_receive(:match_form).with("FIRST")
      person = Person.new(:lastname => "last", :firstname => "first")
      person.name_match?('Rt. Hon. FIRST', 'SECOND', @date)
    end
  
    it 'should return true if the match forms of the first and last names match the first and last name' do 
      person = Person.new(:lastname => 'LAST', :firstname => "FIRST")
      person.name_match?('FIRST SECOND', 'LAST', @date).should be_true
    end
  
    it 'should return false if the match forms of the first and last names do not match' do 
      person = Person.new(:lastname => 'LAST', :firstname => "FIRST")
      person.name_match?('ANY SECOND', 'LAST', @date).should be_false
    end
  
  end

  describe "when asked if a name is a lastname match" do 

    it 'should return true if the match form of the name and the match form of the person\'s lastname are the same' do 
      Person.stub!(:match_form).with("name one").and_return("name")
      Person.stub!(:match_form).with("name two").and_return("name")
      date = Date.new(2004, 1, 1)
      person = Person.new(:lastname => 'name one')
      person.lastname_match?('name two', date).should be_true
    end
  
    it 'should return true if the person has an alternative name whose period covers the date and whose match form matches the match form of the lastname' do 
       person = Person.new(:lastname => 'name no match')
        date = Date.new(2004, 1, 1)
      alternative_name = mock_model(AlternativeName, :lastname => "name one", 
                                                     :start_date => date - 1, 
                                                     :end_date => date + 1)
      person.stub!(:alternative_names).and_return([alternative_name])
      Person.stub!(:match_form).and_return("no match")
      Person.stub!(:match_form).with("name one").and_return("name")
      Person.stub!(:match_form).with("name two").and_return("name")
      person.lastname_match?('name two', date).should be_true
    end
  
    it 'should return false if no lastname or alternate name matches' do 
      person = Person.new(:lastname => 'name no match')
      date = Date.new(2004, 1, 1)
      Person.stub!(:match_form).and_return("no match")
      Person.stub!(:match_form).with("name two").and_return("name")
      person.lastname_match?('name two', date).should be_false
    end

  end

  describe "when asked for the match form of a name" do 

    it 'should return "opik" for "&#x00D6;pik"' do 
      Person.match_form("&#x00D6;pik").should == 'opik'
    end
  
  end

  describe 'when asked for a name hash' do 
  
    it 'should convert any html entities in the name' do
      name = "Mr. &#x00D6;pik"
      lastnames = mock('hash', :[] => [])
      Person.should_receive(:decode_entities).with(name).and_return("Mr. Opik")
      Person.name_hash(name)
    end
    
    it 'should return the correct keys and values for "MR. LAMBERT"' do 
      name = 'MR. LAMBERT'
      Person.name_hash(name).should == {:lastname => 'lambert'}
    end
    
    it 'should return the correct keys and values for "Lord Rooker"' do
      name = "Lord Rooker"
      Person.name_hash(name, is_title=true).should == {:lastname => 'rooker', 
                                                       :title => 'lord rooker'}
    end
    
    it 'should return the correct keys and values for "MR. W. E. GLADSTONE"' do 
      name = "MR. W. E. GLADSTONE"
      Person.name_hash(name).should == {:initial_and_lastname=>"w gladstone", 
                                        :firstname=>"w.", 
                                        :lastname=>"gladstone", 
                                        :fullname=>"w. gladstone"}
    end
    
    it 'should return the correct keys and values for "Lord Roberts of Llandudno"' do 
      name = "Lord Roberts of Llandudno"
      Person.name_hash(name, is_title=true).should == {:lastname => 'roberts', 
                                                       :title => 'lord roberts of llandudno', 
                                                       :title_place => 'llandudno'}
    end
  
    it 'should return the correct keys and values for "Captain SIDNEY HERBERT"' do 
      name = 'Captain SIDNEY HERBERT'
      Person.name_hash(name).should == {:lastname => 'herbert', 
                                        :firstname => 'sidney', 
                                        :initial_and_lastname => 's herbert', 
                                        :fullname => 'sidney herbert'}
    end
    
    it 'should return the correct keys and values for "The Lord Bishop of Newcastle"' do 
      name = 'The Lord Bishop of Newcastle'
      Person.name_hash(name, is_title=true).should == {:title => 'lord bishop of newcastle', 
                                                       :title_place => 'newcastle'}
    end
    
    it 'should return the correct keys and values for "MR. M\'CARTAN"' do 
      name = "MR. M'CARTAN"
      Person.name_hash(name).should == {:lastname => 'mccartan'}
    end
    
    it 'should return the correct keys and values for "MASTER of ELIBANK"' do 
      name = "MASTER of ELIBANK"
      Person.name_hash(name).should == {:lastname => 'elibank'}
    end
    
  end
  
  describe 'when matching a person exactly' do 
    
    before do 
      @attributes = {:date_of_death => Date.new(1944, 1, 3)}
    end
  
    describe 'when there is no date of death' do
      
      before do
        @attributes = {}
      end
      
      it 'should ask for people that match the names, birth year and have no date of death' do 
        Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
        Person.should_receive(:find_all_by_name_birth_year_and_no_date_of_death).with(@attributes).and_return([])
        Person.match_person_exact(@attributes)
      end
      
    end
    
    it 'should ask for people matching the names, and exact date of birth' do 
      Person.should_receive(:find_all_by_name_and_date_of_birth_exact).with(@attributes).and_return([])
      Person.match_person_exact(@attributes)
    end
    
    it 'should return the person found if one is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([person])
      Person.match_person_exact(@attributes).should == person
    end
    
    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([person, person])
      Person.match_person_exact(@attributes).should be_nil
    end
    
    it 'should ask for people matching the names, birth year and date of death' do
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.should_receive(:find_all_by_name_birth_year_and_date_of_death).with(@attributes).and_return([])
      Person.match_person_exact(@attributes)
    end
    
    it 'should return the person found if one is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_birth_year_and_date_of_death).and_return([person])
      Person.match_person_exact(@attributes).should == person
    end
    
    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_name_birth_year_and_date_of_death).and_return([person, person])
      Person.match_person_exact(@attributes).should be_nil
    end
    
    it 'should return nil if no people are found' do
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_name_birth_year_and_date_of_death).and_return([])
      Person.match_person_exact(@attributes).should be_nil 
    end
    
    it 'should ask for people matching the name and exact date of death' do 
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.should_receive(:find_all_by_name_and_date_of_death_exact).with(@attributes).and_return([])
      Person.match_person_exact(@attributes)
    end
    
    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_name_and_date_of_death_exact).and_return([person, person])
      Person.match_person_exact(@attributes).should be_nil
    end
    
    it 'should return nil if no people are found' do
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_name_and_date_of_death_exact).and_return([])
      Person.match_person_exact(@attributes).should be_nil 
    end
    
    it 'should ask for people matching the lastname and exact dates of birth and death' do 
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.should_receive(:find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact).with(@attributes).and_return([])
      Person.match_person_exact(@attributes)
    end
    
    it 'should return the person if one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact).and_return([person])
      Person.match_person_exact(@attributes).should == person
    end
    
    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact).and_return([person, person])
      Person.match_person_exact(@attributes).should be_nil
    end
    
    it 'should return nil if no people are found' do
      Person.stub!(:find_all_by_name_and_date_of_birth_exact).and_return([])
      Person.stub!(:find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact).and_return([])
      Person.match_person_exact(@attributes).should be_nil 
    end
    
  end
  
  describe 'when matching a person loosely' do 
  
    before do 
      @attributes = {}
    end
    
    it 'should ask for people matching the names, estimated birth and death years' do
      Person.should_receive(:find_all_by_name_birth_and_death_years_estimated).with(@attributes).and_return([])
      Person.match_person_loose(@attributes)
    end
    
    it 'should return the person found if one is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_birth_and_death_years_estimated).and_return([person])
      Person.match_person_loose(@attributes).should == person
    end
    
    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_birth_and_death_years_estimated).and_return([person, person])
      Person.match_person_loose(@attributes).should be_nil
    end
    
    it 'should return nil if no people are found' do
      Person.stub!(:find_all_by_name_birth_and_death_years_estimated).and_return([])
      Person.match_person_loose(@attributes).should be_nil 
    end
      
    it 'should ask for people matching the names and estimated death years' do
      Person.should_receive(:find_all_by_name_and_death_year_estimated).with(@attributes).and_return([])
      Person.match_person_loose(@attributes)
    end

    it 'should ask for people matching the names and estimated birth years' do
      Person.should_receive(:find_all_by_name_and_birth_year_estimated).with(@attributes).and_return([])
      Person.match_person_loose(@attributes)
    end
    
    it 'should return the person found if one is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_death_year_estimated).and_return([person])
      Person.match_person_loose(@attributes).should == person
    end

    it 'should return nil if more than one person is found' do 
      person = mock_model(Person)
      Person.stub!(:find_all_by_name_and_death_year_estimated).and_return([person, person])
      Person.match_person_loose(@attributes).should be_nil
    end

    it 'should return nil if no people are found' do
      Person.stub!(:find_all_by_name_and_death_year_estimated).and_return([])
      Person.match_person_loose(@attributes).should be_nil 
    end
    
  end
  
  

  describe "in general" do

    before(:all) do
      @person = Person.create(:lastname => "test person")
      @last_sitting = Sitting.new(:date => Date.new(2005, 1, 10))
      @first_sitting = Sitting.new(:date => Date.new(1967, 3,21))
      @middle_sitting = Sitting.new(:date => Date.new(2001, 5, 2))
      @commons_membership_one = CommonsMembership.create(:person => @person)
      @commons_membership_two = CommonsMembership.create(:person => @person)
      
      @last_section = Section.create(:sitting => @last_sitting, :date => @last_sitting.date)
      @last_sitting.all_sections << @last_section
      @second_last_contribution = Contribution.create(:section => @last_section, :commons_membership => @commons_membership_one)
      @last_contribution = Contribution.create(:section => @last_section, :commons_membership => @commons_membership_one)

      @middle_section = Section.create(:sitting => @middle_sitting, :date => @middle_sitting.date)
      @middle_sitting.all_sections << @middle_section
      @middle_contribution = Contribution.create(:section => @middle_section, :commons_membership => @commons_membership_two)

      @first_section = Section.create(:sitting => @first_sitting, :date => @first_sitting.date)
      @first_sitting.all_sections << @first_section
      @first_contribution = Contribution.create(:section => @first_section, :commons_membership => @commons_membership_two)

      @sittings = [@last_sitting, @middle_sitting, @first_sitting]
      @sittings.each{ |sitting| sitting.save! }
    end

    after(:all) do
      @person.destroy
      @sittings.each{ |sitting| sitting.destroy }
    end

    it 'should be able to find the first sitting associated with the person' do
      @person.first_sitting.should == @first_sitting
    end

    it 'should be able to find the last sitting associated with the person' do
      @person.last_sitting.should == @last_sitting
    end

    it 'should be able to return the first contribution associated with the person' do
      @person.first_contribution.should == @first_contribution
    end
    
    it 'should return nil for the first contribution if there is no first sitting' do 
      @person.stub!(:first_sitting).and_return(nil)
      @person.first_contribution.should be_nil
    end
    
    it 'should return nil for the last contribution if there is no last sitting' do 
      @person.stub!(:last_sitting).and_return(nil)
      @person.last_contribution.should be_nil
    end

    it 'should be able to return the last contribution associated with the person' do
      @person.last_contribution.should == @last_contribution
    end

    it 'should be able to give an ordered list of years in which a person made contributions' do
      @person.active_years.should == [1967, 2001, 2005]
    end

    it 'should be able to give a set of a person\'s contributions in a year grouped by section' do
      grouped_contributions = @person.contributions_in_year(2005)
      grouped_contributions.size.should == 1
      grouped_contributions.each do |contributions|
        contributions.size.should == 2
        contributions.each do |contribution|
          contribution.section.should == @last_section
        end
      end
    end
    
  end
end