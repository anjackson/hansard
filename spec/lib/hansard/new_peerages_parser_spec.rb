require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::NewPeeragesParser do

  before do 
    @parser = Hansard::NewPeeragesParser.new 'test/path'
  end
  
  describe 'when parsing' do 
  
    it 'should parse the memberships' do 
      @parser.should_receive(:parse_memberships).and_return([])
      @parser.parse
    end
  
  end
  
  describe 'when getting memberships from rows' do 
    
    it 'should not return a membership that starts after the last date covered by the application' do 
      @parser.stub!(:strings_from_row).and_return(['',''])
      @parser.stub!(:get_info_from_date_string).and_return({:start_date => LAST_DATE + 1})
      @parser.membership_from_row('').should be_nil
    end
    
    it 'should not return a membership that does not have a date of death' do 
      @parser.stub!(:strings_from_row).and_return(['',''])
      @parser.stub!(:get_info_from_date_string).and_return({:start_date => LAST_DATE - 1})
      @parser.stub!(:get_info_from_peerage_string).and_return({})
      @parser.membership_from_row('').should be_nil
    end
    
    it 'should  return a membership that has a date of death and is in the date range covered by the application' do 
      @parser.stub!(:strings_from_row).and_return(['',''])
      @parser.stub!(:get_info_from_date_string).and_return({:start_date => LAST_DATE - 1})
      @parser.stub!(:get_info_from_peerage_string).and_return({:date_of_death => Date.new(2004, 1, 1)})
      @parser.membership_from_row('').should_not be_nil
    end
  end
  
  describe 'when getting information from a peerage cell' do 
    
    def expect_degree(peerage_string, degree) 
      @parser.get_info_from_peerage_string(peerage_string)[:degree].should == degree
    end
    
    def expect_title(peerage_string, title) 
      @parser.get_info_from_peerage_string(peerage_string)[:title].should == title
    end
    
    def expect_firstname(peerage_string, firstname) 
      @parser.get_info_from_peerage_string(peerage_string)[:firstname].should == firstname
    end
    
    def expect_firstnames(peerage_string, firstnames) 
      @parser.get_info_from_peerage_string(peerage_string)[:firstnames].should == firstnames
    end
    
    def expect_lastname(peerage_string, lastname)
      @parser.get_info_from_peerage_string(peerage_string)[:lastname].should == lastname
    end
    
    def expect_date_of_death(peerage_string, date_of_death)
      @parser.get_info_from_peerage_string(peerage_string)[:date_of_death].should == date_of_death
    end
    
    it 'should get a degree of "Lord" from "L. <b>Gordon of Drumearn</b> in the County of Stirling &#8211; Edward Strathearn <i>Gordon</i> (died 21 Aug 1879)"' do 
      expect_degree("L. <b>Gordon of Drumearn</b> in the County of Stirling &#8211; Edward Strathearn <i>Gordon</i> (died 21 Aug 1879)", 'Baron')
    end
    
    it 'should get a degree of "Duke" from "D. of <b>Albany</b> (&amp; L. <b>Arklow</b> &amp; E. of <b>Clarence</b>) &#8211; Leopold George Duncan Albert (died 28 March 1884, extinct(2) 28 March 1919)"' do 
      expect_degree("D. of <b>Albany</b> (&amp; L. <b>Arklow</b> &amp; E. of <b>Clarence</b>) &#8211; Leopold George Duncan Albert (died 28 March 1884, extinct(2) 28 March 1919)", 'Duke')
    end
  
    it 'should get a degree of "Duchess" from "Dss of <b>Inverness</b> &#8211; Cecilia Letitia <i>Underwood</i> (extinct(1) 1 Aug 1873)"' do 
      expect_degree("Dss of <b>Inverness</b> &#8211; Cecilia Letitia <i>Underwood</i> (extinct(1) 1 Aug 1873)", 'Duchess')
    end
  
    it 'should get a degree of "Marquess" from M. of <b>Dalhousie</b> of Dalhousie Castle in the County of Edinburgh and of the Punjaub &#8211; James Andrew <i>Ramsay</i> (10th E. of Dalhousie (S)) (extinct(1) 22 Dec 1860)""' do 
      expect_degree("M. of <b>Dalhousie</b> of Dalhousie Castle in the County of Edinburgh and of the Punjaub &#8211; James Andrew <i>Ramsay</i> (10th E. of Dalhousie (S)) (extinct(1) 22 Dec 1860)", 'Marquess')
    end
    
    it 'should get a degree of "Earl" from "E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)"' do 
      expect_degree("E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)", 'Earl')
    end
    
    it 'should get a degree of "Countess" from "C. <b>De Grey</b> of Wrest in the County of Bedford (<A HREF="peeragesr.htm#18161025">special remainder</A>) &#8211; Amabell <i>Hume-Campbell</i> (B. Lucas) (died 4 May 1833, extinct(4) 22 Sep 1923)"' do 
      expect_degree('C. <b>De Grey</b> of Wrest in the County of Bedford (<A HREF="peeragesr.htm#18161025">special remainder</A>) &#8211; Amabell <i>Hume-Campbell</i> (B. Lucas) (died 4 May 1833, extinct(4) 22 Sep 1923)', 'Countess')
    end
    
    it 'should get a degree of "Viscount" from "V. <b>Exmouth</b> of Canonteign in the County of Devon &#8211; Edward <i>Pellew</i> (1st L. Exmouth) (died 23 Jan 1833)"' do 
      expect_degree("V. <b>Exmouth</b> of Canonteign in the County of Devon &#8211; Edward <i>Pellew</i> (1st L. Exmouth) (died 23 Jan 1833)", 'Viscount')
    end
  
    it 'should get a degree of "Viscountess" from "Vss <b>Canning</b> of Kilbrahan in the County of Kilkenny (<A HREF="peeragesr.htm#182801224">special remainder</A>) &#8211; Joan <i>Canning</i> (died 15 March 1837, extinct(2) 17 June 1862)"' do 
      expect_degree('Vss <b>Canning</b> of Kilbrahan in the County of Kilkenny (<A HREF="peeragesr.htm#182801224">special remainder</A>) &#8211; Joan <i>Canning</i> (died 15 March 1837, extinct(2) 17 June 1862)', 'Viscountess')
    end
 
    it 'should get a degree of "Baroness" from "B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)"' do 
      expect_degree("B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)", 'Baroness')
    end
    
    it 'should get a title of "Wenman" from "B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)"' do 
      expect_title("B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)", 'Wenman')
    end
    
    it 'should get a title of "Powis" from "E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)"' do 
      expect_title("E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)", 'Powis')
    end
    
    it 'should get a firstname "Edward" from "E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)"' do 
      expect_firstname("E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)", 'Edward')
    end
    
    it 'should get a lastname "Clive" from "E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (1st L. Clive) (died 16 May 1839)"' do 
      expect_lastname("E. of <b>Powis</b> in the County of Montgomery (&amp; V. <b>Clive</b> of Ludlow in the County of Salop &amp; L. <b>Herbert</b> of Chirbury in the County of Salop &amp; L. <b>Powis</b> of Powis Castle in the County of Montgomery) &#8211; Edward <i>Clive</i> (died 16 May 1839)", 'Clive')
    end
    
    it 'should get firstnames of "Sophia Elizabeth" from "B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)"' do 
      expect_firstnames("B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)", 'Sophia Elizabeth')
    end
    
    it 'should get date of death of "1870-08-09" from "B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)"' do 
      expect_date_of_death("B. <b>Wenman</b> of Thame Park and Swalcliffe in the County of Oxford &#8211; Sophia Elizabeth <i>Wykam</i> (extinct(1) 9 Aug 1870)", Date.new(1870, 8, 9))
    end   
   
    it 'should get date of death of "1925-03-02" from "B. <b>Dorchester</b> of Dorchester in the County of Oxford &#8211; Henrietta Anne <i>Carleton</i> (died 2 March 1925, extinct(2) 20 Jan 1963)"' do 
      expect_date_of_death("B. <b>Dorchester</b> of Dorchester in the County of Oxford &#8211; Henrietta Anne <i>Carleton</i> (died 2 March 1925, extinct(2) 20 Jan 1963)", Date.new(1925, 3, 2))
    end
   
    it 'should get firstnames of "Paul Bertrand" from "L. <b>Hamlyn</b> of Edgeworth in the County of Gloucestershire &#8211; Paul Bertrand <i>Hamlyn</i> (died 31 Aug 2001)"' do 
      expect_firstnames("L. <b>Hamlyn</b> of Edgeworth in the County of Gloucestershire &#8211; Paul Bertrand <i>Hamlyn</i> (died 31 Aug 2001)", 'Paul Bertrand')
    end
  
  end
  
  describe 'when handling a membership' do 
    
    before do 
      @membership = { :date_of_death => Date.new(1977, 4, 1), 
                      :gender => 'M' }
      LordsMembership.stub!(:find_by_years_degree_and_title)
      @parser.stub!(:person_sits_in_lords?).and_return(true)
    end
    
    it 'should not try to match someone who has neither a date of birth nor a year of birth nor a date of death or year of death' do
      @membership[:date_of_death] = nil
      @parser.should_not_receive(:match_person)
      @parser.handle_membership(@membership)
    end
    
    it 'should try and match a person with a date of death' do 
      @parser.should_receive(:match_person)
      @parser.handle_membership(@membership)
    end
    
    describe 'when matching someone not entitled to sit in the Lords' do 
      
      before do 
        @parser.stub!(:person_sits_in_lords?).and_return(false)
      end
      
      it 'should not add a new person' do
        @parser.should_not_receive(:add_to_new_people)
        @parser.handle_membership(@membership)
      end
      
      it 'should not add a new membership' do 
        @parser.should_not_receive(:add_to_new_memberships)
        @parser.handle_membership(@membership)
      end

    end
    
    describe 'when matching someone entitled to sit in the Lords' do 
    
      before do 
        @parser.stub!(:person_sits_in_lords?).and_return(true)
      end
      
      it 'should add a new person' do
        @parser.should_receive(:add_to_new_people)
        @parser.handle_membership(@membership) 
      end
      
    end
    
    describe 'when the person is matched' do
      
      before do 
        @person = mock_model(Person, :import_id => 4)
        @parser.stub!(:match_person).and_return(@person)
      end
      
      it 'should add the new membership if the matched person has no existing Lords memberships' do 
        @person.stub!(:lords_memberships).and_return([])
        @parser.should_receive(:add_to_new_memberships)
        @parser.handle_membership(@membership)
      end
      
      it 'should add the new membership if the matched person has existing Lords memberships matching the new one' do 
        memberships = mock('memberships', :empty? => false)
        @person.stub!(:lords_memberships).and_return(memberships)
        memberships.stub!(:find_by_years_degree_and_title).and_return('moo')
        @parser.should_not_receive(:add_to_new_memberships)
        @parser.handle_membership(@membership)
      end
      
      it 'should set the person import id of the membership to the import id of the person' do 
        @person.stub!(:lords_memberships).and_return([])
        @parser.handle_membership(@membership)
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
        @parser.handle_membership(@membership)
      end
      
      it 'should not add the membership to the list of new people if the membership matches an existing membership' do 
        LordsMembership.stub!(:find_by_years_degree_and_title).and_return(mock_model(LordsMembership))
        @parser.should_not_receive(:add_to_new_people)
        @parser.handle_membership(@membership)
      end
      
    end
  end
  
  describe 'when getting the gender of a person from their degree' do 
  
    it 'should return "M" for a degree of "Baron"' do 
      @parser.gender_from_degree('Baron').should == 'M'
    end
    
    it 'should return "M" for a degree of "Duke"' do 
      @parser.gender_from_degree('Duke').should == 'M'
    end
    
    it 'should return "M" for a degree of "Marquess"' do 
      @parser.gender_from_degree('Marquess').should == 'M'
    end
    
    it 'should return "M" for a degree of "Earl"' do 
      @parser.gender_from_degree('Earl').should == 'M'
    end
    
    it 'should return "M" for a degree of "Viscount"' do 
      @parser.gender_from_degree('Viscount').should == 'M'
    end
    
    it 'should return "F" for a degree of "Duchess"' do 
      @parser.gender_from_degree('Duchess').should == 'F'
    end
    
    it 'should return "F" for a degree of "Marchioness"' do 
      @parser.gender_from_degree('Marchioness').should == 'F'
    end
    
    it 'should return "F" for a degree of "Countess"' do 
      @parser.gender_from_degree('Countess').should == 'F'
    end
    
    it 'should return "F" for a degree of "Viscountess"' do 
      @parser.gender_from_degree('Viscountess').should == 'F'
    end
    
    it 'should return "F" for a degree of "Baroness"' do 
      @parser.gender_from_degree('Baroness').should == 'F'
    end

  end
  
  describe 'when getting information from a date cell' do 
  
    def expect_start_date(date_string, date)
      @parser.get_info_from_date_string(date_string)[:start_date].should == date
    end
    
    def expect_peerage_type(date_string, peerage_type)
      @parser.get_info_from_date_string(date_string)[:peerage_type].should == peerage_type
    end
    
    it 'should get a start date from the string "17 Jan 1801 (H:I)"' do
      expect_start_date('17 Jan 1801 (H:I)', Date.new(1801, 1, 17))
    end
    
    it 'should get a start date from the string "30 June 1992 (a.m.) (L)"' do 
      expect_start_date('30 June 1992 (a.m.) (L)', Date.new(1992, 6, 30))
    end
    
    it 'should get a peerage type of "Hereditary" from "17 Jan 1801 (H:I)"' do 
      expect_peerage_type("17 Jan 1801 (H:I)", 'Hereditary')
    end
    
    it 'should get a peerage type of "Life peer" from "30 June 1992 (a.m.) (L)"' do 
      expect_peerage_type("30 June 1992 (a.m.) (L)", 'Life peer')
    end
    
    it 'should get a peerage type of "Hereditary" from "28 Nov 1815 (P)"' do 
      expect_peerage_type("28 Nov 1815 (P)", 'Hereditary')
    end
    
    it 'should get a peerage type of "Hereditary" from "16 Jan 1816 (X)"' do 
      expect_peerage_type("16 Jan 1816 (X)", 'Hereditary')
    end
  
    it 'should get a peerage type of "Life peer" from "16 Oct 1876 (A)"' do 
      expect_peerage_type("16 Oct 1876 (A)", 'Life peer')
    end
      
    it 'should get a peerage type of "Hereditary" from "16 Oct 1876 (H)"' do 
      expect_peerage_type("16 Oct 1876 (H)", 'Hereditary')
    end  
    
    it 'should get a peerage type of "Hereditary" from "16 Oct 1876 (H:S)"' do 
      expect_peerage_type("16 Oct 1876 (H:S)", 'Hereditary')
    end
    
    it 'should get a peerage type of "Life peer" from "16 Oct 1876 (L:H)"' do 
      expect_peerage_type("16 Oct 1876 (L:H)", 'Life peer')
    end
  
  end
  
  
end 
