require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::LordsMembershipParser do 

  before do 
    @parser = Hansard::LordsMembershipParser.new 'test/path'
  end
  
  describe 'when parsing' do 
  
    it 'should parse the memberships' do 
      @parser.should_receive(:parse_memberships).and_return([])
      @parser.parse
    end
    
    it 'should ask for the memberships by person' do 
      @parser.stub!(:parse_memberships).and_return([])
      @parser.should_receive(:memberships_by_person).with([]).and_return({})
      @parser.parse
    end
    
    it 'should save the membership data' do 
      @parser.stub!(:parse_memberships).and_return([])
      @parser.stub!(:memberships_by_person).with([]).and_return({1 => ['membership', 'membership']})  
      @parser.should_receive(:save_data).with(['membership', 'membership'])
      @parser.parse
    end
    
  end
  
  describe 'when saving data for a list of memberships belonging to a person' do 
    
    before do 
      @parser.stub!(:save_person)
      @parser.stub!(:save_membership)
      @memberships = [{:first => true}, {:second => true}]
    end
    
    it 'should try and match the person to an existing person' do 
      @parser.should_receive(:match_person).with({:first => true})
      @parser.save_data(@memberships)
    end
    
    it 'should save each membership if the person does not already have lords memberships' do 
      person = mock_model(Person, :lords_memberships => [])
      @parser.stub!(:match_person).and_return(person)
      @parser.should_receive(:save_membership).with(@memberships.first, person)
      @parser.save_data(@memberships)
    end
    
    it 'should not save the memberships if the person already has lords memberships' do 
      person = mock_model(Person, :lords_memberships => ['membership'])
      @parser.stub!(:match_person).and_return(person)
      @parser.should_not_receive(:save_membership).with(@memberships.first, person)
      @parser.save_data(@memberships)
    end
    
    describe 'if the person cannot be matched' do 
      
      before do 
        @parser.stub!(:match_person).and_return(nil)
      end
      
      it 'should save the person info to a file' do 
        @parser.should_receive(:save_person).with(@memberships.first)
        @parser.save_data(@memberships)
      end
      
      it 'should create a new person model with the import id of the newly saved person info' do
        @parser.stub!(:save_person).and_return(1)
        Person.should_receive(:new).with(:import_id => 1).and_return(mock_model(Person, :lords_memberships => [])) 
        @parser.save_data(@memberships)
      end
      
    end
    
  end
  
  describe 'when getting memberships by person' do 
  
    it 'should create a hash of lists containing unique memberships, keyed on import id' do 
      memberships = [{:import_id => 1, :a => 'a', :b => 'b'}, 
                     {:import_id => 1, :a => 'a', :b => 'b'},
                     {:import_id => 1, :a => 'b', :b => 'b'},
                     {:import_id => 2, :a => 'a', :b => 'b'} ]
      memberships_by_person = {1 => [{:import_id => 1, :a => 'a', :b => 'b'}, 
                                     {:import_id => 1, :a => 'b', :b => 'b'}],
                               2 => [{:import_id => 2, :a => 'a', :b => 'b'}]}
      @parser.memberships_by_person(memberships).should == memberships_by_person
    end
    
  end
  
  describe 'when parsing membership lines from a file' do 

    before do 
      @fake_file = ['first line', 'line']
      File.stub!(:read).and_return(@fake_file)
      @attributes = {:start_date => Date.new(1975, 1, 1),
                     :end_date   => Date.new(2001, 1, 1), 
                     :firstname             => 'First', 
                     :lastname              => 'Last', 
                     :title                 => 'Baron Westmoreland', 
                     :date_of_birth         => Date.new(1921, 1, 1)}
      @parser.stub!(:parse_membership_line).with('line').and_return(@attributes)
      @mock_iconv = mock('iconv')
      Iconv.stub!(:new).with('US-ASCII//TRANSLIT', 'UTF-16').and_return(@mock_iconv)
      @mock_iconv.stub!(:iconv).with(@fake_file).and_return(@fake_file)
    end
    
    it 'should convert the file from UTF-16' do 
      @mock_iconv = mock('iconv')
      Iconv.should_receive(:new).with('US-ASCII//TRANSLIT', 'UTF-16').and_return(@mock_iconv)
      @mock_iconv.should_receive(:iconv).with(@fake_file).and_return(@fake_file)
      @parser.parse_memberships
    end
  
    it 'should not parse the first line of the file' do 
      @parser.should_not_receive(:parse_membership_line).with('first line')
      @parser.parse_memberships
    end
    
    it 'should not return a membership whose start date is after its end date' do 
      @attributes[:start_date] = @attributes[:end_date] + 1
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership whose start date is after the date hereditary peerages were abolished and whose type is hereditary' do 
      @attributes[:start_date] = @parser.hereditary_peers_abolition_date + 1
      @attributes[:peerage_type] = 'Hereditary'
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership whose start date is after the last date covered by the application' do
      @attributes[:start_date] = LAST_DATE + 1
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership that does not have a start date' do 
      @attributes[:start_date] = nil
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership that does not have a date of birth' do 
      @attributes[:date_of_birth] = nil
      @parser.parse_memberships.should == []      
    end
    
    it 'should not return a membership whose firstname is blank' do 
      @attributes[:firstname] = ''
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership whose lastname is blank' do 
      @attributes[:lastname] = ''
      @parser.parse_memberships.should == []
    end
      
    it 'should not return a membership whose title is blank' do 
      @attributes[:title] = ''
      @parser.parse_memberships.should == []
    end
    
    it 'should parse the degree and title from a title string' do 
      @parser.should_receive(:degree_and_title).with(@attributes[:title])
      @parser.parse_memberships
    end
    
    it 'should not return a membership whose parsed degree is blank' do 
      @parser.stub!(:degree_and_title).and_return(['Baron', ''])
      @parser.parse_memberships.should == []
    end
    
    it 'should not return a membership whose parsed title is blank' do 
      @parser.stub!(:degree_and_title).and_return(['', 'Westmoreland'])
      @parser.parse_memberships.should == []
    end
    
    it 'should return a membership that has firstname, lastname, degree, title, start date, end date and date of birth' do 
      @parser.parse_memberships.should == [@attributes]
    end
    
  end
  
  describe 'when asked to parse a membership line' do 
  
    before do 
      @line = '"3842","Maitland","Ian","","Earl of Lauderdale The","Male","1937-11-04 00:00:00","","","1999-11-11 00:00:00","2008-12-02 00:00:00","1999-11-11 00:00:00","Hereditary","","","","1937-11-04 00:00:00"'
      @attributes = {:import_id => 3842, 
                    :lastname  => "Maitland", 
                    :firstname => 'Ian',
                    :firstnames => '', 
                    :title => 'Earl of Lauderdale The', 
                    :gender => 'Male',
                    :date_of_birth => Date.new(1937, 11, 4), 
                    :date_of_death => nil,
                    :retired_date => Date.new(1999, 11, 11),
                    :start_date => Date.new(2008, 12, 2), 
                    :end_date => Date.new(1999, 11, 11), 
                    :peerage_type => 'Hereditary'
                    }
    end
    
    it 'should return a hash of attributes' do
      @parser.parse_membership_line(@line).should == @attributes
    end
    
    it 'should remove bracketed suffixes from lastnames' do 
      line = '"3842","Maitland (one t)","Ian","","Earl of Lauderdale The","Male","1937-11-04 00:00:00","","","1999-11-11 00:00:00","2008-12-02 00:00:00","1999-11-11 00:00:00","Hereditary","","","","1937-11-04 00:00:00"'
      @parser.parse_membership_line(line).should == @attributes
    end
    
  end
  
  describe 'when asked to save a person' do 
    
    before do 
      @person = {:firstname => 'First', 
                 :lastname  => 'Last', 
                 :firstnames => 'Other', 
                 :date_of_birth => Date.new(1901, 1, 2), 
                 :date_of_death => Date.new(1986, 3, 21)}
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
    end
  
    it 'should ask for the last people id' do 
      @parser.should_receive(:last_people_id).and_return(3)
      @parser.save_person(@person)
    end
    
    it 'should write a line correctly to the file' do 
      @parser.stub!(:last_people_id).and_return(3)
      @fake_file.should_receive(:write).with("4\tOther\tFirst\tLast\tMr\t1901\t1901-01-02\tTRUE\t1986\t1986-03-21\tTRUE\n")
      @parser.save_person(@person)
    end
    
    it 'should set the honorific to "Ms" for a female person' do 
      @person[:gender] = 'Female'
      @parser.stub!(:last_people_id).and_return(3)
      @fake_file.should_receive(:write).with("4\tOther\tFirst\tLast\tMs\t1901\t1901-01-02\tTRUE\t1986\t1986-03-21\tTRUE\n")
      @parser.save_person(@person)
    end
  
  end
  
  describe 'when asked to save a membership' do 
    
    before do 
      @membership = {:start_date => Date.new(2004, 10, 21), 
                     :end_date => Date.new(2006, 7, 13), 
                     :degree => 'Baron', 
                     :title => 'Westminster', 
                     :peerage_type => 'Hereditary'}
      @person = mock_model(Person, :import_id => 8)
      @parser.stub!(:last_lords_membership_id).and_return(5)
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @parser.stub!(:open).and_yield(@fake_file)
    end
    
    it 'should ask for the last lords membership id' do 
      @parser.should_receive(:last_lords_membership_id).and_return(4)
      @parser.save_membership(@membership, @person)
    end
    
    it 'should append a line to the file' do 
      @parser.save_membership(@membership, @person)
      @string.should == "existing content\n6\t8\t\tBaron\tWestminster\t\tHereditary\t2004\t2004-10-21\t2006\t2006-07-13\n"
    end
    
    it 'should set the end date to the earliest of the retired date and the end date' do 
      @membership[:retired_date] = Date.new(1999,11,11)
      @parser.save_membership(@membership, @person)
      @string.should == "existing content\n6\t8\t\tBaron\tWestminster\t\tHereditary\t2004\t2004-10-21\t1999\t1999-11-11\n"      
    end
    
  end
  
  describe 'when getting a degree and title from a title string' do 
  
    it 'should get ["Lord", " Watson of Invergowrie"] from "The Lord Watson of Invergowrie"' do 
      @parser.degree_and_title("The Lord Watson of Invergowrie").should == ["Lord", "Watson of Invergowrie"]
    end
    
    it 'should get ["Lord", "Chan"] from "The Lord Chan MBE"' do 
      @parser.degree_and_title("The Lord Chan MBE").should == ["Lord", "Chan"]
    end
    
    it 'should get ["Earl of", "Stair"] from "The Rt Hon. the Earl of Stair"' do 
      @parser.degree_and_title("The Rt Hon. the Earl of Stair").should == ["Earl of", "Stair"] 
    end
    
    it 'should get ["Lord", "Inglewood"] from "The Lord Inglewood MEP ARICS DL"' do 
      @parser.degree_and_title("The Lord Inglewood MEP ARICS DL").should == ["Lord", "Inglewood"]
    end
    
    it 'should get ["Lord Bishop of", "St Edmundsbury and Ipswich"] from "The Rt Revd. the Lord Bishop of St Edmundsbury and Ipswich"' do 
      @parser.degree_and_title("The Rt Revd. the Lord Bishop of St Edmundsbury and Ipswich").should == ["Lord Bishop of", "St Edmundsbury and Ipswich"]
    end
    
    it 'should get ["Lord Bishop of", "Exeter"] from "The Rt Rev. the Lord Bishop of Exeter"' do 
      @parser.degree_and_title("The Rt Rev. the Lord Bishop of Exeter").should == ["Lord Bishop of", "Exeter"] 
    end
    
    it 'should get ["Earl of", "Iveagh"] from "The Rt Hon. Earl of Iveagh"' do 
      @parser.degree_and_title("The Rt Hon. Earl of Iveagh").should == ["Earl of", "Iveagh"]
    end
    
    it 'should get ["Duke of", "Wellington"] from "His Grace the Duke of Wellington KG LVO OBE MC DL"' do 
      @parser.degree_and_title("His Grace the Duke of Wellington KG LVO OBE MC DL").should == ["Duke of", "Wellington"]
    end
    
    it 'should get ["Viscount of", "Oxfuird"] from "The Rt Hon. Viscount of Oxfuird"' do 
      @parser.degree_and_title("The Rt Hon. Viscount of Oxfuird").should == ["Viscount of", "Oxfuird"]
    end
    
    it 'should get ["Marquess of", "Waterford"] from "The Most Hon. the Marquess of Waterford"' do
      @parser.degree_and_title("The Most Hon. the Marquess of Waterford").should == ["Marquess of", "Waterford"]
    end
    
    it 'should get ["Lord Archbishop of", "York"] from "The Most Revd. and Rt Hon. the Lord Archbishop of York"' do
      @parser.degree_and_title("The Most Revd. and Rt Hon. the Lord Archbishop of York").should == ["Lord Archbishop of", "York"] 
    end
    
    it 'should get ["Lord", "Caccia"] from "The. Lord Caccia"' do 
      @parser.degree_and_title("The. Lord Caccia").should == ["Lord", "Caccia"]
    end
    
    it 'should get ["Lord Archbishop of", "York"] from "The Most Rev. and The Rt Hon. the Lord Archbishop of York"' do 
      @parser.degree_and_title("The Most Rev. and The Rt Hon. the Lord Archbishop of York").should == ["Lord Archbishop of", "York"]
    end
    
    it 'should get ["Lord", "Stourton"] from "The the Lord Stourton CBE"' do 
      @parser.degree_and_title("The the Lord Stourton CBE").should == ["Lord", "Stourton"] 
    end
    
    it 'should get ["Lord", "Black of Crossharbour"] from "The Lord Black of Crossharbour PC (Can.) OC"' do 
      @parser.degree_and_title("The Lord Black of Crossharbour PC (Can.) OC").should == ["Lord", "Black of Crossharbour"]
    end
    
    it 'should get ["Prince of", "Wales"] from "His Royal Highness the Prince of Wales KG KT GCB PC"' do 
      @parser.degree_and_title("His Royal Highness the Prince of Wales KG KT GCB PC").should == ["Prince of", "Wales"]
    end
    
    it 'should get ["Lord Bishop of", "Truro"] from "The Rt  Rev. the Lord Bishop of Truro"' do 
      @parser.degree_and_title("The Rt  Rev. the Lord Bishop of Truro").should == ["Lord Bishop of", "Truro"]
    end
    
    it 'should get ["Duke of", "Devonshire"] from "His Grace the Rt Hon. the Duke of Devonshire KG PC MC"' do 
      @parser.degree_and_title("His Grace the Rt Hon. the Duke of Devonshire KG PC MC").should == ["Duke of", "Devonshire"]
    end
    
    it 'should get ["Earl of", "Wessex"] from "HRH The Prince Edward, Earl of Wessex CVO"' do 
      @parser.degree_and_title("HRH The Prince Edward, Earl of Wessex CVO").should == ["Earl of", "Wessex"]
    end
    
    it 'should get ["The Rt Hon. Kalms GCB, KCVO"] from "The Rt Hon. Kalms GCB, KCVO"' do 
      @parser.degree_and_title("The Rt Hon. Kalms GCB, KCVO").should == [nil, "Kalms"]
    end
    
    it 'should get ["The Rt. Hon Kalms, L. GCB, GCVO"] from "The Rt. Hon Kalms, L. GCB, GCVO"' do 
      @parser.degree_and_title("The Rt. Hon Kalms, L. GCB, GCVO").should == [nil, "Kalms, L."]
    end
    
    it 'should get ["Lord Bishop of", "Southwell and Nottingham"] from "The Rt Revd the Lord Bishop of Southwell and Nottingham"' do 
      @parser.degree_and_title("The Rt Revd the Lord Bishop of Southwell and Nottingham").should == ["Lord Bishop of", "Southwell and Nottingham"]
    end
    
    it 'should get ["Lord", "Drayson"] from "The Rt. Hon. the Lord Drayson"' do 
      @parser.degree_and_title("The Rt. Hon. the Lord Drayson").should == ["Lord", "Drayson"]
    end
    
    it 'should get ["Baroness", "Royall of Blaisdon"] from "The Rt. Hon. the Baroness Royall of Blaisdon"' do 
      @parser.degree_and_title("The Rt. Hon. the Baroness Royall of Blaisdon").should == ["Baroness", "Royall of Blaisdon"] 
    end
    
    it 'should get ["Duke of", "Sutherland"] from "His Grace Duke of Sutherland TD DL"' do 
      @parser.degree_and_title("His Grace Duke of Sutherland TD DL").should == ["Duke of", "Sutherland"] 
    end    
    
    it 'should get ["Earl of", "Snowdon"] from "The Earl of SnowdonH1 GCVO"' do 
      @parser.degree_and_title("The Earl of SnowdonH1 GCVO").should == ["Earl of", "Snowdon"]
    end
    
    it 'should get ["Lord", "Carrington"] from "Lord CarringtonH"' do 
      @parser.degree_and_title("Lord CarringtonH").should == ["Lord", "Carrington"] 
    end
    
    it 'should get ["Lord", "Pilkington of Oxenford"] from "The Rev. Canon the Lord Pilkington of Oxenford "' do 
      @parser.degree_and_title("The Rev. Canon the Lord Pilkington of Oxenford ").should == ["Lord", "Pilkington of Oxenford"]
    end
    
    it 'should get ["Baroness", "Richardson of Calow"] from "The Rev. the Baroness Richardson of Calow OBE"' do 
      @parser.degree_and_title("The Rev. the Baroness Richardson of Calow OBE").should == ["Baroness", "Richardson of Calow"]
    end
    
    it 'should get ["Lord", "Manton"] from "Major the Hon. The Lord Manton "' do 
      @parser.degree_and_title("Major the Hon. The Lord Manton ").should == ["Lord", "Manton"]
    end
  
    it 'should get ["Earl", "Cathcart"] from "Major-General Earl Cathcart CB DSO MC"' do 
      @parser.degree_and_title("Major-General Earl Cathcart CB DSO MC").should == ["Earl", "Cathcart"]
    end
 
    it 'should get ["Lord", "Desai"] from "Professor the Lord Desai "' do 
      @parser.degree_and_title("Professor the Lord Desai ").should == ["Lord", "Desai"] 
    end
 
    it 'should get ["Lord", "Guthrie of Craigiebank"] from "General the Lord Guthrie of Craigiebank "' do 
      @parser.degree_and_title("General the Lord Guthrie of Craigiebank").should == ["Lord", "Guthrie of Craigiebank"]
    end
    
    it 'should get ["Lord", "Hill-Norton"] from "The Admiral of the Fleet The Lord Hill-Norton"' do 
      @parser.degree_and_title("The Admiral of the Fleet The Lord Hill-Norton").should == ["Lord", "Hill-Norton"] 
    end
      
  end
  
end