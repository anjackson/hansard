require File.dirname(__FILE__) + '/../spec_helper'

describe BillResolver do 
  
  describe ' when matching bills' do

    def should_extract text, expected_name, expected_number=nil
      resolver = BillResolver.new('')
      resolver.name_and_number(text).should == [expected_name, expected_number]
    end

    def expect_match text
      should_match_bills(text, [text])
    end

    def should_not_match text
     should_match_bills(text, [])
    end

    def should_match_bills text, reference_list
      resolver = BillResolver.new(text)
      reference_list = [reference_list] if reference_list.is_a? String
      resolver.references.size.should == reference_list.size
      resolver.references.should == reference_list
    end
  
    it 'should not hang on long piece of caps text' do 
      text = 'ESTIMATED NUMBERS OF EMPLOYEES IN MANUFACTURING INDUSTRIES ORDERS III-XVI OF THE STANDARD INDUSTRIAL CLASSIFICATION AND IN SERVICE INDUSTRIES (ORDERS XIX-XXIV) EXPRESSED AS PERCENTAGES OF EMPLOYEES IN ALL INDUSTRIES AND SERVICES IN COUNTIES OF WALES AT'
      start_time = Time.now
      resolver = BillResolver.new(text)
      resolver.references
      end_time = Time.now
      elapsed = end_time - start_time
      elapsed.should < 30
    end
  
    it "should match 'Newcastle-upon-Tyne Corporation (Trolley Vehicles) Provisional Order Bill'" do
     expect_match("Newcastle-upon-Tyne Corporation (Trolley Vehicles) Provisional Order Bill")
    end
  
     it "should match 'Consolidated Fund (Appropriation) Bill'" do
      expect_match("Consolidated Fund (Appropriation) Bill")
     end

    it 'should extract "SUPERANNUATION BILL. (No. 385.)"' do
      should_extract "SUPERANNUATION BILL. (No. 385.)", "SUPERANNUATION BILL", '385'
    end

    it 'should extract "COUNTY COURTS BILL. [H.L]"' do
      should_extract "COUNTY COURTS BILL. [H.L]", "COUNTY COURTS BILL. [H.L.]"
    end

    it 'should extract "HOUSE LETTING AND RATING (SCOTLAND) BILL"' do
      should_extract 'HOUSE LETTING AND RATING (SCOTLAND) BILL', 'HOUSE LETTING AND RATING (SCOTLAND) BILL'
    end

    it 'should extract "HOUSING, TOWN PLANNING, &c. BILL"' do
      should_extract 'HOUSING, TOWN PLANNING, &c. BILL', 'HOUSING, TOWN PLANNING, &c. BILL'
    end

    it "should match 'SUPERANNUATION BILL. (No. 385.)' " do
     expect_match("SUPERANNUATION BILL. (No. 385.)")
    end

    it 'should match "LIQUOR TRAFFIC LOCAL VETO (SCOTLAND) BILL. (No. 98.)"' do
      expect_match("LIQUOR TRAFFIC LOCAL VETO (SCOTLAND) BILL. (No. 98.)")
    end

    it 'should extract "DOGS (AMENDMENT) BILL."' do
      expect_match("DOGS (AMENDMENT) BILL")
    end

    it 'should extract "Hampshire Bill [H.L.]"' do
      expect_match("Hampshire Bill [H.L.]")
    end

    it 'should extract "REGENT\'S CANAL AND DOCK COM PANY (WARWICK CANALS PUR CHASE) BILL."' do
      expect_match("REGENT'S CANAL AND DOCK COM PANY (WARWICK CANALS PUR CHASE) BILL")
    end

    it 'should extract "Water Bill" from "Second Reading of the Water Bill."' do
      should_match_bills("Second Reading of the Water Bill.", "Water Bill")
    end

    it 'should extract "IMMIGRATION APPEALS BILL"' do
      expect_match("IMMIGRATION APPEALS BILL")
    end

    it 'should extract "PARLIAMENTARY ELECTIONS (REDISTRIBUTION) (re-committed) BILL.&#x2014;[BILL.49.]"' do
      expect_match("PARLIAMENTARY ELECTIONS (REDISTRIBUTION) (re-committed) BILL.&#x2014;[BILL.49.]")
    end

    it 'should extract "University of Wales, Cardiff Bill [HL]"' do
      expect_match("University of Wales, Cardiff Bill [HL]")
    end

    it 'should extract "GAS PROVISIONAL ORDERS (NO. 1) BILL."' do
      expect_match("GAS PROVISIONAL ORDERS (NO. 1) BILL")
    end

    it 'should extract "GAS PROVISIONAL ORDERS (NO. 1) BILL."' do
      should_extract "GAS PROVISIONAL ORDERS (NO. 1) BILL", "GAS PROVISIONAL ORDERS BILL", '1'
    end

    it 'should extract "LOCAL GOVERNMENT, &C. (NO. 7) BILL."' do
      expect_match("LOCAL GOVERNMENT, &C. (NO. 7) BILL")
    end

    it 'should match "Employment Relations Bill" in "Official Report of the Grand Committee on the Employment Relations Bill"' do
      should_match_bills("Official Report of the Grand Committee on the Employment Relations Bill", "Employment Relations Bill")
    end

    it 'should extract "Children Bill [Lords]"' do
      expect_match("Children Bill [Lords]")
    end

    it 'should extract "SCOTTISH INSURANCE COMPANIES (SUPERANNUATION FUND) BILL." from ">SCOTTISH INSURANCE COMPANIES (SUPERANNUATION FUND) BILL."' do
      should_match_bills('<span class="bold">SCOTTISH INSURANCE COMPANIES (SUPERANNUATION FUND) BILL.</span>','SCOTTISH INSURANCE COMPANIES (SUPERANNUATION FUND) BILL')
    end

    it "should not match 'A Bill'" do
     should_not_match("A Bill")
    end

    it "should not match 'A Private Member's Bill'" do
     should_not_match("A Private Member's Bill")
    end

    it "should not match 'Although the Bill'" do
     should_not_match("Although the Bill")
    end

    it "should not match 'On Question, Bill'" do
     should_not_match("On Question, Bill")
    end

    it "should not match 'Most Bills come into effect two'" do
     should_not_match("Most Bills come into effect two")
    end

    it 'should extract "Administration of Justice Bill."' do
      expect_match("Administration of Justice Bill")
    end

    it "should not match 'Any Bill'" do
      should_not_match("Any Bill")
    end

    it 'should extract "Local Government Grants (Social Need) Bill" from "Afterwards, Second Reading of the Local Government Grants (Social Need) Bill."' do
      should_match_bills('Afterwards, Second Reading of the Local Government Grants (Social Need) Bill.', 'Local Government Grants (Social Need) Bill')
    end

    it "should not match 'Average Council Tax Bill'" do
      should_not_match("Average Council Tax Bill")
    end

    it "should not match 'Nursery Education and Grant-Maintained Schools Bill'" do
      expect_match("Nursery Education and Grant-Maintained Schools Bill")
    end

    it "should not match 'Access to Justice Bill [Lords]'" do
     expect_match("Access to Justice Bill [Lords]")
    end

    it "should not match 'Baroness Bill'" do
     should_not_match("Baroness Bill")
    end

    it "should not match 'Committal of Bill'" do
     should_not_match("Committal of Bill")
    end

    it "should not match 'Government Bill'" do
     should_not_match("Government Bill")
    end

    it "should not match 'Government's Bill'" do
     should_not_match("Government's Bill")
    end

    it 'should not match "Government\'s Pensions Bill"' do
      should_not_match('Government\'s Pensions Bill')
    end

    it 'should extract "Regional Assemblies Bill" from the "On the Regional Assemblies Bill"' do
      should_match_bills('On the Regional Assemblies Bill', 'Regional Assemblies Bill')
    end

    it 'should extract "Occupiers\' Disqualification Removal Bill" from the"Committee of the Occupiers\' Disqualification Removal Bill"' do
      should_match_bills('Committee of the Occupiers\' Disqualification Removal Bill', 'Occupiers\' Disqualification Removal Bill')
    end

    it 'should match "British Nationality Bill"' do
      expect_match('British Nationality Bill')
    end

    it 'should not match "Draft Bill"' do
      should_not_match('Draft Bill')
    end

    it 'should not match "Draft Bill"' do
      should_not_match('Draft Bill')
    end

    it 'should extract "Seats Bill" from the "Fourth Schedule of the Seats Bill"' do
      should_match_bills('Fourth Schedule of the Seats Bill', 'Seats Bill')
    end

    it 'should extract "Disability Discrimination Bill" from the "on the draft Disability Discrimination Bill,"' do
      should_match_bills('on the draft Disability Discrimination Bill,', 'Disability Discrimination Bill')
    end

    it 'should extract "Disability Discrimination Bill" from the "Draft Disability Discrimination Bill"' do
      should_match_bills('Draft Disability Discrimination Bill', 'Disability Discrimination Bill')
    end

    it 'should extract "Human Rights Bill" from the "In the Human Rights Bill"' do
      should_match_bills('In the Human Rights Bill', 'Human Rights Bill')
    end

    it 'should not match "make the Minister\'s Bill come true"' do
      should_not_match("make the Minister's Bill come true")
    end

    it 'should not match "Clerk of Private Bill"' do
      should_not_match("Clerk of Private Bill")
    end

    it 'should not match "My Bill"' do
      should_not_match("My Bill")
    end

    it 'should not match "No Bill"' do
      should_not_match("No Bill")
    end

    it 'should not match "Second Beading of the Bill"' do
      should_not_match("Second Beading of the Bill")
    end

    it 'should not match "Standing Committee B, Freedom of Information Bill"' do
      should_not_match('Standing Committee B, Freedom of Information Bill')
    end

    it 'should extract "Sexual Offences Bill" from the ">The Sexual Offences Bill"' do
      should_match_bills('>The Sexual Offences Bill', 'Sexual Offences Bill')
    end

    it 'should extract "Baxi Partnership Limited Trusts Bill" from the "That the Promoters of the Baxi Partnership Limited Trusts Bill"' do
      should_match_bills('That the Promoters of the Baxi Partnership Limited Trusts Bill', 'Baxi Partnership Limited Trusts Bill')
    end

    it 'should extract "Pensions Bill" from the "Through the Pensions Bill"' do
      should_match_bills('Through the Pensions Bill', 'Pensions Bill')
    end

    it 'should extract "Human Rights Bill" from the "Under the Human Rights Bill"' do
      should_match_bills('Under the Human Rights Bill', 'Human Rights Bill')
    end

    it 'should not match "the Unopposed Bill"' do
      should_not_match('the Unopposed Bill')
    end

    it 'should not match "English Bill"' do
      should_not_match('English Bill')
    end

    it 'should not match ">A Bill"' do
      should_not_match('>A Bill')
    end

    it 'should not match "Back-Bench Bill"' do
      should_not_match('Back-Bench Bill')
    end

    it 'should extract "Northern Ireland Bill" from the "Wales Act, the Northern Ireland Bill"' do
      should_match_bills('Wales Act, the Northern Ireland Bill', 'Northern Ireland Bill')
    end

    it 'should extract "Law Commissions Bill" from the "When the Law Commissions Bill"' do
     should_match_bills('When the Law Commissions Bill', 'Law Commissions Bill')
    end

    it 'should extract "Finance Bill" from the "On the Second Reading of the Finance Bill"' do
     should_match_bills('On the Second Reading of the Finance Bill', 'Finance Bill')
    end

    it 'should extract "Racecourse Betting Bill" from the "on the Wednesday the Racecourse Betting Bill"' do
     should_match_bills('on the Wednesday the Racecourse Betting Bill', 'Racecourse Betting Bill')
    end

    it 'should extract "Criminal Injuries Compensation Bill" from the "Once the Criminal Injuries Compensation Bill"' do
     should_match_bills('Once the Criminal Injuries Compensation Bill', 'Criminal Injuries Compensation Bill')
    end

    it 'should extract "Family Homes and Domestic Violence Bill" from the "As for the Family Homes and Domestic Violence Bill"' do
     should_match_bills('As for the Family Homes and Domestic Violence Bill', 'Family Homes and Domestic Violence Bill')
    end

    it 'should extract "Finance Bill" from the "Board into the Finance Bill"' do
     should_match_bills('Board into the Finance Bill', 'Finance Bill')
    end

    it 'should not match "This Bill"' do
      should_not_match('This Bill')
    end

    it 'should extract "Anti-Social Behaviour Bill" from the "All of the Anti-Social Behaviour Bill"' do
     should_match_bills('All of the Anti-Social Behaviour Bill', 'Anti-Social Behaviour Bill')
    end

    it 'should not match "BUSINESS OF THE HOUSE (CUSTOMS (IMPORT DEPOSITS) BILL"' do
      should_not_match('BUSINESS OF THE HOUSE (CUSTOMS (IMPORT DEPOSITS) BILL')
    end

    it 'should extract "Parliamentary Elections (Redistribution) Bill" from the "Report of the Parliamentary Elections (Redistribution) Bill"' do
     should_match_bills('Report of the Parliamentary Elections (Redistribution) Bill', 'Parliamentary Elections (Redistribution) Bill')
    end

    it 'should extract "Appropriation Bill" from the "Second Heading of the Appropriation Bill"' do
     should_match_bills('Second Heading of the Appropriation Bill', 'Appropriation Bill')
    end

    it 'should extract "Administration of Justice Bill" from the "Commons Amendments to the Administration of Justice Bill"' do
     should_match_bills('Commons Amendments to the Administration of Justice Bill', 'Administration of Justice Bill')
    end

    it 'should extract "Finance Bill" from the "<p>  The Finance Bill"' do
     should_match_bills('<p>  The Finance Bill', 'Finance Bill')
    end

    it 'should extract "Medical (Professional Performance) Bill" from the "Lords Amendments to the Medical (Professional Performance) Bill"' do
     should_match_bills('Lords Amendments to the Medical (Professional Performance) Bill', 'Medical (Professional Performance) Bill')
    end

    it 'should extract "Immigration and Asylum Bill" from the "Explanatory Notes to the Immigration and Asylum Bill"' do
     should_match_bills('Explanatory Notes to the Immigration and Asylum Bill', 'Immigration and Asylum Bill')
    end

    it 'should extract "Occupiers\' Disqualification Removal Bill" from the "Instruction to the Committee of the Occupiers\' Disqualification Removal Bill"' do
     should_match_bills("Instruction to the Committee of the Occupiers' Disqualification Removal Bill", "Occupiers' Disqualification Removal Bill")
    end

    it 'should not match "or the Public Bill Office to"' do
      should_not_match('or the Public Bill Office to')
    end

    it 'should extract "PARLIAMENTARY ELECTIONS (REDISTRIBUTION) (re-committed) BILL.&#x2014;[BILL.49.]"' do
      should_extract "PARLIAMENTARY ELECTIONS (REDISTRIBUTION) (re-committed) BILL.&#x2014;[BILL.49.]", "PARLIAMENTARY ELECTIONS (REDISTRIBUTION) (re-committed) BILL", '49'
    end

    it 'should match "Insolvency Bill <i>[Lords]</i>"' do
      expect_match('Insolvency Bill <i>[Lords]</i>')
    end
  
    it 'should match "Insolvency Bill [<i>Lords</i>]"' do
      expect_match('Insolvency Bill [<i>Lords</i>]')
    end

    it 'should extract "Insolvency Bill [Lords]" from "Insolvency Bill <i>[Lords]</i>"' do
      should_extract "Insolvency Bill <i>[Lords]</i>", "Insolvency Bill [Lords]", nil
    end
  
    it 'should extract "Insolvency Bill [Lords]" from "Insolvency Bill [<i>Lords</i>]"' do 
      should_extract "Insolvency Bill [<i>Lords</i>]", "Insolvency Bill [Lords]", nil
    end

    it 'should not match "This Budget and Finance Bill"' do
      should_not_match('This Budget and Finance Bill')
    end

    it 'should extract "Finance Bill" from the "the Chief Secretary of the Finance Bill"' do
     should_match_bills('the Chief Secretary of the Finance Bill', 'Finance Bill')
    end

    it 'should extract "INFANTICIDE BILL [H.L.]" from "FORMERLY INFANTICIDE BILL [H.L.]"' do
      should_match_bills("FORMERLY INFANTICIDE BILL [H.L.]", "INFANTICIDE BILL [H.L.]")
    end

    it 'should extract "Finance Bill" from "introduced the Clause in the Finance Bill"' do
      should_match_bills("introduced the Clause in the Finance Bill", "Finance Bill")
    end
  
    it 'should not match "A British Bill"' do 
      should_not_match('A British Bill')
    end
  
    it 'should extract "Finance Bill" from "Act in the Finance Bill"' do
      should_match_bills('Act in the Finance Bill', 'Finance Bill')
    end
  
    it 'should match "Environment Bill" in "Act of the Environment Bill"' do 
      should_match_bills("Act of the Environment Bill", 'Environment Bill')
    end
  
    it 'should not match "Advice and Inspection Notes and Bill"' do 
      should_not_match("Advice and Inspection Notes and Bill")
    end
 
    it 'should match "Water Bill" in "After Royal Assent of the Water Bill"' do 
      should_match_bills("After Royal Assent of the Water Bill", "Water Bill")
    end

    it 'should not match "Afterwards Bill"' do 
      should_not_match("Afterwards Bill")
    end
  
    it 'should not match "Afterwards, Finance Bill"' do
      should_not_match("Afterwards, Finance Bill")
    end

    it 'should not match "Again, in the Scottish Bill"' do 
      should_match_bills("Again, in the Scottish Bill", "Scottish Bill")
    end

    it 'should match "Brighton Bill" in "Amendment in the Brighton Bill"' do
      should_match_bills("Amendment in the Brighton Bill", "Brighton Bill")
    end
  
    it 'should not match "Amended Bill"' do 
      should_not_match("Amended Bill")
    end
  
    it 'should not match "Amending Bill"' do 
      should_not_match("Amending Bill")
    end
  
    it 'should not match "Amendment Bill"' do 
      should_not_match("Amendment Bill")
    end
  
    it 'should match "Poor Law Bill" in "Amendment of the Poor Law Bill"' do 
      should_match_bills("Amendment of the Poor Law Bill", "Poor Law Bill")
    end
  
    it 'should not match "Amendment to Amendments to East Anglian Electricity Bill"' do 
      should_not_match("Amendment to Amendments to East Anglian Electricity Bill")
    end
  
    it 'should match "Revenue Bill" in "Amendments of the Revenue Bill"' do 
      should_match_bills("Amendments of the Revenue Bill", "Revenue Bill")
    end
  
    it 'should not match "Amendment in the English Bill"' do 
      should_not_match("Amendment in the English Bill")
    end
  
    it 'should not match "AND WATER BILL [H.L.]"' do 
      should_not_match("AND WATER BILL [H.L.]")
    end
  
    it 'should not match "Another Bill"' do 
      should_not_match("Another Bill")
    end
  
    it 'should not match "As in the English Bill"' do 
      should_not_match("As in the English Bill")
    end
  
    it 'should not match "Ballot for Private Members\' Bill"' do 
      should_not_match("Ballot for Private Members' Bill")
    end
  
    it 'should match "Local Government Bill" in "Bill in the Local Government Bill"' do 
      should_match_bills("Bill in the Local Government Bill", "Local Government Bill")
    end
  
    it 'should match "Children Bill" in "Under Part I of the Children Bill"' do 
      should_match_bills("Under Part I of the Children Bill", "Children Bill")
    end
  
    it 'should not match "Amending Munitions Bill"' do 
      should_not_match("Amending Munitions Bill")
    end
  
    it 'should match "Misuse of Drugs Bill" in "Amendment Paper for the Misuse of Drugs Bill"' do 
      should_match_bills("Amendment Paper for the Misuse of Drugs Bill", "Misuse of Drugs Bill")
    end

    it 'should not match "AND CREMATORIUM LIMITED BILL"' do 
     should_not_match("AND CREMATORIUM LIMITED BILL")
    end

    it 'should not match "Another Deer Bill"' do 
     should_not_match("Another Deer Bill")
    end

    it 'should match "Licensing Bill" in "As in the Licensing Bill"' do 
      should_match_bills("As in the Licensing Bill", "Licensing Bill")
    end
  
    it 'should match "Bankruptcy (Scotland) Consolidation Bill" in "As to the Bankruptcy (Scotland) Consolidation Bill"' do 
      should_match_bills("As to the Bankruptcy (Scotland) Consolidation Bill", "Bankruptcy (Scotland) Consolidation Bill")
    end
  
    it 'should not match "Amended Merchant Seamen Bill"' do 
      should_not_match("Amended Merchant Seamen Bill")
    end

    it 'should not match "Between Portland Bill"' do 
      should_not_match("Between Portland Bill")
    end
  
    it 'should not match "Bill and Bill No. 2"' do 
      should_not_match("Bill and Bill No. 2")
    end
  
    it 'should not match "Bill in the Local Government Bill"' do 
      should_match_bills("Bill in the Local Government Bill", "Local Government Bill")
    end
  
    it 'should not match "Bill, Australian States Constitution Bill"' do 
      should_not_match("Bill, Australian States Constitution Bill")
    end
  
    it 'should not match "Bills, and to the Public Bill"' do 
      should_not_match("Bills, and to the Public Bill")
    end

    it 'should match "Scotland Bill" in "But in the Scotland Bill"' do 
      should_match_bills("But in the Scotland Bill", "Scotland Bill")
    end
  
    it 'should match "Police Bill" in "Campaign Against the Police Bill"' do 
      should_match_bills("Campaign Against the Police Bill", "Police Bill")
    end
  
    it 'should match "Scottish Criminal Justice Bill" in "Campaign to Stop the Scottish Criminal Justice Bill"' do 
      should_match_bills("Campaign to Stop the Scottish Criminal Justice Bill", "Scottish Criminal Justice Bill")
    end  
  
    it 'should match "Case Against the Dogs Bill" in "Case Against the Dogs Bill"' do 
      should_match_bills("Case Against the Dogs Bill", "Dogs Bill")
    end
  
    it 'should match "Consolidation Bill" in "Chairman of the Consolidation Bill"' do 
      should_match_bills("Chairman of the Consolidation Bill", "Consolidation Bill")
    end

    it 'should not match "Chancellor of the Exchequer in Finance Bill"' do 
     should_not_match("Chancellor of the Exchequer in Finance Bill")
    end 

    it 'should match "Finance Bill" in "Chancellor in the Finance Bill"' do 
      should_match_bills("Chancellor in the Finance Bill", "Finance Bill")
    end 

    it 'should not match "Clerk in the Public Bill"' do 
      should_not_match("Clerk in the Public Bill")
    end
  
    it 'should not match "Clerk of Supply in the Public Bill"' do 
      should_not_match("Clerk of Supply in the Public Bill")
    end

    it 'should not match "Clerk to the Public Bill"' do 
     should_not_match("Clerk to the Public Bill")
    end 

    it 'should not match "Clerks of the Public Bill "' do 
      should_not_match("Clerks of the Public Bill ")
    end 
  
    it 'should match "Church Building Acts Amendment Bill" in "Committal of the Church Building Acts Amendment Bill"' do 
      should_match_bills("Committal of the Church Building Acts Amendment Bill", "Church Building Acts Amendment Bill")
    end
  
    it 'should match "Criminal Justice Bill" in "Committe Stage of the Criminal Justice Bill"' do 
      should_match_bills("Committe Stage of the Criminal Justice Bill", "Criminal Justice Bill")
    end
  
    it 'should match "Air Navigation (Financial Provisions) Bill" in "Committee and Third Reading of the Air Navigation (Financial Provisions) Bill"' do 
      should_match_bills("Committee and Third Reading of the Air Navigation (Financial Provisions) Bill", "Air Navigation (Financial Provisions) Bill")
    end
  
    it 'should match "Brighton Bill" in "Committee for the Brighton Bill"' do 
      should_match_bills("Committee for the Brighton Bill", "Brighton Bill")
    end
  
    it 'should match "Betting and Gaming Bill" in "Committee in the Betting and Gaming Bill"' do 
      should_match_bills("Committee in the Betting and Gaming Bill", "Betting and Gaming Bill")
    end
  
    it 'should match "Army (Annual) Bill" in "Committee Stage of the Army (Annual) Bill"' do 
      should_match_bills("Committee Stage of the Army (Annual) Bill", "Army (Annual) Bill")
    end
  
    it 'should match "Social Security Bill" in "Committee Stages of the Social Security Bill"' do 
      should_match_bills("Committee Stages of the Social Security Bill", "Social Security Bill")
    end

    it 'should match "Osteopaths Bill" in "Committees of the Osteopaths Bill"' do 
      should_match_bills("Committees of the Osteopaths Bill", "Osteopaths Bill")
    end

    it 'should match "Housing (Scotland) Bill" in "Commons to the Housing (Scotland) Bill"' do 
      should_match_bills("Commons to the Housing (Scotland) Bill", "Housing (Scotland) Bill")
    end  
  
    it 'should match "Imprisonment for Debt Bill" in "Commons\' Amendments to the Imprisonment for Debt Bill"' do 
      should_match_bills("Commons' Amendments to the Imprisonment for Debt Bill", "Imprisonment for Debt Bill")
    end  

    it 'should not match "Conservative Government\'s Firearms (Amendment) Bill"' do 
      should_not_match("Conservative Government's Firearms (Amendment) Bill")
    end

    it 'should not match "COMMONS AMENDMENTS TO WORDS RESTORED TO TILE BILL"' do 
      should_not_match("COMMONS AMENDMENTS TO WORDS RESTORED TO TILE BILL")
    end 
  
    it 'should not match "Conservative Bill"' do 
      should_not_match("Conservative Bill")
    end   
  
    it 'should match "Human Rights Bill [Lords]" in "Consideration in Committee of the Human Rights Bill [Lords]"' do 
      should_match_bills("Consideration in Committee of the Human Rights Bill [Lords]", "Human Rights Bill [Lords]")
    end  

    it 'should match "Employers\' Liability (Defective Equipment) Bill" in "Consideration of Lords Amendment to the Employers\' Liability (Defective Equipment) Bill"' do 
      should_match_bills("Consideration of Lords Amendment to the Employers' Liability (Defective Equipment) Bill", "Employers' Liability (Defective Equipment) Bill")
    end  

    it 'should match "Miners\' Welfare Bill" in "Consideration of the Lords Amendments to the Miners\' Welfare Bill"' do 
      should_match_bills("Consideration of the Lords Amendments to the Miners' Welfare Bill", "Miners' Welfare Bill")
    end

    it 'should match "Transport Bill" in "Debates in the Transport Bill"' do 
      should_match_bills("Debates in the Transport Bill", "Transport Bill")
    end
  
    it 'should match "Home Rule Bill" in "Debates of the Home Rule Bill"' do 
      should_match_bills("Debates of the Home Rule Bill", "Home Rule Bill")
    end
  
    it 'should match "Irish Church Bill" in "Debates of the Irish Church Bill"' do 
      should_match_bills("Debates of the Irish Church Bill", "Irish Church Bill")
    end
  
    it 'should match "Local Government Bill" in "Debates On the Local Government Bill"' do 
      should_match_bills("Debates On the Local Government Bill", "Local Government Bill")
    end
 
    it 'should match "Irish Tithe Rent-charge Bill" in "Debate to the Irish Tithe Rent-charge Bill"' do 
      should_match_bills("Debate to the Irish Tithe Rent-charge Bill", "Irish Tithe Rent-charge Bill")
    end  
 
    it 'should match "Debates Bill" in "Debates Bill"' do 
      should_match_bills("Debates Bill", "Debates Bill")
    end  
  
    it 'should match "Financial Services and Markets Bill" in "Draft Financial Services and Markets Bill"' do 
      should_match_bills("Draft Financial Services and Markets Bill", "Financial Services and Markets Bill")
    end
  
    it 'should not match "Each United Kingdom Bill"' do 
      should_not_match("Each United Kingdom Bill ")
    end   

    it 'should not match "Every Finance Bill"' do 
      should_not_match("Every Finance Bill")
    end  
   
    it 'should match "Textile and Apparel Trade Bill" in "EEC of the Textile and Apparel Trade Bill"' do 
      should_match_bills("EEC of the Textile and Apparel Trade Bill", "Textile and Apparel Trade Bill")
    end
  
    it 'should match "Industry Bill" in "EEC to the Industry Bill"' do 
      should_match_bills("EEC to the Industry Bill", "Industry Bill")
    end

    it 'should match "Wages Bill" in "Effects of the Wages Bill"' do 
      should_match_bills("Effects of the Wages Bill", "Wages Bill")
    end
  
    it 'should match "Revenue Bill" in "Exchequer, in the Revenue Bill"' do 
      should_match_bills("Exchequer, in the Revenue Bill", "Revenue Bill")
    end
  
    it 'should match "Finance Bill" in "Exchequer in the Finance Bill"' do 
      should_match_bills("Exchequer in the Finance Bill", "Finance Bill")
    end
  
    it 'should match "National Debt Bill" in "Exchequer, If the National Debt Bill"' do 
      should_match_bills("Exchequer, If the National Debt Bill", "National Debt Bill")
    end
  
    it 'should match "Irish Reform Bill" in "Exchequer, When the Irish Reform Bill"' do 
      should_match_bills("Exchequer, When the Irish Reform Bill", "Irish Reform Bill")
    end
  
    it 'should match "Crime (Sentences) Bill" in "Explanatory and Financial Memorandum of the Crime (Sentences) Bill"' do 
      should_match_bills("Explanatory and Financial Memorandum of the Crime (Sentences) Bill", "Crime (Sentences) Bill")
    end
  
    it 'should match "Government of Wales Bill" in "Explanatory and Financial Memorandum to the Government of Wales Bill"' do 
      should_match_bills("Explanatory and Financial Memorandum to the Government of Wales Bill", "Government of Wales Bill")
    end
  
    it 'should match "Criminal Law Bill" in "Explanatory Memorandum of the Criminal Law Bill"' do 
      should_match_bills("Explanatory Memorandum of the Criminal Law Bill", "Criminal Law Bill")
    end
  
    it 'should match "Cotton Industry Bill" in "Explanatory Memorandum to the Cotton Industry Bill"' do 
      should_match_bills("Explanatory Memorandum to the Cotton Industry Bill", "Cotton Industry Bill")
    end

    it 'should match "Home Rule Bill" in "First and Second Readings of the Home Rule Bill"' do 
      should_match_bills("First and Second Readings of the Home Rule Bill", "Home Rule Bill")
    end
  
    it 'should match "Parliament Bill" in "First and Third Readings of the Parliament Bill"' do 
      should_match_bills("First and Third Readings of the Parliament Bill", "Parliament Bill")
    end
  
    it 'should match "Local Taxation Bill" in "First Lord of the Admiralty, Whether, in the Local Taxation Bill"' do 
      should_match_bills("First Lord of the Admiralty, Whether, in the Local Taxation Bill", "Local Taxation Bill")
    end
  
    it 'should match "Local Courts of Bankruptcy (Ireland) Bill" in "First Lord of the Treasury, When the Local Courts of Bankruptcy (Ireland) Bill"' do 
      should_match_bills("First Lord of the Treasury, When the Local Courts of Bankruptcy (Ireland) Bill", "Local Courts of Bankruptcy (Ireland) Bill")
    end
  
    it 'should match "Marine Mutiny Bill" in "First Lord of the Admiralty, If the Second Reading of the Marine Mutiny Bill"' do 
      should_match_bills("First Lord of the Admiralty, If the Second Reading of the Marine Mutiny Bill", "Marine Mutiny Bill")
    end
  
    it 'should match "Conveyancing (Scotland) Acts Amendment Bill" in "First Lord of the Treasury, Whether the Conveyancing (Scotland) Acts Amendment Bill"' do 
      should_match_bills("First Lord of the Treasury, Whether the Conveyancing (Scotland) Acts Amendment Bill", "Conveyancing (Scotland) Acts Amendment Bill")
    end
  
    it 'should match "Land Purchase (Ireland) Bill" in "First Lord of the Treasury, Why the Land Purchase (Ireland) Bill"' do 
      should_match_bills("First Lord of the Treasury, Why the Land Purchase (Ireland) Bill", "Land Purchase (Ireland) Bill")
    end
  
    it 'should match "Indian Councils Bill" in "First Order the Report of the Indian Councils Bill"' do 
      should_match_bills("First Order the Report of the Indian Councils Bill", "Indian Councils Bill")
    end
  
    it 'should match "Equalisation of Rates (London) Bill" in "First Readings of the Equalisation of Rates (London) Bill"' do 
      should_match_bills("First Readings of the Equalisation of Rates (London) Bill", "Equalisation of Rates (London) Bill")
    end
  
    it 'should match "Rent Restrictions Bill" in "First Reading to the Rent Restrictions Bill"' do 
      should_match_bills("First Reading to the Rent Restrictions Bill", "Rent Restrictions Bill")
    end

    it 'should match "Budget Bill" in "First, Second, and Third Reading of the Budget Bill"' do 
      should_match_bills("First, Second, and Third Reading of the Budget Bill", "Budget Bill")
    end  

    it 'should match "Finance Bill" in "Floor of the House for the Finance Bill"' do 
      should_match_bills("Floor of the House for the Finance Bill", "Finance Bill")
    end  
  
    it 'should match "Road Traffic (Random Breath Testing) Bill" in "Floor of the House of the Road Traffic (Random Breath Testing) Bill"' do 
      should_match_bills("Floor of the House of the Road Traffic (Random Breath Testing) Bill", "Road Traffic (Random Breath Testing) Bill")
    end  
  
    it 'should match "Finance Bill" in "From Royal Assent to the Finance Bill"' do 
      should_match_bills("From Royal Assent to the Finance Bill", "Finance Bill")
    end  
  
    it 'should match "Criminal Justice Bill" in "Government in Part I of the Criminal Justice Bill"' do 
      should_match_bills("Government in Part I of the Criminal Justice Bill", "Criminal Justice Bill")
    end  
  
    it 'should match "Child Benefit Bill" in "Government in the Child Benefit Bill"' do 
      should_match_bills("Government in the Child Benefit Bill", "Child Benefit Bill")
    end  
  
    it 'should match "Cotton Spinning Industry Bill" in "Government of the Cotton Spinning Industry Bill"' do 
      should_match_bills("Government of the Cotton Spinning Industry Bill", "Cotton Spinning Industry Bill")
    end  
  
    it 'should match "Family Law Bill" in "Government to the Family Law Bill"' do 
      should_match_bills("Government to the Family Law Bill", "Family Law Bill")
    end  
  
    it 'should match "Factory Bill" in "Government, in the Factory Bill"' do 
      should_match_bills("Government, in the Factory Bill", "Factory Bill")
    end  

    it 'should not match "Government-inspired Bill"' do 
      should_not_match("Government-inspired Bill")
    end
    
    it 'should not match "Government-sponsored Disability Discrimination Bill"' do 
      should_not_match("Government-sponsored Disability Discrimination Bill")
    end
  
    it 'should match "Irish Agricultural Rating Bill" in "Gracious Speech of the Irish Agricultural Rating Bill"' do 
      should_match_bills("Gracious Speech of the Irish Agricultural Rating Bill", "Irish Agricultural Rating Bill")
    end
  
    it 'should match "Reserve Forces Bill" in "Gracious Speech to the Reserve Forces Bill"' do 
      should_match_bills("Gracious Speech to the Reserve Forces Bill", "Reserve Forces Bill")
    end
  
    it 'should match "Trade Disputes and Trade Unions Bill" in "Guillotine for the Trade Disputes and Trade Unions Bill"' do 
      should_match_bills("Guillotine for the Trade Disputes and Trade Unions Bill", "Trade Disputes and Trade Unions Bill")
    end 
  
    it 'should match "Transport Bill" in "Guillotine Motion of the House the Third Reading of the Transport Bill"' do 
      should_match_bills("Guillotine Motion of the House the Third Reading of the Transport Bill", "Transport Bill")
    end
  
    it 'should match "Welsh Church Bill" in "Guillotine Resolution for the Welsh Church Bill"' do 
      should_match_bills("Guillotine Resolution for the Welsh Church Bill", "Welsh Church Bill")
    end
  
    it 'should match "Wheat Bill" in "Guillotine to the Wheat Bill"' do 
      should_match_bills("Guillotine to the Wheat Bill", "Wheat Bill")
    end
  
    it 'should match "Finance Bill" in "Floor of the House in the Finance Bill"' do 
      should_match_bills("Floor of the House in the Finance Bill", "Finance Bill")
    end
    
    it 'should match "GOVERNMENT OF INDIA (ADEN) BILL" in "GOVERNMENT OF INDIA (ADEN) BILL"' do 
      should_match_bills("GOVERNMENT OF INDIA (ADEN) BILL", "GOVERNMENT OF INDIA (ADEN) BILL")
    end

    it 'should match "Home Rule Bill" in "Imperial Parliament, in the Home Rule Bill"' do 
      should_match_bills("Imperial Parliament, in the Home Rule Bill", "Home Rule Bill")
    end 

    it 'should match "Wildlife and Countryside Bill" in "Labour Front Bench to the Wildlife and Countryside Bill"' do 
      should_match_bills("Labour Front Bench to the Wildlife and Countryside Bill", "Wildlife and Countryside Bill")
    end 

    it 'should not match "His Bill"' do 
      should_not_match("His Bill")
    end   
  
    it 'should not match "His Treasure Bill"' do 
      should_not_match("His Treasure Bill")
    end   
  
    it 'should not match "House, Finance Bill"' do 
      should_not_match("House, Finance Bill")
    end   
  
    it 'should not match "Hypothetical Bill"' do 
      should_not_match("Hypothetical Bill")
    end
  
    it 'should not match "I and Settlement (Facilities) Bill"' do 
      should_not_match("I and Settlement (Facilities) Bill")
    end   
  
    it 'should not match "Ian Bill"' do 
      should_not_match("Ian Bill")
    end   
  
    it 'should not match "In Finance Bill"' do 
      should_not_match("In Finance Bill")
    end   
  
    it 'should not match "Introduction of Government Valuation Bill"' do 
      should_not_match("Introduction of Government Valuation Bill")
    end   

    it 'should match "Crofters Acts Amendment Bill" in "Introduction of the Crofters Acts Amendment Bill"' do 
      should_match_bills("Introduction of the Crofters Acts Amendment Bill", "Crofters Acts Amendment Bill")
    end 

    it 'should match "Housing Bill" in "Labour Government, in the Housing Bill"' do 
      should_match_bills("Labour Government, in the Housing Bill", "Housing Bill")
    end 

    it 'should match "Consolidation Bill" in "Lords in the Consolidation Bill"' do 
      should_match_bills("Lords in the Consolidation Bill", "Consolidation Bill")
    end 
  
    it 'should not match "Lords Bill"' do 
      should_not_match("Lords Bill")
    end
  
    it 'should not match "Labour Government\'s Energy Bill"' do 
      should_not_match("Labour Government's Energy Bill")
    end
  
    it 'should not match "Labour Party Pensions Plan (Enabling) Bill"' do 
      should_not_match("Labour Party Pensions Plan (Enabling) Bill")
    end
  
    it 'should not match "Liberal Government\'s Education Bill"' do 
       should_not_match("Liberal Government's Education Bill")
     end

    it 'should match "Education (Scotland) Bill" in "Long Title of the Education (Scotland) Bill"' do 
      should_match_bills("Long Title of the Education (Scotland) Bill", "Education (Scotland) Bill")
    end 

    it 'should match "Scotch University Bill" in "Lord Advocate, When the Scotch University Bill"' do 
      should_match_bills("Lord Advocate, When the Scotch University Bill", "Scotch University Bill")
    end 

    it 'should match "Cattle Diseases Bill" in "Lord President of the Council, Whether the Cattle Diseases Bill"' do 
      should_match_bills("Lord President of the Council, Whether the Cattle Diseases Bill", "Cattle Diseases Bill")
    end
  
    it 'should match "Paper Duty Repeal Bill" in "Lords of the Paper Duty Repeal Bill"' do 
      should_match_bills("Lords of the Paper Duty Repeal Bill", "Paper Duty Repeal Bill")
    end
  
    it 'should match "Corn Production Acts (Repeal) Bill" in "Lords to Commons Amendment to Lords Amendment to the Corn Production Acts (Repeal) Bill"' do 
      should_match_bills("Lords to Commons Amendment to Lords Amendment to the Corn Production Acts (Repeal) Bill", "Corn Production Acts (Repeal) Bill")
    end
  
    it 'should match "Commonwealth Immigrants Bill" in "Lords to the Commonwealth Immigrants Bill"' do 
      should_match_bills("Lords to the Commonwealth Immigrants Bill", "Commonwealth Immigrants Bill")
    end
  
    it 'should match "Free Education Bill" in "Lords\' Amendment to the Free Education Bill"' do 
      should_match_bills("Lords' Amendment to the Free Education Bill", "Free Education Bill")
    end
  
    it 'should match "Mines Regulation Bill" in "Lords\' Amendments to the Mines Regulation Bill"' do 
      should_match_bills("Lords' Amendments to the Mines Regulation Bill", "Mines Regulation Bill")
    end  
    
    it 'should not match "Lords\' Public Bill"' do 
      should_not_match("Lords\' Public Bill")
    end

    it 'should not match "Lords, Lord Lester\'s Equality Bill"' do 
      should_not_match("Lords, Lord Lester\'s Equality Bill")
    end
  
     it 'should not match "January Bill"' do 
     should_not_match("January Bill")
    end

    it 'should not match "February Bill"' do 
     should_not_match("February Bill")
    end

    it 'should not match "March Bill"' do 
     should_not_match("March Bill")
    end

    it 'should not match "April Bill"' do 
     should_not_match("April Bill")
    end

    it 'should not match "July Bill"' do 
     should_not_match("July Bill")
    end

    it 'should not match "October Bill"' do 
     should_not_match("October Bill")
    end

    it 'should not match "November Bill"' do 
     should_not_match("November Bill")
    end
 
    it 'should match "Pensions Bill" in "Measures in the Pensions Bill"' do 
      should_match_bills("Measures in the Pensions Bill", "Pensions Bill")
    end
  
    it 'should match "Industrial Relations Bill" in "Marshalled List of the Industrial Relations Bill"' do 
      should_match_bills("Marshalled List of the Industrial Relations Bill", "Industrial Relations Bill")
    end
  
    it 'should match "Silverman Bill" in "Member for Hendon, South to the Silverman Bill"' do 
      should_match_bills("Member for Hendon, South to the Silverman Bill", "Silverman Bill")
    end
  
    it 'should match "POLICE BILL" in "MEMORANDUM ON THE POLICE BILL"' do 
      should_match_bills("MEMORANDUM ON THE POLICE BILL", "POLICE BILL")
    end
  
    it 'should match "Wheat Bill" in "Memorandum of the Wheat Bill"' do 
      should_match_bills("Memorandum of the Wheat Bill", "Wheat Bill")
    end
  
    it 'should match "Unemployment Insurance Bill No. 2" in "Memorandum to the Unemployment Insurance Bill No. 2"' do 
      should_match_bills("Memorandum to the Unemployment Insurance Bill No. 2", "Unemployment Insurance Bill No. 2")
    end
      
    it 'should match "Vehicles (Crime) Bill" in "Minister in the Vehicles (Crime) Bill"' do 
      should_match_bills("Minister in the Vehicles (Crime) Bill", "Vehicles (Crime) Bill")
    end 
      
    it 'should match "Local Government Bill" in "Minister of Health in the Local Government Bill"' do 
      should_match_bills("Minister of Health in the Local Government Bill", "Local Government Bill")
    end
      
    it 'should match "English Bill" in "Minister of State in the English Bill"' do 
      should_not_match("Minister of State in the English Bill")
    end
    
    it 'should match "Transport Bill" in "Minister of Transport in the Transport Bill"' do 
      should_match_bills("Minister of Transport in the Transport Bill", "Transport Bill")
    end

    it 'should not match "Minister, Mr Bill"' do 
      should_not_match("Minister, Mr Bill")
    end

    it 'should match "Fire Brigades Bill" in "Money Resolution of the Fire Brigades Bill"' do 
      should_match_bills("Money Resolution of the Fire Brigades Bill", "Fire Brigades Bill")
    end
  
    it 'should match "Pensions (Increase) Bill" in "Money Resolution for the Pensions (Increase) Bill"' do 
      should_match_bills("Money Resolution for the Pensions (Increase) Bill", "Pensions (Increase) Bill")
    end
  
    it 'should match "Energy Bill" in "Money Resolution to the Energy Bill"' do 
      should_match_bills("Money Resolution to the Energy Bill", "Energy Bill")
    end
  
    it 'should match "Import Duties Bill" in "Money Resolutions of the Import Duties Bill"' do 
      should_match_bills("Money Resolutions of the Import Duties Bill", "Import Duties Bill")
    end
  
    it 'should match "Irish Home Rule Bill" in "Motion to the Irish Home Rule Bill"' do 
      should_match_bills("Motion to the Irish Home Rule Bill", "Irish Home Rule Bill")
    end

    it 'should not match "Motion for Second Reading and Bill"' do 
      should_not_match("Motion for Second Reading and Bill")
    end

    it 'should not match "Motion, and Bill"' do 
      should_not_match("Motion, and Bill")
    end
  
    it 'should match "Adoption and Children Bill" in "Moved, That the Adoption and Children Bill"' do 
      should_match_bills("Moved, That the Adoption and Children Bill", "Adoption and Children Bill")
    end

    it 'should not match "My Defamation Bill"' do 
      should_not_match("My Defamation Bill")
    end

    it 'should not match "Next Presentations Bill"' do 
      should_not_match("Next Presentations Bill")
    end

    it 'should not match "Next Social Security Bill"' do 
      should_not_match("Next Social Security Bill")
    end
  
    it 'should not match "No Superannuation Bill"' do 
      should_not_match("No Superannuation Bill")
    end
  
    it 'should match "Freedom of Information Bill" in "Nothing in the Freedom of Information Bill"' do 
      should_match_bills("Nothing in the Freedom of Information Bill", "Freedom of Information Bill")
    end
  
    it 'should match "Flood Prevention (Scotland) Bill" in "Notice of the Lords Amendments to the Flood Prevention (Scotland) Bill"' do 
      should_match_bills("Notice of the Lords Amendments to the Flood Prevention (Scotland) Bill", "Flood Prevention (Scotland) Bill")
    end
  
    it 'should not match "NOTES ON DRAFT THEFT BILL"' do 
      should_not_match("NOTES ON DRAFT THEFT BILL")
    end

    it 'should match "Iron and Steel Bill" in "Notice Paper Amendments to the Iron and Steel Bill"' do 
      should_match_bills("Notice Paper Amendments to the Iron and Steel Bill", "Iron and Steel Bill")
    end
  
    it 'should not match "NOTICES TO BE GIVEN AND DEPOSITS MADE IN CASES WHERE WORK IS ALTERED WHILE BILL"' do 
      should_match_bills("NOTICES TO BE GIVEN AND DEPOSITS MADE IN CASES WHERE WORK IS ALTERED WHILE BILL", "NOTICES TO BE GIVEN AND DEPOSITS MADE IN CASES WHERE WORK IS ALTERED WHILE BILL")
    end
  
    it 'should match "Finance Bill" in "Now, in the Finance Bill"' do 
      should_match_bills("Now, in the Finance Bill", "Finance Bill")
    end
  
    it 'should match "Local Government Bill" in "Nowhere in the Local Government Bill"' do 
      should_match_bills("Nowhere in the Local Government Bill", "Local Government Bill")
    end

    it 'should match "Civil Aviation Bill" in "OFFICIAL REPORT of the Second Reading of the Civil Aviation Bill"' do 
      should_match_bills("OFFICIAL REPORT of the Second Reading of the Civil Aviation Bill", "Civil Aviation Bill")
    end
  
    it 'should match "Teachers\' Superannuation Bill" in "OFFICIAL REPORT in the Teachers\' Superannuation Bill"' do 
      should_match_bills("OFFICIAL REPORT in the Teachers' Superannuation Bill", "Teachers' Superannuation Bill")
    end

    it 'should not match "Official Report, House of Lords, Public Bill"' do 
      should_not_match("Official Report, House of Lords, Public Bill")
    end
  
    it 'should match "Children and Young Persons Bill" in "On Friday the Second Reading of the Children and Young Persons Bill"' do 
      should_match_bills("On Friday the Second Reading of the Children and Young Persons Bill", "Children and Young Persons Bill")
    end
  
    it 'should not match "One other Bill"' do 
      should_not_match("One other Bill")
    end
  
    it 'should not match "One Bill"' do 
      should_not_match("One Bill")
    end  

    it 'should match "Parliament Bill No. 2" in "Opposition Front Bench for the Parliament Bill No. 2"' do 
      should_match_bills("Opposition Front Bench for the Parliament Bill No. 2", "Parliament Bill No. 2")
    end
  
    it 'should match "Unfair Contract Terms Bill" in "Opposition in the Unfair Contract Terms Bill"' do 
      should_match_bills("Opposition in the Unfair Contract Terms Bill", "Unfair Contract Terms Bill")
    end
  
    it 'should match "Criminal Justice and Public Order Bill" in "Opposition to the Criminal Justice and Public Order Bill"' do 
      should_match_bills("Opposition to the Criminal Justice and Public Order Bill", "Criminal Justice and Public Order Bill")
    end
  
    it 'should not match "Opposition\'s National Superannuation Bill"' do 
      should_not_match("Opposition's National Superannuation Bill")
    end
  
    it 'should match "Seeds Bill" in "Order for the Seeds Bill"' do 
      should_match_bills("Order for the Seeds Bill", "Seeds Bill")
    end
  
    it 'should match "Real Estates Settlements Bill" in "Order for the Second Reading of the Real Estates Settlements Bill"' do 
      should_match_bills("Order for the Second Reading of the Real Estates Settlements Bill", "Real Estates Settlements Bill")
    end

    it 'should match "Scotch Whisky Bill" in "Order of Commitment for the Scotch Whisky Bill"' do 
      should_match_bills("Order of Commitment for the Scotch Whisky Bill", "Scotch Whisky Bill")
    end

    it 'should match "Municipal Corporations Act Amendment Bill" in "Order of the Municipal Corporations Act Amendment Bill"' do 
      should_match_bills("Order of the Municipal Corporations Act Amendment Bill", "Municipal Corporations Act Amendment Bill")
    end

    it 'should match "Commonwealth Immigrants Bill No. 2" in "Order Paper the Commonwealth Immigrants Bill No. 2"' do 
      should_match_bills("Order Paper the Commonwealth Immigrants Bill No. 2", "Commonwealth Immigrants Bill No. 2")
    end
  
    it 'should match "Dublin Corporation Bill" in "Ordered, That the Dublin Corporation Bill"' do 
      should_match_bills("Ordered, That the Dublin Corporation Bill", "Dublin Corporation Bill")
    end

    it 'should match "Channel Tunnel Railway Bill" in "Orders for the Channel Tunnel Railway Bill"' do 
      should_match_bills("Orders for the Channel Tunnel Railway Bill", "Channel Tunnel Railway Bill")
    end
  
    it 'should not match "Orders for Trust Companies Bill"' do 
      should_not_match("Orders for Trust Companies Bill")
    end
  
    it 'should match "Refreshment Houses and Wine Licences Bill" in "Order of the Day for the Consideration of the Refreshment Houses and Wine Licences Bill"' do 
      should_match_bills("Order of the Day for the Consideration of the Refreshment Houses and Wine Licences Bill", "Refreshment Houses and Wine Licences Bill")
    end
  
    it 'should match "Iron and Steel Bill" in "Orders of the Day the Iron and Steel Bill"' do 
      should_match_bills("Orders of the Day the Iron and Steel Bill", "Iron and Steel Bill")
    end
    
    it 'should not match "Our Finance Bill"' do 
      should_not_match("Our Finance Bill")
    end

    it 'should not match "Original Bill"' do 
      should_not_match("Original Bill")
    end
  
    it 'should not match "Original Motion and Bill"' do 
      should_not_match("Original Motion and Bill")
    end

    it 'should match "Naval Works Bill" in "Paper to the Naval Works Bill"' do 
      should_match_bills("Paper to the Naval Works Bill", "Naval Works Bill")
    end

    it 'should not match "Paper, Technical Education (Ireland) Bill"' do 
      should_not_match("Paper, Technical Education (Ireland) Bill")
    end

    it 'should match "Brentford Gas Bill" in "Paper (the Brentford Gas Bill"' do 
      should_match_bills("Paper (the Brentford Gas Bill", "Brentford Gas Bill")
    end

    it 'should match "Australia and New Zealand Banking Group Bill" in "Procedure Act) the Promoters of the Australia and New Zealand Banking Group Bill"' do 
      should_match_bills("Procedure Act) the Promoters of the Australia and New Zealand Banking Group Bill", "Australia and New Zealand Banking Group Bill")
    end

    it 'should not match "Parliamentary Under-Secretary of State for Foreign and Commonwealth Affairs, Mr Bill"' do 
      should_not_match("Parliamentary Under-Secretary of State for Foreign and Commonwealth Affairs, Mr Bill")
    end

    it 'should match "Air Force Bill" in "Part II of the Air Force Bill"' do 
      should_match_bills("Part II of the Air Force Bill", "Air Force Bill")
    end

    it 'should match "Coal Bill" in "Part of the Coal Bill"' do 
      should_match_bills("Part of the Coal Bill", "Coal Bill")
    end

    it 'should match "Housing Bill" in "Parts of the Housing Bill"' do 
      should_match_bills("Parts of the Housing Bill", "Housing Bill")
    end
    
    it 'should not match "Petition, and Bill"' do 
      should_not_match("Petition, and Bill")
    end
  
    it 'should match "AGRICULTURAL HOLDINGS (ENGLAND) BILL" in "PASSING OF THE AGRICULTURAL HOLDINGS (ENGLAND) BILL"' do 
      should_match_bills("PASSING OF THE AGRICULTURAL HOLDINGS (ENGLAND) BILL", "AGRICULTURAL HOLDINGS (ENGLAND) BILL")
    end

    it 'should match "Alexandra Park Bill" in "Petition for the Alexandra Park Bill"' do 
      should_match_bills("Petition for the Alexandra Park Bill", "Alexandra Park Bill")
    end
  
    it 'should match "TRIAL BY BATTLE BILL" in "PETITION FROM LONDON AGAINST THE TRIAL BY BATTLE BILL"' do 
      should_match_bills("PETITION FROM LONDON AGAINST THE TRIAL BY BATTLE BILL", "TRIAL BY BATTLE BILL")
    end
  
    it 'should match "CORN BILL" in "PETITIONS AGAINST THE CORN BILL"' do 
      should_match_bills("PETITIONS AGAINST THE CORN BILL", "CORN BILL")
    end
  
    it 'should match "PETITIONS OF RIGHT (IRELAND) BILL" in "PETITIONS OF RIGHT (IRELAND) BILL"' do 
      should_match_bills("PETITIONS OF RIGHT (IRELAND) BILL", "PETITIONS OF RIGHT (IRELAND) BILL")
    end

    it 'should match "Irish Church Disestablishment Bill" in "Preamble of the Irish Church Disestablishment Bill"' do 
      should_match_bills("Preamble of the Irish Church Disestablishment Bill", "Irish Church Disestablishment Bill")
    end
  
    it 'should match "Parliament Bill No. 2" in "Preamble to the Parliament Bill No. 2"' do 
      should_match_bills("Preamble to the Parliament Bill No. 2", "Parliament Bill No. 2")
    end
  
    it 'should match "Coal Mines Bill" in "President of the Board of Trade in the Coal Mines Bill"' do 
      should_match_bills("President of the Board of Trade in the Coal Mines Bill", "Coal Mines Bill")
    end
  
    it 'should match "Government Bill" in "President of the Board of Trade, When the Government Bill"' do 
      should_not_match("President of the Board of Trade, When the Government Bill")
    end

    it 'should match "Old Age Pensions Bill" in "Prime Minister, to the Old Age Pensions Bill"' do 
      should_match_bills("Prime Minister, to the Old Age Pensions Bill", "Old Age Pensions Bill")
    end
  
    it 'should not match "Private Members\' Bill"' do 
      should_not_match("Private Members' Bill")
    end
    
    it 'should not match "Private Members Bill"' do 
      should_not_match("Private Members Bill")
    end
  
    it 'should not match "Private Member\'s Pesticides Bill"' do 
      should_not_match("Private Member's Pesticides Bill")
    end
  
    it 'should not match "Private Member Bill"' do 
      should_not_match("Private Member Bill")
    end  
  
    it 'should match "Coal Mines Bill" in "Proceedings of the Coal Mines Bill"' do 
      should_match_bills("Proceedings of the Coal Mines Bill", "Coal Mines Bill")
    end
  
    it 'should match "Pensions Bill" in "Proposals in the Pensions Bill"' do 
      should_match_bills("Proposals in the Pensions Bill", "Pensions Bill")
    end
  
    it 'should match "WAR TAXES EXTENSION BILL" in "PROTEST AGAINST THE WAR TAXES EXTENSION BILL"' do 
      should_match_bills("PROTEST AGAINST THE WAR TAXES EXTENSION BILL", "WAR TAXES EXTENSION BILL")
    end

    it 'should match "CORN IMPORTATION BILL" in "PROTESTS AGAINST THE CORN IMPORTATION BILL"' do 
      should_match_bills("PROTESTS AGAINST THE CORN IMPORTATION BILL", "CORN IMPORTATION BILL")
    end
  
    it 'should match "Crime and Disorder Bill" in "Provisions in the Crime and Disorder Bill"' do 
      should_match_bills("Provisions in the Crime and Disorder Bill", "Crime and Disorder Bill")
    end  
  
    it 'should match "Government Ships Bill" in "Provisions of the Government Ships Bill"' do 
      should_match_bills("Provisions of the Government Ships Bill", "Government Ships Bill")
    end
  
    it 'should not match "Proviso in the English Bill"' do 
      should_not_match("Proviso in the English Bill")
    end
  
    it 'should not match "Public Bill"' do 
      should_not_match("Public Bill")
    end

    it 'should match "Hunting Bill" in "Queen\'s Speech the Hunting Bill"' do 
      should_match_bills("Queen's Speech the Hunting Bill", "Hunting Bill")
    end
  
    it 'should match "Overseas Territories Bill" in "Remaining Stages of the Overseas Territories Bill"' do 
      should_match_bills("Remaining Stages of the Overseas Territories Bill", "Overseas Territories Bill")
    end
  
    it 'should match "Teachers Superannuation (Scotland) Bill" in "Remaining Stages of the Teachers Superannuation (Scotland) Bill"' do 
      should_match_bills("Remaining Stages of the Teachers Superannuation (Scotland) Bill", "Teachers Superannuation (Scotland) Bill")
    end
  
    it 'should match "Repeal of the Relief Bill" in "Repeal of the Relief Bill"' do 
      should_match_bills("Repeal of the Relief Bill", "Repeal of the Relief Bill")
    end
  
    it 'should match "Electricity (Supply) Bill" in "Report and Third Readings of the Electricity (Supply) Bill"' do 
      should_match_bills("Report and Third Readings of the Electricity (Supply) Bill", "Electricity (Supply) Bill")
    end
  
    it 'should match "Scottish Education Bill" in "Report Stage and Third Reading of the Scottish Education Bill"' do 
      should_match_bills("Report Stage and Third Reading of the Scottish Education Bill", "Scottish Education Bill")
    end
  
    it 'should match "Appropriation Bill" in "Report Stage of the Appropriation Bill"' do 
      should_match_bills("Report Stage of the Appropriation Bill", "Appropriation Bill")
    end
  
    it 'should match "Money Bill" in "Resolution of the Money Bill"' do 
      should_match_bills("Resolution of the Money Bill", "Money Bill")
    end
  
    it 'should not match "Repealing Bill"' do 
      should_not_match("Repealing Bill")
    end  

    it 'should match "Finance Bill" in "Resolution to the Finance Bill"' do 
      should_match_bills("Resolution to the Finance Bill", "Finance Bill")
    end 
  
    it 'should match "Irish Light Railways Bill" in "Resolution for the Irish Light Railways Bill"' do 
      should_match_bills("Resolution for the Irish Light Railways Bill", "Irish Light Railways Bill")
    end
  
    it 'should match "Home Rule Bill" in "Royal Assent to the Home Rule Bill"' do 
      should_match_bills("Royal Assent to the Home Rule Bill", "Home Rule Bill")
    end
  
    it 'should match "Consolidated Fund Bill" in "Second and Third Beading of the Consolidated Fund Bill"' do 
      should_match_bills("Second and Third Beading of the Consolidated Fund Bill", "Consolidated Fund Bill")
    end
  
    it 'should not match "Second Bill"' do 
      should_not_match("Second Bill")
    end
  
    it 'should not match "Second Reading Coal Industry Bill"' do 
      should_not_match("Second Reading Coal Industry Bill")
    end
  
    it 'should match "Steel Bill" in "Second Readings of the Steel Bill"' do 
      should_match_bills("Second Readings of the Steel Bill", "Steel Bill")
    end
  
    it 'should match "Charges and Allegations Bill" in "Second Rending of the Charges and Allegations Bill"' do 
      should_match_bills("Second Rending of the Charges and Allegations Bill", "Charges and Allegations Bill")
    end

    it 'should not match "Second Resolution, and Bill"' do 
      should_not_match("Second Resolution, and Bill")
    end
    
    it 'should match "Scottish Home Rule Bill" in "Seconder of the Motion for the Second Reading of the Scottish Home Rule Bill"' do 
      should_match_bills("Seconder of the Motion for the Second Reading of the Scottish Home Rule Bill", "Scottish Home Rule Bill")
    end
  
    it 'should match "Housing and Building Control Bill" in "Secondly, in the Housing and Building Control Bill"' do 
      should_match_bills("Secondly, in the Housing and Building Control Bill", "Housing and Building Control Bill")
    end
  
    it 'should match "Bengal Tenancy Bill" in "Secretary of State for India, Whether the Bengal Tenancy Bill"' do 
      should_match_bills("Secretary of State for India, Whether the Bengal Tenancy Bill", "Bengal Tenancy Bill")
    end

    it 'should match "Industry Bill" in "Secretary of State for Industry in the Industry Bill"' do 
      should_match_bills("Secretary of State for Industry in the Industry Bill", "Industry Bill")
    end
  
    it 'should match "Energy Conservation Bill" in "Secretary of State for the Environment to the Energy Conservation Bill"' do 
      should_match_bills("Secretary of State for the Environment to the Energy Conservation Bill", "Energy Conservation Bill")
    end
  
    it 'should match "Boundaries Bill" in "Secretary of State for the Home Department, When the Boundaries Bill"' do 
      should_match_bills("Secretary of State for the Home Department, When the Boundaries Bill", "Boundaries Bill")
    end
  
    it 'should match "Nationalisation Bill" in "Secretary of State in the Nationalisation Bill"' do 
      should_match_bills("Secretary of State in the Nationalisation Bill", "Nationalisation Bill")
    end
  
    it 'should match "Scottish Bill" in "Secretary of State, in the Scottish Bill"' do 
      should_match_bills("Secretary of State, in the Scottish Bill", "Scottish Bill")
    end

    it 'should match "Fishing Boats Amendment Bill" in "Secretary to the Board of Trade, When the Fishing Boats Amendment Bill"' do 
      should_match_bills("Secretary to the Board of Trade, When the Fishing Boats Amendment Bill", "Fishing Boats Amendment Bill")
    end

    it 'should match "Ulster Canal Bill" in "Secretary to the Treasury, When the Ulster Canal Bill"' do 
      should_match_bills("Secretary to the Treasury, When the Ulster Canal Bill", "Ulster Canal Bill")
    end

    it 'should match "Dublin Police Bill" in "Section of the Dublin Police Bill"' do 
      should_match_bills("Section of the Dublin Police Bill", "Dublin Police Bill")
    end
  
    it 'should match "Thames Embankment Bill" in "Select Committee of the Thames Embankment Bill"' do 
      should_match_bills("Select Committee of the Thames Embankment Bill", "Thames Embankment Bill")
    end
  
    it 'should match "Herb and Ginger Beer Makers\' Licence Bill" in "Session, of the Herb and Ginger Beer Makers\' Licence Bill"' do 
      should_match_bills("Session, of the Herb and Ginger Beer Makers' Licence Bill", "Herb and Ginger Beer Makers' Licence Bill")
    end
  
    it 'should match "Eight Hours (Mines) Bill" in "Session to the Eight Hours (Mines) Bill"' do 
      should_match_bills("Session to the Eight Hours (Mines) Bill", "Eight Hours (Mines) Bill")
    end
  
    it 'should match "Sessions Bill" in "Sessions Bill"' do 
      should_match_bills("Sessions Bill", "Sessions Bill")
    end

    it 'should not match "Session and Bill"' do 
      should_not_match("Session and Bill")
    end
    
    it 'should not match "Session That Bill"' do 
      should_not_match("Session That Bill")
    end
  
    it 'should match "Local Government Bill" in "Statute Book the Local Government Bill"' do 
      should_match_bills("Statute Book the Local Government Bill", "Local Government Bill")
    end
  
    it 'should match "Finance Bill No. 2" in "Sub-section in the Finance Bill No. 2"' do 
      should_match_bills("Sub-section in the Finance Bill No. 2", "Finance Bill No. 2")
    end
  
    it 'should match "Criminal Justice Bill" in "Subject to Royal Assent of the Criminal Justice Bill"' do 
      should_match_bills("Subject to Royal Assent of the Criminal Justice Bill", "Criminal Justice Bill")
    end  
   
    it 'should not match "Table and Bill "' do 
      should_not_match("Table and Bill ")
    end
  
    it 'should not match "TABLE SHOWING THE FINANCIAL EFFECTS OF ADMINISTRATION OF JUSTICE (PENSIONS) BILL"' do 
      should_match_bills("TABLE SHOWING THE FINANCIAL EFFECTS OF ADMINISTRATION OF JUSTICE (PENSIONS) BILL", "FINANCIAL EFFECTS OF ADMINISTRATION OF JUSTICE (PENSIONS) BILL")
    end 
     
    it 'should match "Official Secrets Bill" in "Table of the House the Draft of the Official Secrets Bill"' do 
      should_match_bills("Table of the House the Draft of the Official Secrets Bill", "Official Secrets Bill")
    end

    it 'should not match "Table, and Bill"' do 
      should_not_match("Table, and Bill")
    end
    
    it 'should not match "That Amending Bill"' do 
      should_not_match("That Amending Bill")
    end  
  
    it 'should not match "That Bill "' do 
      should_not_match("That Bill ")
    end
  
    it 'should match "Scotland Bill" in "Therefore in the Scotland Bill"' do 
      should_match_bills("Therefore in the Scotland Bill", "Scotland Bill")
    end  
  
    it 'should match "Banking (Scotland) Bill" in "Third Pleading of the Banking (Scotland) Bill"' do 
      should_match_bills("Third Pleading of the Banking (Scotland) Bill", "Banking (Scotland) Bill")
    end
  
    it 'should match "Small Holdings and Allotments Bill" in "Third Reacting of the Small Holdings and Allotments Bill"' do 
      should_match_bills("Third Reacting of the Small Holdings and Allotments Bill", "Small Holdings and Allotments Bill")
    end
  
    it 'should match "Transport Bill" in "Third Reading to the Transport Bill"' do 
      should_match_bills("Third Reading to the Transport Bill", "Transport Bill")
    end
  
    it 'should match "Barclays Bank Bill" in "Third Readings of the Barclays Bank Bill"' do 
      should_match_bills("Third Readings of the Barclays Bank Bill", "Barclays Bank Bill")
    end
  
    it 'should match "Statute Law Revision Bill" in "Third Report of the Statute Law Revision Bill"' do 
      should_match_bills("Third Report of the Statute Law Revision Bill", "Statute Law Revision Bill")
    end

    it 'should match "India and Burma (Temporary and Miscellaneous Provisions) Bill" in "Third Sitting Day-Second Reading of the India and Burma (Temporary and Miscellaneous Provisions) Bill"' do 
      should_match_bills("Third Sitting Day-Second Reading of the India and Burma (Temporary and Miscellaneous Provisions) Bill", "India and Burma (Temporary and Miscellaneous Provisions) Bill")
    end
  
    it 'should not match "Then DEBTORS\' (IRELAND) BILL"' do 
      should_not_match("Then DEBTORS' (IRELAND) BILL")
    end
  
    it 'should not match "Third Order, Chancel Repairs Bill"' do 
      should_not_match("Third Order, Chancel Repairs Bill")
    end
  
    it 'should not match "Thursday, Coal Bill"' do 
      should_not_match("Thursday, Coal Bill")
    end

    it 'should not match "Tuesday, Forestry Bill"' do 
      should_not_match("Tuesday, Forestry Bill")
    end
  
    it 'should match "Berkshire Bill" in "Turning to the Berkshire Bill"' do 
      should_match_bills("Turning to the Berkshire Bill", "Berkshire Bill")
    end
  
    it 'should match "Defence Loans Bill" in "Ways and Means Resolution for the Defence Loans Bill"' do 
      should_match_bills("Ways and Means Resolution for the Defence Loans Bill", "Defence Loans Bill")
    end  
  
    it 'should match "Finance Bill" in "Ways and Means Resolutions for the Finance Bill"' do 
      should_match_bills("Ways and Means Resolutions for the Finance Bill", "Finance Bill")
    end
  
    it 'should match "Emergency Powers Bill" in "Vote Office the Emergency Powers Bill"' do 
      should_match_bills("Vote Office the Emergency Powers Bill", "Emergency Powers Bill")
    end

    it 'should not match "Under NHS Reform and Health Care Professions Bill"' do 
      should_not_match("Under NHS Reform and Health Care Professions Bill")
    end
  
    it 'should not match "White Paper Bill"' do 
      should_not_match("White Paper Bill")
    end
  
    it 'should not match "White Paper and Transport Bill"' do 
      should_not_match("White Paper and Transport Bill")
    end
  
    it 'should not match "Wednesday, Army and Air Force (Annual) Bill"' do 
      should_not_match("Wednesday, Army and Air Force (Annual) Bill")
    end
  
    it 'should match "Irish Land Bill" in "Wednesday for the Irish Land Bill"' do 
      should_match_bills("Wednesday for the Irish Land Bill", "Irish Land Bill")
    end
  
    it 'should match "UNDER SECRETARIES INDEMNITY BILL" in "UNDER SECRETARIES INDEMNITY BILL"' do 
      should_match_bills("UNDER SECRETARIES INDEMNITY BILL", "UNDER SECRETARIES INDEMNITY BILL")
    end
  
    it 'should match "Money Bill" in "Vote for the Money Bill"' do 
      should_match_bills("Vote for the Money Bill", "Money Bill")
    end
  
    it 'should match "Ways and Means Bill" in "Vote in the Ways and Means Bill"' do 
      should_match_bills("Vote in the Ways and Means Bill", "Ways and Means Bill")
    end

    it 'should not match ""VOTE ON DEATH PENALTY (ABOLITION) BILL' do 
      should_not_match("VOTE ON DEATH PENALTY (ABOLITION) BILL")
    end
  
    it 'should match "Finance Bill" in "Why in the Finance Bill"' do 
      should_match_bills("Why in the Finance Bill", "Finance Bill")
    end  
  
    it 'should match "Iron and Steel Bill" in "Time-table for the Iron and Steel Bill"' do 
      should_match_bills("Time-table for the Iron and Steel Bill", "Iron and Steel Bill")
    end

    it 'should match "Import Duties Bill" in "Time-Table Motion for the Import Duties Bill"' do 
      should_match_bills("Time-Table Motion for the Import Duties Bill", "Import Duties Bill")
    end
  
    it 'should not match "Your Bill"' do 
      should_not_match("Your Bill")
    end  

    it 'should not match "Your Consumer Arbitration Agreements Bill"' do 
      should_not_match("Your Consumer Arbitration Agreements Bill")
    end
  
    it 'should match "Ottawa Agreements Bill" in "Time Table Motion for the Ottawa Agreements Bill"' do 
      should_match_bills("Time Table Motion for the Ottawa Agreements Bill", "Ottawa Agreements Bill")
    end

    it 'should not match "Tony Blair and Bill"' do 
      should_not_match("Tony Blair and Bill")
    end
  
    it 'should not match "Tories\' Skin Bill"' do 
      should_not_match("Tories' Skin Bill")
    end
  
    it 'should not match "Tory Coal Bill"' do 
      should_not_match("Tory Coal Bill")
    end
  
    it 'should not match "Whole House, and Bill"' do 
      should_not_match("Whole House, and Bill")
    end

    it 'should not match "WHOLE HOUSE, BE REFERRED TO THE CHAIRMAN OF COMMITTEES, WITH RESPECT TO ALL OR ANY OF THE ORDERS SCHEDULED THERETO, TO BE DEALT WITH IN THE SAME MANNER AS AN UNOPPOSED LOCAL BILL"' do 
      should_not_match("WHOLE HOUSE, BE REFERRED TO THE CHAIRMAN OF COMMITTEES, WITH RESPECT TO ALL OR ANY OF THE ORDERS SCHEDULED THERETO, TO BE DEALT WITH IN THE SAME MANNER AS AN UNOPPOSED LOCAL BILL")
    end  
    
    it 'should match "Relief of Manufacturers Bill" in "Title of the Relief of Manufacturers Bill"' do 
      should_match_bills("Title of the Relief of Manufacturers Bill", "Relief of Manufacturers Bill")
    end
  
    it 'should match "COAL MINES (MINIMUM WAGE) ACT (1912) AMENDMENT BILL,"' do 
      should_match_bills("COAL MINES (MINIMUM WAGE) ACT (1912) AMENDMENT BILL,", "COAL MINES (MINIMUM WAGE) ACT (1912) AMENDMENT BILL")
    end
  
    it 'should match "Government of Ireland Bill" in "Financial Provisions of the Government of Ireland Bill"' do 
     should_match_bills("Financial Provisions of the Government of Ireland Bill", "Government of Ireland Bill")
    end
  
    it 'should match "Coal Bill" in "Financial Resolution for the Coal Bill"' do 
      should_match_bills("Financial Resolution for the Coal Bill", "Coal Bill")
    end
  
  end
  
  describe " when asked for Bill mention attributes" do

    before do
      @resolver = BillResolver.new("")
      @resolver.stub!(:each_reference).and_yield("A Bill", 0, 5)
    end

    it 'should get the title and number of each reference from the resolver' do
      @resolver.should_receive(:name_and_number).and_return(['', nil])
      @resolver.mention_attributes
    end

    it 'should return a hash of title, year, start position and end position for each reference' do
      @resolver.stub!(:name_and_number).and_return(["name", "2"])
      @resolver.mention_attributes.should == [{:name => "name",
                                               :number => "2",
                                               :start_position => 0,
                                               :end_position => 5}]
    end

  end

end

