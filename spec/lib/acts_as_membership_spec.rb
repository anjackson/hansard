require File.dirname(__FILE__) + '/../spec_helper'

describe "a membership class" do 
  
  before do
    self.class.send(:include, Acts::Membership)
    self.class.acts_as_membership
  end
  
  describe "when adding a membership to a lookup hash" do 
  
    before do 
      @date = Date.new(1922, 5, 26)
      @person = mock_model(Person, :lastname => 'Jones', 
                                   :firstname => 'Bob', 
                                   :alternative_names => [], 
                                   :office_holders => [])      
      @member = mock_model(LordsMembership, :person => @person, 
                                   :degree_and_title => 'Lord Jones of London', 
                                   :name => '1st Lord Jones of Luton')
      @alternative_title = mock_model(AlternativeTitle, :degree => 'Earl', 
                                                      :title => 'Jones', 
                                                      :first_possible_date => @date - 4, 
                                                      :last_possible_date => @date + 4, 
                                                      :name => nil, 
                                                      :degree_and_title => 'Earl Jones'
                                                      )
      @person.stub!(:alternative_titles).and_return([@alternative_title])
      @hashes = {:lastnames => {'jones' => []}, 
                 :place_titles => {'lord jones of london' => [], 
                                   'baron jones of london' => [], 
                                   'lord jones of luton' => [], 
                                   'baron jones of luton' => []},
                 :titles => {'lord jones' => [], 'baron jones' => [], 'earl jones' => []}}
    end
    
    it 'should add a title with place value to the hash if the person has a title with a place and the hash has a key for titles with places' do 
      self.class.add_membership_to_lookups(@member, @hashes, @date)
      @hashes[:place_titles]['lord jones of london'].should == [@member.id]
    end
    
    it 'should add a version of the title without place to the hash if the person has a title with a place and the hash has a key for titles' do 
      self.class.add_membership_to_lookups(@member, @hashes, @date)
      @hashes[:titles]['lord jones'].should == [@member.id]
    end
    
    it 'should add the title to the hash if it does not have a place and the hash has a titles key' do 
      @member.stub!(:degree_and_title).and_return('Lord Jones')
      self.class.add_membership_to_lookups(@member, @hashes, @date)
      @hashes[:titles]['lord jones'].should == [@member.id]
    end
    
    it 'should add the name to the hash if the membership has a name with a place and the hash has a key for titles with places' do 
      self.class.add_membership_to_lookups(@member, @hashes, @date)
      @hashes[:place_titles]['lord jones of luton'].should == [@member.id]
    end
    
    it 'should add an alternative title relevant on the date to the lookup if the hash has a key for titles and a key for titles without places' do 
      self.class.add_membership_to_lookups(@member, @hashes, @date)
      @hashes[:titles]['earl jones'].should == [@member.id]
    end
  
  end
  
end