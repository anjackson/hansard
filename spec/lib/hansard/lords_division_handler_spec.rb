require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::DivisionHandler do 
 
  before :all do
    self.class.send(:include, Hansard::LordsDivisionHandler)
  end
  
  describe 'when handling votes' do
  
    it 'should raise a DivisionParsingException for any exception raised' do 
      stub!(:handle_vote).and_raise('test exception')
      lambda{ handle_the_vote('', nil, nil, nil) }.should raise_error(Hansard::DivisionParsingException, 'test exception')
    end
    
  end
   
  describe 'when recognizing divisions' do

    def should_be_a_division text
      is_divided_text?(text).should be_true
    end

    it 'should recognize "Their Lordships divided: Contents, 3; Not-Contents, 3."' do
      should_be_a_division "Their Lordships divided: Contents, 3; Not-Contents, 3."
    end

    it 'should recognize "Their Lordships divided: Contents,"55; Not-Contents, 17"' do
      should_be_a_division %Q|Their Lordships divided: Contents,"55; Not-Contents, 17|
    end

    it 'should recognize "Their Lordships divided:&#x2014;Contents, 93; Not-Contents, 29."' do
      should_be_a_division "Their Lordships divided:&#x2014;Contents, 93; Not-Contents, 29."
    end

    it 'should recognize "Contents, 17; Not-Contents, 30."' do
      should_be_a_division "Contents, 17; Not-Contents, 30."
    end

    it 'should recognize "Their Lordships divided: Contents. 14; Not-Contents, 21."' do
      should_be_a_division "Their Lordships divided: Contents. 14; Not-Contents, 21."
    end

    it 'should recognize "On Question, ... Their Lordships divided:&#x2014;Contents, 4; Not-Contents, 34."' do
      should_be_a_division "On Question, whether the proposed new clause shall be here inserted&#x2014;Their Lordships divided:&#x2014;Contents, 4; Not-Contents, 34."
    end

    it 'should recognize "Their Lordships divided:&#x2014;Contents, 11; Not-Content; 30."' do
      should_be_a_division "Their Lordships divided:&#x2014;Contents, 11; Not-Content; 30."
    end
  end

  describe 'when recognizing division headers' do

    it 'should recognize "NOT-CONTENTS"' do
      is_not_contents?('NOT-CONTENTS').should be_true
      is_contents?('NOT-CONTENTS').should be_false
    end

    it 'should recognize "NOT CONTENTS"' do
      is_not_contents?('NOT CONTENTS').should be_true
      is_contents?('NOT CONTENTS').should be_false
    end

    it 'should recognize "NON-CONTENTS."' do
      is_not_contents?('NON-CONTENTS').should be_true
    end

    it 'should recognize "CONTENTS"' do
      is_contents?('CONTENTS').should be_true
      is_not_contents?('CONTENTS').should be_false
    end

    it 'should recognize "CONTETS"' do
      is_contents?('CONTETS').should be_true
      is_not_contents?('CONTETS').should be_false
    end

    it 'should recognize "CONTENT"' do
      is_contents?('CONTENT').should be_true
      is_not_contents?('CONTENT').should be_false
    end

  end

end