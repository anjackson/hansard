require File.dirname(__FILE__) + '/../spec_helper'

describe Office do

  describe 'find_or_create_from_name' do
    before do
      Office.delete_all
    end

    after do
      Office.delete_all
    end

    def should_correct_name name, corrected_name
      Office.corrected_name(name).should == corrected_name
    end

    it 'should match " ST ATE" to " STATE"' do
      should_correct_name 'THE LORD PRIVY SEAL AND SECRETARY OF ST ATE FOR THE COLONIES', 'LORD PRIVY SEAL AND SECRETARY OF STATE FOR THE COLONIES'
    end

    it 'should match "The SOLICITOR - GENERAL" to "SOLICITOR-GENERAL"' do
      should_correct_name "The SOLICITOR - GENERAL", "SOLICITOR-GENERAL"
    end

    it 'should match "The SOLICITOR - GENERAL" to "SOLICITOR-GENERAL"' do
      should_correct_name "The SOLICITOR - GENERAL", "SOLICITOR-GENERAL"
    end

    it 'should match "THE CHANCELLOR or THE EXCHEQUER" to "CHANCELLOR or THE EXCHEQUER"' do
      should_correct_name "THE CHANCELLOR or THE EXCHEQUER", "CHANCELLOR OF THE EXCHEQUER"
    end

    it 'should match "THE CHAIRMAN OF COMMITTEES." to "CHAIRMAN OF COMMITTEES"' do
      should_correct_name "THE CHAIRMAN OF COMMITTEES.", "CHAIRMAN OF COMMITTEES"
    end

    it 'should match "The Deputy. Prime Minister" to "Deputy Prime Minister"' do
      should_correct_name "The Deputy. Prime Minister", "Deputy Prime Minister"
    end

    it 'should match "The Lord President of the Council:" to "Lord President of the Council"' do
      should_correct_name "The Lord President of the Council:", "Lord President of the Council"
    end

    it 'should match "THE PARLIAMENTARY SECRETAR OF THE MINISTRY OF AGRICULTURE AND FISHERIES" to "PARLIAMENTARY SECRETARY OF THE MINISTRY OF AGRICULTURE AND FISHERIES"' do
      should_correct_name "THE PARLIAMENTARY SECRETAR OF THE MINISTRY OF AGRICULTURE AND FISHERIES", "PARLIAMENTARY SECRETARY OF THE MINISTRY OF AGRICULTURE AND FISHERIES"
    end

    it 'should match "THE SOLICITOR GENERAL FOR IRELA.ND" to "SOLICITOR-GENERAL FOR IRELAND"' do
      should_correct_name "THE SOLICITOR GENERAL FOR IRELA.ND", "SOLICITOR-GENERAL FOR IRELAND"
    end

    it 'should match "THE SOLICITOR GENERAL FOB IRELAND" to "SOLICITOR-GENERAL FOR IRELAND"' do
      should_correct_name "THE SOLICITOR GENERAL FOB IRELAND", "SOLICITOR-GENERAL FOR IRELAND"
    end

    it 'should match "THE SOLICITOR GENEEAL FOR IRELAND" to "SOLICITOR-GENERAL FOR IRELAND"' do
      should_correct_name "THE SOLICITOR GENEEAL FOR IRELAND", "SOLICITOR-GENERAL FOR IRELAND"
    end

    it 'should match "A LORD OF THE TERASUEY" to "LORD OF THE TREASURY"' do
      should_correct_name "A LORD OF THE TERASUEY", "LORD OF THE TREASURY"
    end

    it 'should match "A LORD OE THE TREASURY" to "LORD OF THE TREASURY"' do
      should_correct_name "A LORD OE THE TREASURY", "LORD OF THE TREASURY"
    end

    it 'should match "THE CHANCELLOE OF THE EXCHEQUER" to "CHANCELLOR OF THE EXCHEQUER"' do
      should_correct_name "THE CHANCELLOE OF THE EXCHEQUER", "CHANCELLOR OF THE EXCHEQUER"
    end

    it 'should match "THE FIEST LORD OF THE ADMIRALTY" to "FIRST LORD OF THE ADMIRALTY"' do
      should_correct_name "THE FIEST LORD OF THE ADMIRALTY", "FIRST LORD OF THE ADMIRALTY"
    end

    it 'should match "ATTORNEY GENERAL" to "ATTORNEY-GENERAL"' do
      should_correct_name "ATTORNEY GENERAL", "ATTORNEY-GENERAL"
    end

    it 'should match "Mr. Deputy Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Speaker", "Deputy Speaker"
    end

    it 'should match "The UNDEE SECRETAEY of STATE foe the COLONIES" to "UNDER-SECRETARY of STATE foe the COLONIES"' do
      should_correct_name "The UNDEE SECRETAEY of STATE foe the COLONIES", "UNDER-SECRETARY of STATE foe the COLONIES"
    end

    it 'should match "THE UNDEE SECRETARY OF STATE FOR INDIA" to "UNDER-SECRETARY OF STATE FOR INDIA"' do
      should_correct_name "THE UNDEE SECRETARY OF STATE FOR INDIA", "UNDER-SECRETARY OF STATE FOR INDIA"
    end

    it 'should match "Mr. Deputh Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputh Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deput3 Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deput3 Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputh Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputh Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Spt aker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Spt aker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Speeket" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Speeket", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Speake" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Speake", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Speakcr" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Speakcr", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Speak" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Speak", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Spe iker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Spe iker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Spe aker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Spe aker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Spaeker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Spaeker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy Sneaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy Sneaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy \'Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy 'Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. DeputySpeaker" to "Deputy Speaker"' do
      should_correct_name "Mr. DeputySpeaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deupty Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deupty Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy, Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy, Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deputy&#x00B7;Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deputy&#x00B7;Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Deptuy Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Deptuy Speaker", "Deputy Speaker"
    end

    it 'should match "Mr. Depury Speaker" to "Deputy Speaker"' do
      should_correct_name "Mr. Depury Speaker", "Deputy Speaker"
    end

    it 'should match "The]\'rime Minister" to "Prime Minister"' do
      should_correct_name "The]\'rime Minister", "Prime Minister"
    end

    it 'should match "E MINISTER WITHOUT PORTFOLIO" to "MINISTER WITHOUT PORTFOLIO"' do
      should_correct_name 'E MINISTER WITHOUT PORTFOLIO', 'MINISTER WITHOUT PORTFOLIO'
    end

    it 'should match "HE MINISTER WITHOUT PORTFOLIO" to "MINISTER WITHOUT PORTFOLIO"' do
      should_correct_name 'HE MINISTER WITHOUT PORTFOLIO', 'MINISTER WITHOUT PORTFOLIO'
    end

    it 'should match "Hhe Miniser of State, Home Office" to "Minister of State, Home Office"' do
      should_correct_name 'Hhe Miniser of State, Home Office', 'Minister of State, Home Office'
    end

    it 'should match "THE LORDCHANCELLOR" to "LORD CHANCELLOR"' do
      should_correct_name 'THE LORDCHANCELLOR', 'LORD CHANCELLOR'
    end

    it 'should match "THE LORD PRIVY, SEAL" to "LORD PRIVY SEAL"' do
      should_correct_name 'THE LORD PRIVY, SEAL', 'LORD PRIVY SEAL'
    end

    it 'should match "TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER" to "CHANCELLOR OF THE DUCHY OF LANCASTER"' do
      should_correct_name 'TIFF, CHANCELLOR OF THE DUCHY OF LANCASTER', 'CHANCELLOR OF THE DUCHY OF LANCASTER'
    end

    it 'should match "Th Prime Minister" to "Prime Minister"' do
      should_correct_name 'Th Prime Minister', 'Prime Minister'
    end

    it 'should match "The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs" to "Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs"' do
      should_correct_name 'The. Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs', 'Parliamentary Under-Secretary of State for Environment, Food and Rural Affairs'
    end

    it 'should match "Tun MINISTER OF STATE, BOARD OF TRADE" to "MINISTER OF STATE, BOARD OF TRADE"' do
      should_correct_name 'Tun MINISTER OF STATE, BOARD OF TRADE', 'MINISTER OF STATE, BOARD OF TRADE'
    end

    it 'should match "Tint LORD CHANCELLOR" to "LORD CHANCELLOR"' do
      should_correct_name 'Tint LORD CHANCELLOR', 'LORD CHANCELLOR'
    end

    it 'should match "Tine Temporary Chairman" to "Temporary Chairman"' do
      should_correct_name 'Tine Temporary Chairman', 'Temporary Chairman'
    end

    it 'should match "Tine Minister of State, Privy Council Office" to "Minister of State, Privy Council Office"' do
      should_correct_name 'Tine Minister of State, Privy Council Office', 'Minister of State, Privy Council Office'
    end

    it 'should match "Tim MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE" to "MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE"' do
      should_correct_name 'Tim MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE', 'MINISTER of STATE, FOREIGN AND COMMONWEALTH OFFICE'
    end

    it 'should match "Thr Parliamentary Under-Secretary of State for Social Security" to "Parliamentary Under-Secretary of State for Social Security"' do
      should_correct_name 'Thr Parliamentary Under-Secretary of State for Social Security', 'Parliamentary Under-Secretary of State for Social Security'
    end

    it 'should match "The: Lord CHANCELLOR" to "Lord CHANCELLOR"' do
      should_correct_name 'The: Lord CHANCELLOR', 'Lord CHANCELLOR'
    end

    it 'should match "The, Solicitor-General" to "Solicitor-General"' do
      should_correct_name 'The, Solicitor-General', 'Solicitor-General'
    end

    it 'should match "Tin LORD CHANCELLOR" to "LORD CHANCELLOR"' do
      should_correct_name 'Tin LORD CHANCELLOR', 'LORD CHANCELLOR'
    end

    it 'should match "The Lord. Privy Seal" to "Lord Privy Seal"' do
      should_correct_name 'The Lord. Privy Seal', 'LORD PRIVY SEAL'
    end

    it 'should match "The Solicitor?General" to "Solicitor-General"' do
      should_correct_name 'The Solicitor?General', 'Solicitor-General'
    end

    it 'should match "Solicitor General" to "Solicitor-General"' do
      should_correct_name 'Solicitor General', 'Solicitor-General'
    end

    it 'should match "The Solicitor General" to "Solicitor-General"' do
      should_correct_name 'The Solicitor General', 'Solicitor-General'
    end

    it 'should match "Solicitor-General" to "Solicitor-General"' do
      should_correct_name 'Solicitor-General', 'Solicitor-General'
    end

    it 'should match "THE FIRST LORE) OF THE AD-MIRALTY" to "FIRST LORD OF THE ADMIRALTY"' do
      should_correct_name 'THE FIRST LORE) OF THE AD-MIRALTY', 'FIRST LORD OF THE ADMIRALTY'
    end

    it 'should match "THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES" to "LORD PRIVY SEAL AND SECRETARY OF STATE FOR THE COLONIES"' do
      should_correct_name 'THE LORD PEIVY SEAL AND SECRETARY OF STATE FOB THE COLONIES', 'LORD PRIVY SEAL AND SECRETARY OF STATE FOR THE COLONIES'
    end

    it 'should match "The. Parliamentary Under-Secretary of State for Scotland" to "Parliamentary Under-Secretary of State for Scotland"' do
      should_correct_name 'The. Parliamentary Under-Secretary of State for Scotland', 'Parliamentary Under-Secretary of State for Scotland'
    end

    it 'should match "THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT" to "JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT"' do
      should_correct_name "THE JOINT PARLIAMENTARY SECRETARY, [MINISTRY OF TRANSPORT", "JOINT PARLIAMENTARY SECRETARY, MINISTRY OF TRANSPORT"
    end

    it 'should match "The Parliamentary Under&#x2013;Secretary of State for Health" to "Parliamentary Under-Secretary of State for Health"' do
      should_correct_name "The Parliamentary Under&#x2013;Secretary of State for Health", "Parliamentary Under-Secretary of State for Health"
    end

    it 'should match "THE PARLIAMENTARY UNDER SECRETARY OF STATE FOR FOREIGN AFFAIRS" to "PARLIAMENTARY UNDER-SECRETARY OF STATE FOR FOREIGN AFFAIRS"' do
      should_correct_name "THE PARLIAMENTARY UNDER SECRETARY OF STATE FOR FOREIGN AFFAIRS", "PARLIAMENTARY UNDER-SECRETARY OF STATE FOR FOREIGN AFFAIRS"
    end

    it 'should match "The Parliamentary tinder-Secretary of State for Energy" to "Parliamentary Under-Secretary of State for Energy"' do
      should_correct_name "The Parliamentary tinder-Secretary of State for Energy", "Parliamentary Under-Secretary of State for Energy"
    end

    it 'should match "THE PARLIAMENTARY UNDERSECRETARY FOR DEFENCE FOR THE ARMY" to "PARLIAMENTARY UNDERSECRETARY FOR DEFENCE FOR THE ARMY"' do
      should_correct_name "THE PARLIAMENTARY UNDERSECRETARY FOR DEFENCE FOR THE ARMY", "PARLIAMENTARY UNDERSECRETARY FOR DEFENCE FOR THE ARMY"
    end

    it 'should match "THE PARLIAMENTARY UNDERSECREFARY OF STATE FOR THE COLONIES" to "PARLIAMENTARY UNDER-SECRETARY OF STATE FOR THE COLONIES"' do
      should_correct_name "THE PARLIAMENTARY UNDERSECREFARY OF STATE FOR THE COLONIES", "PARLIAMENTARY UNDER-SECRETARY OF STATE FOR THE COLONIES"
    end

    it 'should match "The Parliamentary Under-Secretay of State for the Home Department" to "Parliamentary Under-Secretary of State for the Home Department"' do
      should_correct_name "The Parliamentary Under-Secretay of State for the Home Department", "Parliamentary Under-Secretary of State for the Home Department"
    end

    it 'should match "The Parliamentary Under&#x00B7;Secretary of State, Department of Trade and Industry" to "Parliamentary Under-Secretary of State, Department of Trade and Industry"' do
      should_correct_name "The Parliamentary Under&#x00B7;Secretary of State, Department of Trade and Industry", "Parliamentary Under-Secretary of State, Department of Trade and Industry"
    end

    it 'should match "The Parliamentary Under\"Secretary of State for Social Security" to "Parliamentary Under-Secretary of State for Social Security"' do
      should_correct_name 'The Parliamentary Under"Secretary of State for Social Security', "Parliamentary Under-Secretary of State for Social Security"
    end

    it 'should match "The Secretary of State for the Environment" to "Secretary of State for the Environment"' do
      should_correct_name "The Secretary of State for the Environment", "Secretary of State for the Environment"
    end

    it 'should match "THE SECRETARY OF STATE FOR THE COLONIES" to "SECRETARY OF STATE FOR THE COLONIES"' do
      should_correct_name "THE SECRETARY OF STATE FOR THE COLONIES", "SECRETARY OF STATE FOR THE COLONIES"
    end

    it 'should match "A Lord Commissioner to the Treasury" to "Lord Commissioner to the Treasury"' do
      should_correct_name "A Lord Commissioner to the Treasury", "Lord Commissioner to the Treasury"
    end
  end

  describe "one_holder?" do
    it 'should return false if the office does not exist' do
      Office.one_holder?("fake office").should be_false
    end

    it 'should return true for "Prime Minister"' do
      Office.stub!(:find_from_name).and_return(Office.new(:name => 'Prime Minister'))
      Office.one_holder?("Prime Minister").should be_true
    end
  end

  describe "when asked for people by date" do
    before do
      @holder_one = mock_model(OfficeHolder, :first_possible_date => Date.new(2004, 1, 1), :person => mock_model(Person))
      @holder_two = mock_model(OfficeHolder, :first_possible_date => Date.new(2005, 1, 1), :person => mock_model(Person))
      @no_person_holder = mock_model(OfficeHolder, :first_possible_date => Date.new(2005, 1, 1), :person => nil)
      @office = Office.new
      @office.stub!(:office_holders).and_return([@holder_two, @holder_one, @no_person_holder])
    end

    it 'should return office holders' do
      @office.people_by_date.each{ |office| office.class.should == OfficeHolder }
    end

    it 'should not return office holders with no person' do
      @office.people_by_date.include?(@no_person_holder).should be_false
    end

    it 'should return offices sorted by first possible date' do
      @office.people_by_date.should == [@holder_one, @holder_two]
    end
  end

  describe 'when asked to find all sorted' do
    it 'should return all from database sorted in ascending alphabetical order' do
      office = mock('office')
      Office.should_receive(:find).with(:all, {:order => "name asc"}).and_return [office]
      Office.find_all_sorted.should == [office]
    end
  end

  describe 'when asked to find office' do
    it 'should return office with matching slug' do
      office = mock(Office)
      Office.should_receive(:find_by_slug).with('slug').and_return office
      Office.find_office('slug').should == office
    end
  end
end
