require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../app/models/act'
require File.dirname(__FILE__) + '/../../app/models/bill'

def mock_contribution_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:<<)
  mock_builder.stub!(:p)
  mock_builder
end

describe Contribution do

  describe "when finding mentions" do

    def stubbed_contribution acts=[], bills=[]
      contribution = Contribution.new
      contribution.stub!(:act_mentions).and_return acts
      contribution.stub!(:bill_mentions).and_return bills
      contribution
    end

    it 'should return act and bill mentions sorted by start position' do
      act = mock('act mention', :start_position=>40)
      bill = mock('bill mention',  :start_position=>30)
      contribution = stubbed_contribution [act], [bill]
      contribution.mentions.should == [bill, act]
    end

    it 'should not return empty array if no mentions exist' do
      stubbed_contribution.mentions.should == []
    end

  end

  describe "when asked for the initial membership list for a name and office" do
    it 'should return an empty array when the name is blank and there is no office' do
      contribution = Contribution.new
      contribution.initial_membership_list(nil,nil, CommonsMembership).should == []
    end
  end

  describe "on creation " do

    before(:each) do
      @member_name = 'Mr. Tickle'
      CommonsMembership.stub!(:find_from_contribution)
      Constituency.stub!(:find_by_name_and_date)
      Party.stub!(:find_or_create_by_name)
      @contribution = MemberContribution.new(:member_name => @member_name,
                                              :member_suffix => '(West Birkenhead) (Lab)')
      @contribution.stub!(:date).and_return(Date.new(2004, 12, 1))
      @contribution.stub!(:sitting_type).and_return('Commons')
      @contribution.stub!(:populate_mentions)
    end

    it 'should look for memberships' do
      @contribution.should_receive(:populate_memberships)
      @contribution.save
    end

    it 'should look for a constituency model if there is a constituency name ' do
      Constituency.should_receive(:find_by_name_and_date).with('West Birkenhead', @contribution.date)
      @contribution.valid?
    end

    it 'should create a party model if there is a party name and a model does not exist for that party' do
      Party.should_receive(:find_or_create_by_name).with('Lab')
      @contribution.valid?
    end

  end
  
  describe 'when asked for its associated person' do 
  
    it 'should return the person associated with its commons_membership if it has one' do 
      person = mock_model(Person)
      membership = mock_model(CommonsMembership, :person => person)
      contribution = Contribution.new(:commons_membership => membership)
      contribution.person.should == person
    end
    
    it 'should return the person associated with its lords_membership if it has one' do 
      person = mock_model(Person)
      membership = mock_model(LordsMembership, :person => person)
      contribution = Contribution.new(:lords_membership => membership)
      contribution.person.should == person
    end
    
    it 'should return nil if it does not have a commons membership' do 
      contribution = Contribution.new
      contribution.person.should be_nil
    end
  
  end
  
  describe 'when asked for its associated person id' do 
  
    it 'should return the id of the person associated with its commons_membership if it has one' do 
      membership = mock_model(CommonsMembership, :person_id => 30)
      contribution = Contribution.new(:commons_membership => membership)
      contribution.person_id.should == 30
    end
    
    it 'should return the id of the person associated with its lords_membership if it has one' do 
      membership = mock_model(LordsMembership, :person_id => 30)
      contribution = Contribution.new(:lords_membership => membership)
      contribution.person_id.should == 30
    end
    
    it 'should return nil if it does not have a commons membership' do 
      contribution = Contribution.new
      contribution.person_id.should be_nil
    end
  
  end

  describe " when parsing constituency and party" do

    def expect_constituency_and_party(member_suffix, constituency, party)
      contribution = MemberContribution.new :member_name => @member_name, :member_suffix => member_suffix
      contribution.stub!(:date).and_return(Date.new(2004, 12, 1))
      contribution.stub!(:populate_memberships)
      contribution.stub!(:populate_mentions)
      Constituency.should_receive(:find_by_name_and_date).with(constituency, contribution.date)
      if party
        Party.should_receive(:find_or_create_by_name).with(party)
      else
        Party.should_not_receive(:find_or_create_by_name)
      end
      contribution.valid?
    end

    it 'should correctly handle a member_suffix with a missing opening bracket' do
      expect_constituency_and_party('West Birkenhead) (Lab)', 'West Birkenhead', 'Lab')
    end
    
    it 'should correctly handle member_suffix "Montgomeryshire (LD)"' do 
      expect_constituency_and_party('Montgomeryshire (LD)', 'Montgomeryshire', 'LD')
    end

    it 'should correctly handle a member_suffix with no brackets' do
      expect_constituency_and_party('Sheffield, Eccleshall', 'Sheffield, Eccleshall', nil)
    end

    it 'should correctly handle a member_suffix in the form ": (Southwark and Bermondsey)"' do 
      expect_constituency_and_party(': (Southwark and Bermondsey)', 'Southwark and Bermondsey', nil)
    end

    it 'should correctly parse a member_suffix with no party and a trailing colon' do
      expect_constituency_and_party("(Newcastle upon Tyne, East and Wallsend):",  'Newcastle upon Tyne, East and Wallsend', nil)
    end

    it 'should correctly parse a member_suffix with a trailing colon and party' do
      expect_constituency_and_party('(Orkney and Shetland) (LD):', 'Orkney and Shetland', 'LD')
    end

    it 'should correctly parse a member suffix with missing closing bracket' do
      expect_constituency_and_party("(Morley and Leeds, South", 'Morley and Leeds, South', nil)
    end

    it 'should correctly parse a member suffix like "(Birmingham), (Small Heath)"' do
      expect_constituency_and_party("(Birmingham), (Small Heath)", 'Birmingham, Small Heath', nil)
    end

    it 'should correctly parse a member suffix like " (Yeovil)\'"' do
      expect_constituency_and_party(" (Yeovil)'", 'Yeovil', nil)
    end

    it 'should correctly parse a member suffix like " (Swindon). "' do
      expect_constituency_and_party(" (Swindon). ", 'Swindon', nil)
    end

    it 'should correctly parse a member suffix like " (Edinburgh), Leith) "' do
      expect_constituency_and_party(" (Edinburgh), Leith) ", 'Edinburgh, Leith', nil)
    end

    it 'should correctly parse a member suffix like "(Kingston upon Hull), East)"' do
      expect_constituency_and_party("(Kingston upon Hull), East)", 'Kingston upon Hull, East', nil)
    end

    it 'should correctly parse a member suffix like "((Roxburgh, Selkirk and Peebles)"' do
      expect_constituency_and_party("((Roxburgh, Selkirk and Peebles)", 'Roxburgh, Selkirk and Peebles', nil)
    end

    it 'should correctly parse a member suffix like "(Chipping Barnet): W"' do
      expect_constituency_and_party("(Chipping Barnet): W", 'Chipping Barnet', nil)
    end

    it 'should correctly parse a member suffix like "(Arundel and South Downs);"' do
      expect_constituency_and_party("(Arundel and South Downs);", 'Arundel and South Downs', nil)
    end

    it 'should correctly parse a member suffix like "(Ryedale)?"' do
      expect_constituency_and_party("(Ryedale)?", 'Ryedale', nil)
    end

    it 'should correctly parse a member suffix like "(Aldridge&#x2014;Brownhills)"' do
      expect_constituency_and_party("(Aldridge&#x2014;Brownhills)", 'Aldridge-Brownhills', nil)
    end

    it 'should correctly parse a member suffix like "(Banff and    Buchan)"' do
      expect_constituency_and_party("(Banff and    Buchan)", 'Banff and Buchan', nil)
    end

    it 'should correctly parse a member suffix like "(Colchester, South and (Maldon)"' do
      expect_constituency_and_party("(Colchester, South and (Maldon)", 'Colchester, South and Maldon', nil)
    end

    it 'should correctly parse a member suffix like "(East Surrey) Con)"' do
      expect_constituency_and_party("(East Surrey) Con)", 'East Surrey', 'Con')
    end

    it 'should correctly parse a member suffix like "(Beaconsfield) (Con)(urgent question)"' do
      expect_constituency_and_party("(Beaconsfield) (Con)(urgent question)", 'Beaconsfield', 'Con')
    end

    it 'should correctly parse a member suffix like "(Rochford and Southend, East) Con)"' do
      expect_constituency_and_party("(Rochford and Southend, East) Con) ", 'Rochford and Southend, East', 'Con')
    end

    it 'should correctly parse a member suffix like "(South Cambridgeshire) (Con"' do
      expect_constituency_and_party("(South Cambridgeshire) (Con", 'South Cambridgeshire', 'Con')
    end

    it 'should correctly parse a member suffix like "(Congleton (Con.)"' do
      expect_constituency_and_party("(Congleton (Con.)", 'Congleton', 'Con.')
    end

    it 'should correctly parse a member suffix like "(Havant (Con)"' do
      expect_constituency_and_party("(Havant (Con)", 'Havant', 'Con')
    end

    it 'should correctly parse a member suffix like "(Winchester) I (LD) "' do
      expect_constituency_and_party("(Winchester) I (LD) ", 'Winchester', 'LD')
    end

    it 'should correctly parse a member suffix like "(Wirral, South)|"' do
      expect_constituency_and_party("(Wirral, South)|", 'Wirral, South', nil)
    end

    it 'should correctly parse a member suffix like "s(Bury St. Edmunds)"' do
      expect_constituency_and_party("s(Bury St. Edmunds)", 'Bury St. Edmunds', nil)
    end

    it 'should correctly parse a member suffix like "Tyrie (Chichester) (Con)"' do
      expect_constituency_and_party("Tyrie (Chichester) (Con)", 'Tyrie (Chichester)', 'Con')
    end

    it 'should retain the original member suffix after parsing' do
      suffix = '(Caernarfon:)'
      parsed_name = 'Caernarfon:'
      constituency_name = "Caernarfon"
      contribution = Contribution.new :member_name => "Mr Tickle", :member_suffix => suffix
      contribution.stub!(:populate_memberships)
      contribution.stub!(:date).and_return(Date.new(2004, 12, 1))
      contribution.stub!(:populate_mentions)
      Constituency.should_receive(:find_by_name_and_date).with(parsed_name, contribution.date)
      contribution.valid?
      contribution.member_suffix.should == suffix
    end
  end

  describe " finding contributions for a sitting" do

    before(:all) do
      @sitting = Sitting.new :date => '2007-12-12'
      @section_one = Section.new
      @section_two = Section.new
      @contribution_one = Contribution.new(:section => @section_one)
      @contribution_two = Contribution.new(:section => @section_one)
      @contribution_three = Contribution.new(:section => @section_two)
      @contribution_four = Contribution.new(:section => @section_two)
      @section_one.contributions << @contribution_one
      @section_one.contributions << @contribution_two
      @section_two.contributions << @contribution_three
      @section_two.contributions << @contribution_four
      @sitting.all_sections = [@section_one, @section_two]
      @sitting.save!
    end

    it 'should return the same contributions that navigating associations should produce' do
      expected = @sitting.all_sections.map{ |section| section.contributions }.flatten
      Contribution.contributions_for_sitting(@sitting).should == expected
    end

    after(:all) do
      Sitting.delete_all
      Section.delete_all
      Contribution.delete_all
    end

  end

  describe "generally" do
    before(:each) do
      @year = 1999
      @date = Date.new(@year,12,31)
      section = mock(Section, :title => 'test', 
                              :year => @year, 
                              :date => @date)  
      @model = Contribution.new
      @model.stub!(:section).and_return(section)
      @model.stub!(:populate_mentions)
      @mock_builder = mock_contribution_builder
      @model.text = "some text"
    end

    it "should be valid" do
      @model.should be_valid
    end

    it "should return year based on parent section's year" do
      @model.year.should == @year
    end

    it "should return date based on parent section's date" do
      @model.date.should == @date
    end

    it 'should escape ampersands in its text when producing xml' do 
      @model.text = "part of any college, &c.,"
      @model.to_xml.should == '<p id="">part of any college, &amp;c.,</p>'
    end

    it_should_behave_like "an xml-generating model"

  end

  describe "when giving a title via it's associations" do

    before do
      @contribution = Contribution.new
      @section = Section.new
      @parent_section = Section.new
      @sitting = Sitting.new
    end

    it 'should be able to give a title by looking for its section, parent_section and sitting\'s titles if it is a normal contribution' do
      @contribution.should_receive(:section).any_number_of_times.and_return(@section)
      @section.should_receive(:title)
      @section.should_receive(:parent_section).any_number_of_times.and_return(@parent_section)
      @parent_section.should_receive(:title)
      @contribution.should_receive(:sitting).and_return(@sitting)
      @sitting.should_receive(:title).and_return("sitting title")
      @contribution.title_via_associations.should == "sitting title"
    end

    it 'should try titles via associations if its section title is blank if it is a normal contribution' do
      @contribution.stub!(:section).and_return(@section)
      @section.stub!(:title).and_return("")
      @section.stub!(:parent_section).and_return(@parent_section)
      @parent_section.stub!(:title).and_return("parent title")
      @contribution.title_via_associations.should == "parent title"
    end

  end

  describe ".find_by_person_in_year" do

    before(:each) do
      @person = mock_model(Person, :lastname => 'Boyes', :slug => 'mr-boyes')
      @commons_membership = mock_model(CommonsMembership, :person => @person)
      @lords_membership = mock_model(LordsMembership, :person => @person)
      @person.stub!(:commons_memberships).and_return([@commons_membership])
      @person.stub!(:lords_memberships).and_return([@lords_membership])
      @first_sitting = mock_model(HouseOfCommonsSitting)
      @first_section = mock_model(Section, :id => 1, :sitting => @first_sitting, :title => "first section", :date => Date.new(1999, 12, 31))
      @second_sitting = mock_model(HouseOfLordsSitting)
      @second_section = mock_model(Section, :id => 2, :sitting => @second_sitting, :title => "second section", :date => Date.new(1999, 12, 31))
      @third_section = mock_model(Section, :id => 3, :sitting => @second_sitting, :title => "third section", :parent_section => @second_section, :date => Date.new(1999,12,31))
      @third_sitting = mock_model(HouseOfLordsSitting)
      @fourth_section = mock_model(Section, :id => 4, :sitting => @third_sitting, :title => "fourth section", :date => Date.new(1999, 12, 30))
      @one = Contribution.new(:section => @first_section, :commons_membership => @commons_membership)
      @two = Contribution.new(:section => @second_section, :commons_membership => @commons_membership)
      @two_a = Contribution.new(:section => @third_section, :commons_membership => @commons_membership)
      @two_b = Contribution.new(:section => @third_section, :commons_membership => @commons_membership)
      @three = Contribution.new(:section => @fourth_section, :lords_membership => @lords_membership)
    end

    it 'should return an empty array if there are no contributions' do
      Contribution.stub!(:find).and_return([])
      @groups = Contribution.find_by_person_in_year(@person, 1999)
      @groups.should be_empty
    end

    it 'should return contributions grouped by year and section ascending' do
      Contribution.stub!(:find).and_return([@one, @two, @two_a, @two_b, @three])
      @groups = Contribution.find_by_person_in_year(@person, 1999)
      @groups.size.should == 4
      @groups[0].size.should == 1
      @groups[0].first.section.should == @fourth_section
      
      @groups[1].size.should == 1
      @groups[1].first.section.should == @first_section

      @groups[2].size.should == 1
      @groups[2].first.section.should == @second_section

      @groups[3].size.should == 2
      @groups[3].first.section.should == @third_section
      @groups[3].last.section.should == @third_section
    end
    
    it 'should ask for contributions with the lords membership ids if the person only has lords memberships' do 
      @person.stub!(:commons_memberships).and_return([])
      Contribution.should_receive(:find).with(:all, :conditions => ["contributions.lords_membership_id in (?) and 
                                                                     sittings.date >= ? and 
                                                                     sittings.date <= ?".squeeze(' '), 
                                                                     [@lords_membership.id], 
                                                                     Date.new(1999, 1, 1),
                                                                     Date.new(1999, 12, 31)], 
                                              :include => [{:section => [:sitting]}]).and_return([])
      Contribution.find_by_person_in_year(@person, 1999)
    end

    it 'should ask for contributions with the commons membership ids if the person only has commons memberships' do 
      @person.stub!(:lords_memberships).and_return([])
      Contribution.should_receive(:find).with(:all, :conditions => ["contributions.commons_membership_id in (?) and 
                                                                     sittings.date >= ? and 
                                                                     sittings.date <= ?".squeeze(' '), 
                                                                     [@commons_membership.id], 
                                                                     Date.new(1999, 1, 1), 
                                                                     Date.new(1999, 12, 31)], 
                                              :include => [{:section => [:sitting]}]).and_return([])
      Contribution.find_by_person_in_year(@person, 1999)
    end
    
    it 'should ask for contributions with the commons membership ids or the lords membership ids if the person has both' do 
      Contribution.should_receive(:find).with(:all, :conditions => ["(contributions.commons_membership_id in (?) or
                                                                     contributions.lords_membership_id in (?)) and 
                                                                     sittings.date >= ? and 
                                                                     sittings.date <= ?".squeeze(' '), 
                                                                     [@commons_membership.id], 
                                                                     [@lords_membership.id], 
                                                                     Date.new(1999, 1, 1), 
                                                                     Date.new(1999, 12, 31)], 
                                              :include => [{:section => [:sitting]}]).and_return([])
      Contribution.find_by_person_in_year(@person, 1999)
    end  
  end
  
  describe ".to_xml" do

    before do
      @contribution = Contribution.new
    end

    it_should_behave_like "a contribution"

  end

  describe ".cols" do

    it "should return a list of the columns for the contribution" do
      contribution = Contribution.new(:column_range => "2,3,4")
      contribution.cols.should == ['2','3','4']
    end

  end

  describe ".start_column" do
    it "should return the first column" do
      contribution = Contribution.new(:column_range => "2,3,4")
      contribution.start_column.should == '2'
    end

    it "should return nil if the contribution has no columns" do
      contribution = Contribution.new(:column_range => nil)
      contribution.start_column.should be_nil
    end
  end
  
  describe ".end_column" do
    it "should return the last column" do
      contribution = Contribution.new(:column_range => "2,3,4")
      contribution.end_column.should == '4'
    end

    it "should return nil if the contribution has no columns" do
      contribution = Contribution.new(:column_range => nil)
      contribution.end_column.should be_nil
    end
  end

  describe " when handling parent sections" do

    before do
      @grandparent = Section.new
      @parent = Section.new(:parent_section => @grandparent)
      @contribution = Contribution.new(:section => @parent)
    end

    it 'should return a list including the contribution\'s section' do
      @contribution.parent_sections.include?(@parent).should be_true
    end

    it 'should return a list including the contribution\'s section\'s parents' do
      @contribution.parent_sections.include?(@parent).should be_true
    end

    it 'should order sections with the contribution\'s own section first' do
      @contribution.parent_sections.should == [@parent, @grandparent]
    end

    it 'should be able to return it\s first linkable parent' do
      @parent.stub!(:linkable?).and_return(true)
      @contribution.first_linkable_parent.should == @parent
      @parent.stub!(:linkable?).and_return(false)
      @grandparent.stub!(:linkable?).and_return(true)
      @contribution.first_linkable_parent.should == @grandparent
    end

    it 'should return the contribution\'s section when asked for a linkable parent if the contribution has no linkable parents' do
      @parent.stub!(:linkable?).and_return(false)
      @grandparent.stub!(:linkable?).and_return(false)
      @contribution.first_linkable_parent.should == @parent
    end

  end

  describe 'when asked if it needs a Lords membership' do
    
    before do
      @sitting = mock_model(Sitting, :house => 'Lords')
      @contribution = Contribution.new
      @contribution.stub!(:sitting).and_return(@sitting)
    end
  
    it 'should return false if the sitting house is not the Lords' do 
      @sitting.stub!(:house).and_return('Commons')
      @contribution.needs_lords_membership?.should be_false
    end
    
    it 'should return false if there is no member name' do 
      @contribution.member_name = ""
      @contribution.needs_lords_membership?.should be_false
    end
    
    it 'should return false if the member name is "A noble Lord"' do 
      @contribution.member_name = 'A noble Lord'
      @contribution.needs_lords_membership?.should be_false
    end
    
  end

  describe "before validation on creation" do

    it 'should populate act mentions in it\'s text' do
      section = mock_model(Section, :parent_sections => [], :linkable? => true)
      contribution = Contribution.new(:text => "test text")
      contribution.stub!(:section).and_return(section)
      Act.should_receive(:populate_mentions).with("test text", section, contribution).and_return([])
      contribution.save!
    end

    it 'should populate Bill mentions in it\'s text' do
      section = mock_model(Section, :parent_sections => [], :linkable? => true)
      contribution = Contribution.new(:text => "test text")
      contribution.stub!(:section).and_return(section)
      Bill.should_receive(:populate_mentions).with("test text", section, contribution).and_return([])
      contribution.save!
    end

  end

  describe " when preparing text to send to solr" do

    before do
      @contribution = Contribution.new(:text => 'some test text with a <col>34</col> tag and <b>another</b> tag')
    end

    it 'should get its own text' do
      @contribution.should_receive(:text)
      @contribution.solr_text
    end

    it 'should remove any col tags and their contents' do
      @contribution.solr_text.should_not have_tag('col')
      @contribution.solr_text.should_not match(/34/)
    end

    it 'should strip any other html tags' do
      @contribution.solr_text.should_not have_tag('b')
    end

  end

  describe ' when populating memberships' do

    before do
      @contribution = Contribution.new(:member_name => 'Bob Member')
      @section = mock_model(Section, :members_in_section => [])
      @sitting = mock_model(Sitting, :offices_in_sitting => { 'office'=> [] }, 
                                     :membership_lookups => {}, 
                                     :house => 'Commons')
      @contribution.stub!(:section).and_return(@section)
      @contribution.stub!(:sitting).and_return(@sitting)
      @contribution.stub!(:person_name).and_return('Bob Member')
      CommonsMembership.stub!(:get_memberships_by_name).and_return([])
      LordsMembership.stub!(:get_memberships_by_name).and_return([])
      @contribution.stub!(:narrow_memberships_by_constituency).and_return([22])
    end
    
    it 'should try to populate a commons membership if it needs a commons membership' do
      @contribution.stub!(:needs_commons_membership?).and_return(true)
      @contribution.should_receive(:populate_commons_membership)
      @contribution.populate_memberships
    end
    
    it 'should not try to populate a commons membership if it does not need a commons membership' do
      @contribution.stub!(:needs_commons_membership?).and_return(false)
      @contribution.should_not_receive(:populate_commons_membership)
      @contribution.populate_memberships
    end
    
    it 'should try to populate a lords membership if it needs a lords membership' do
      @contribution.stub!(:needs_lords_membership?).and_return(true)
      @contribution.should_receive(:populate_lords_membership)
      @contribution.populate_memberships
    end
    
    it 'should not try to populate a lords membership if it does not need a lords membership' do
      @contribution.stub!(:needs_lords_membership?).and_return(false)
      @contribution.should_not_receive(:populate_lords_membership)
      @contribution.populate_memberships
    end

    it 'should not set the commons_membership_id if the sitting house is "Lords"' do
      @sitting.stub!(:house).and_return('Lords')
      @contribution.should_not_receive(:commons_membership_id=)
      @contribution.populate_memberships
    end

    it 'should not set the commons_membership_id if the member_name is ""' do
      @contribution.stub!(:member_name).and_return('')
      @contribution.should_not_receive(:commons_membership_id=)
      @contribution.populate_memberships
    end

    it 'should not set the commons_membership_id if the member_name is a generic member description' do
      @contribution.stub!(:member_name).and_return('A NOBLE LORD')
      @contribution.should_not_receive(:commons_membership_id=)
      @contribution.populate_memberships
    end

    it "should ask for the members in the section" do
      @section.should_receive(:members_in_section).and_return([])
      @contribution.populate_memberships
    end

    it "should ask the sitting for the membership lookups" do
      @sitting.should_receive(:membership_lookups).and_return({})
      @contribution.populate_memberships
    end

    it 'should get the person\'s name for the contribution' do
      @contribution.should_receive(:person_name).and_return('Bob Member')
      @contribution.populate_memberships
    end
    
    it 'should add a nil to the list of members in the sitting if a membership id cannot be set' do 
      @contribution.stub!(:narrow_memberships_by_constituency).and_return([])
      @contribution.members_in_section.should_receive(:<<).with nil
      @contribution.populate_memberships
    end
    
    it 'should not add a nil to the list of members in the sitting if a membership id can be set' do 
      @contribution.stub!(:narrow_memberships_by_constituency).and_return([22])
      @contribution.members_in_section.should_not_receive(:<<).with nil
      @contribution.populate_memberships
    end
    
    
    describe 'when populating a lords membership' do 
      
      before do 
        @sitting = mock_model(Sitting, :offices_in_sitting => { 'office'=> [] }, 
                                       :membership_lookups => {}, 
                                       :house => 'Lords')
        @contribution.stub!(:sitting).and_return(@sitting)
      end
      
      it 'should try and get memberships by name if the name is not blank' do
        LordsMembership.should_receive(:get_memberships_by_name).and_return([])
        @contribution.populate_memberships
      end
      
    end

    describe 'when populating a commons membership' do 
      
      it 'should try and get memberships by name if the name is not blank' do
        CommonsMembership.should_receive(:get_memberships_by_name).and_return([])
        @contribution.populate_memberships
      end

      it 'should try and get memberships by office if there is no person name and there is an office' do
        @contribution.should_receive(:person_name).and_return('')
        @contribution.stub!(:office).and_return('office')
        @contribution.should_receive(:get_memberships_by_office).and_return([])
        @contribution.populate_memberships
      end

      it 'should try to narrow memberships by office if office name and person name are present, and membership cannot be determined by constituency alone' do
        @contribution.stub!(:person_name).and_return('name')
        office = 'office'
        @contribution.stub!(:office).and_return(office)
        memberships = ['a','b']
        @contribution.should_receive(:initial_membership_list).and_return memberships
        @contribution.should_receive(:narrow_memberships_by_constituency).and_return memberships
        @contribution.should_receive(:narrow_memberships_by_office).with(memberships, office).and_return ['a']
        @contribution.populate_memberships
      end

      it 'should set the commons membership to the single value matching the name if there is one' do
        CommonsMembership.stub!(:get_memberships_by_name).and_return([22])
        @contribution.should_receive(:commons_membership_id=).with(22)
        @contribution.populate_memberships
      end

      it 'should set the commons membership to the single value matching the office if there is one' do
        @contribution.stub!(:person_name).and_return('')
        @contribution.stub!(:office).and_return('office')
        @contribution.stub!(:get_memberships_by_office).and_return([22])
        @contribution.should_receive(:commons_membership_id=).with(22)
        @contribution.populate_memberships
      end

      it 'should try and narrow the memberships using constituency if there is more than one matching the name or office' do
        CommonsMembership.stub!(:get_memberships_by_name).and_return([22,33])
        @contribution.should_receive(:narrow_memberships_by_constituency).and_return([22])
        @contribution.should_receive(:commons_membership_id=).with(22)
        @contribution.populate_memberships
      end

      it 'should set the commons membership to the most recent previous speaker in the sitting whose name or office matches if there is still more than one possible membership' do
        @contribution.stub!(:narrow_memberships_by_constituency).and_return([44,55])
        @contribution.should_receive(:narrow_memberships_by_previous_speakers).and_return([44,55])
        @contribution.should_receive(:commons_membership_id=).with(55)
        @contribution.populate_memberships
      end
      
    end
    
  end

  describe ' when getting memberships by office' do

    before do
      @holders_in_sitting = Hash.new{ |hash, key| hash[key] = [] }
      @holders_on_date = Hash.new{ |hash, key| hash[key] = [] }
      @contribution = Contribution.new
      @contribution.stub!(:membership_lookups).and_return :office_names => @holders_on_date
      @contribution.stub!(:offices_in_sitting).and_return @holders_in_sitting
    end

    it 'should try getting a unique list of members who have been identified in the sitting in the office' do
      @holders_in_sitting.should_receive(:[]).with('prime minister').and_return([22,22])
      @contribution.get_memberships_by_office('Prime Minister').should == [22]
    end

    it 'should try getting a unique list of members in the office on the date if no members have been identified in the office in the sitting' do
      @holders_in_sitting.stub!(:[]).with('prime minister').and_return([])
      @holders_on_date.should_receive(:[]).with('prime minister').and_return([22,22])
      @contribution.get_memberships_by_office('Prime Minister').should == [22]
    end

  end

  describe ' when narrowing memberships by constituency' do

    before do
      @contribution = Contribution.new(:constituency_id => 4)
      @memberships = [22, 33, 44]
      @constituencies = {4 => [33, 77, 33]}
      @contribution.stub!(:membership_lookups).and_return :constituency_ids => @constituencies
    end

    it 'should return the memberships as given if there is no constituency' do
      @contribution.constituency_id = nil
      @contribution.narrow_memberships_by_constituency(@memberships).should == @memberships
    end

    it 'should return a unique intersection of the memberships with memberships for the constituency' do
      @contribution.narrow_memberships_by_constituency(@memberships).should == [33]
    end

  end

  describe ' when narrowing memberships by office' do

    before do
      @contribution = Contribution.new
      @contribution.stub!(:membership_lookups).and_return Hash.new
      @contribution.stub!(:offices_in_sitting).and_return Hash.new
      @memberships = [22, 33, 44]
    end

    it 'should ask for the memberships by office' do
      @contribution.should_receive(:get_memberships_by_office).and_return([])
      @contribution.narrow_memberships_by_office(@memberships, 'Prime Minister')
    end

    it 'should return an intersection of the memberships with memberships for the office' do
      @contribution.stub!(:get_memberships_by_office).and_return([33, 33])
      @contribution.narrow_memberships_by_office(@memberships, 'Prime Minister').should == [33]
    end

  end

  describe ' when narrowing memberships by previous speakers' do

   before do
     @contribution = Contribution.new
     @memberships = [22, 33, 44]
     @members_in_sitting = [33, 22]
   end

   it 'should return an empty array if there are no previous speakers' do
     @members_in_sitting = []
     @contribution.narrow_memberships_by_previous_speakers(@memberships, @members_in_sitting).should == []
   end

   it 'should return an intersection of the memberships with the most recent speakers in the section except the last one' do
     @contribution.narrow_memberships_by_previous_speakers(@memberships, @members_in_sitting).should == [33]
   end

  end

  describe ' when setting a membership id' do

    def stubbed_contribution members_in_section=[], offices_in_sitting={}
      contribution = Contribution.new
      contribution.stub!(:members_in_section).and_return members_in_section
      contribution.stub!(:offices_in_sitting).and_return offices_in_sitting
      contribution
    end

    describe ' when passed a list containing one id' do
      it "should add to the list of members in the section" do
        member_list = mock('list')
        member_list.should_receive(:<<).with(1)
        contribution = stubbed_contribution member_list

        contribution.set_membership([1], 'commons')
      end

      it "should add to the hash of office holders in the sitting if the contribution has an office" do
        office_hash = mock('hash')
        office_list = mock('list')
        office_hash.should_receive(:[]).with('office').and_return(office_list)
        office_list.should_receive(:<<).with(1)

        contribution = stubbed_contribution [], office_hash
        contribution.stub!(:office).and_return('office')

        contribution.set_membership([1], 'commons')
      end

      it "should add to the 'chairman' key of the hash of office holders in the sitting if the contribution has an office like 'Chairman of'" do
        office_hash = mock('hash')
        office_list = mock('list')
        chairman_list = mock('list')
        office_hash.should_receive(:[]).with('chairman of something').and_return(office_list)
        office_hash.should_receive(:[]).with('chairman').and_return(chairman_list)
        office_list.stub!(:<<)
        chairman_list.should_receive(:<<).with(1)

        contribution = stubbed_contribution [], office_hash
        contribution.stub!(:office).and_return('Chairman of Something')

        contribution.set_membership([1], 'commons')
      end

      it "should set the commons membership id" do
        contribution = stubbed_contribution
        contribution.should_receive(:commons_membership_id=).with(1)
        contribution.set_membership([1], 'commons')
      end

      it "should return true" do
        stubbed_contribution.set_membership([1], 'commons').should be_true
      end
      
    end

    describe ' when passed a list containing more than one id' do
      it "should not add to the list of members in the section" do
        member_list = mock('list')
        member_list.should_not_receive(:<<)
        contribution = stubbed_contribution member_list
        contribution.set_membership([1, 2], 'commons')
      end

      it "should not add to the hash of office holders in the sitting if the contribution has an office" do
        office_hash = mock('hash')
        office_hash.should_not_receive(:[]).with('office')
        contribution = stubbed_contribution [], office_hash
        contribution.stub!(:office).and_return('office')
        contribution.set_membership([1, 2], 'commons')
      end

      it "should not set the commons membership id" do
        contribution = stubbed_contribution
        contribution.should_not_receive(:commons_membership_id=).with(1)
        contribution.set_membership([1, 2], 'commons')
      end

      it 'should return false' do
        stubbed_contribution.set_membership([1, 2], 'commons').should be_false
      end
      
    end
  end

  describe ' when getting a person name' do

    it 'should return a name that has erroneously been put in the constituency' do
      contribution = Contribution.new(:member_name => 'Prime Minister',
                                      :constituency_name => 'Joe Member')
      contribution.person_name.should == 'Joe Member'
    end

    it 'should otherwise return the member name' do
      contribution = Contribution.new(:member_name => 'Joe Member')
      contribution.person_name.should == 'Joe Member'
    end

    it 'should extract an office part of the member name and set the contribution\'s office' do
      contribution = Contribution.new(:member_name => 'The Official (Joe Member)')
      Contribution.should_receive(:office_and_name).with('The Official (Joe Member)').and_return(['Official', 'Joe Member'])
      contribution.person_name.should == 'Joe Member'
      contribution.office.should == 'Official'
    end

  end

  describe 'when obtaining preceding contribution' do
    it 'should return preceding contribution from section' do
      preceeding = mock('contribution')
      contribution = Contribution.new
      section = mock('section')
      section.should_receive(:preceding_contribution).with(contribution).and_return preceeding
      contribution.should_receive(:section).and_return section
      contribution.preceding_contribution.should == preceeding
    end

    it 'should return nil if there is no preceeding contribution in section' do
      contribution = Contribution.new
      section = mock('section')
      section.should_receive(:preceding_contribution).with(contribution).and_return nil
      contribution.should_receive(:section).and_return section
      contribution.preceding_contribution.should be_nil
    end
  end

  describe 'when obtaining following contribution' do
    it 'should return following contribution from section' do
      following = mock('contribution')
      contribution = Contribution.new
      section = mock('section')
      section.should_receive(:following_contribution).with(contribution).and_return following
      contribution.should_receive(:section).and_return section
      contribution.following_contribution.should == following
    end

    it 'should return nil if there is no following contribution in section' do
      contribution = Contribution.new
      section = mock('section')
      section.should_receive(:following_contribution).with(contribution).and_return nil
      contribution.should_receive(:section).and_return section
      contribution.following_contribution.should be_nil
    end
  end

  describe 'when obtaining plain text' do
    it 'should removed element tags' do
      contribution = Contribution.new :text => '<i>The House divided:</i>Ayes 274, Noes 162.'
      contribution.plain_text.should == 'The House divided: Ayes 274, Noes 162.'
    end
  end
end
