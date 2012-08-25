require File.dirname(__FILE__) + '/../spec_helper'

describe "a class that acts as a sortable division" do

  before do
    self.class.send(:include, Acts::SortableDivision)
    self.class.acts_as_sortable_division
  end

  describe 'when calculating an alphanumeric title' do 
    
    def expect_alphanumeric_title title, alphanumeric_title
      stub!(:section_title).and_return(title)
      alphanumeric_section_title.should == alphanumeric_title
    end

    it 'should return "ADJOURNMENT (CHRISTMAS)." for a division with section title "ADJOURNMENT (CHRISTMAS)."' do 
      expect_alphanumeric_title "ADJOURNMENT (CHRISTMAS).", 'ADJOURNMENT (CHRISTMAS).'
    end
    
    it 'should return "BILL 18.] THIRD READING." for a division with section title "[BILL 18.] THIRD READING."' do 
      expect_alphanumeric_title "[BILL 18.] THIRD READING.", 'BILL 18.] THIRD READING.'
    end
    
    it 'should return "AIR PASSENGER DUTY" for a division with section title "14. AIR PASSENGER DUTY"' do 
      expect_alphanumeric_title "14. AIR PASSENGER DUTY", 'AIR PASSENGER DUTY'
    end
    
    it 'should return "CUSTOMS—CORN, GRAIN AND MEAL &c." for a division with section title "B.—CUSTOMS—CORN, GRAIN AND MEAL &c."' do 
      expect_alphanumeric_title "B.—CUSTOMS—CORN, GRAIN AND MEAL", 'CUSTOMS—CORN, GRAIN AND MEAL'
    end
    
    it 'should return "F111K AIRCRAFT CONTRACT" for a division with section title "F111K AIRCRAFT CONTRACT"' do 
      expect_alphanumeric_title "F111K AIRCRAFT CONTRACT", 'F111K AIRCRAFT CONTRACT'
    end
    
    it 'should return "AJOURNMENT" for a division with section title "Adjournment"' do 
      expect_alphanumeric_title "Adjournment", "ADJOURNMENT"
    end
    
  end
  
  describe "when calculating an index letter" do 

    def expect_letter title, letter
      stub!(:section_title).and_return(title)
      calculate_index_letter.should == letter
    end

    it 'should set the index letter to "A" for a division with section title "ADJOURNMENT (CHRISTMAS)."' do 
      expect_letter "ADJOURNMENT (CHRISTMAS).", 'A'
    end

    it 'should set the index letter to "B" for a division with section title "[BILL 18.] THIRD READING."' do 
      expect_letter "[BILL 18.] THIRD READING.", "B"
    end

    it 'should set the index letter to "I" for a division with section title ""21. INCOME TAX (CHARGE AND RATES FOR 2000&#x2013;01)' do 
      expect_letter "21. INCOME TAX (CHARGE AND RATES FOR 2000&#x2013;01)", 'I'
    end

    it 'should set the index letter to "A" for a division with section title "14. AIR PASSENGER DUTY "' do
      expect_letter "14. AIR PASSENGER DUTY", 'A'
    end 

    it 'should set the index letter to "A" for a division with section title "\'ARMY ESTIMATES, 1899–1900."' do
      expect_letter "'ARMY ESTIMATES, 1899–1900. ", 'A'
    end

    it 'should set the index letter to "A" for a division with section title "\' APPLICATIONS FOR REGISTRATION OF RENT"' do
      expect_letter "' APPLICATIONS FOR REGISTRATION OF RENT", 'A'
    end

    it 'should set the index letter to "C" for a division with section title "B.—CUSTOMS—CORN, GRAIN AND MEAL &c."' do
      expect_letter "B.—CUSTOMS—CORN, GRAIN AND MEAL &c.", 'C'
    end

    it 'should set the index letter to "G" for a division with section title "C. GENERAL"' do
      expect_letter "C. GENERAL", 'G'
    end

    it 'should set the index letter to "R" for a division with section title "103D RECONSIDERATION: LEGAL AID"' do
      expect_letter "103D RECONSIDERATION: LEGAL AID", 'R'
    end

    it 'should set the index letter to "E" for a division with section title "*ERRATUM: TRANSPORT BILL DIVISION "' do
      expect_letter "*ERRATUM: TRANSPORT BILL DIVISION ", 'E'
    end

    it 'should set the index letter to "O" for a division with section title "F.—OCCASIONAL LICENCES. "' do
      expect_letter "F.—OCCASIONAL LICENCES. ", 'O'
    end

    it 'should set the index letter to "F" for a division with section title "F111K AIRCRAFT CONTRACT"' do
      expect_letter "F111K AIRCRAFT CONTRACT", 'F'
    end

    it 'should set the index letter to "D" for a division with section title "II. DUCHY OF CORNWALL."' do
      expect_letter "II. DUCHY OF CORNWALL.", 'D'
    end

    it 'should set the index letter to "I" for a division with section title "I6–I9 EDUCATION"' do
      expect_letter "I6–I9 EDUCATION", 'I'
    end

    it 'should set the index letter to "S" for a division with section title "(No. 164.) SECOND READING."' do
      expect_letter "(No. 164.) SECOND READING.", 'S'
    end
    
  end

end
