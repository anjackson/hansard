require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsDivisionHandler do

  before :each do
    self.class.send(:include, Hansard::CommonsDivisionHandler)
  end
  
  describe 'when recognizing divisions' do
    
    def should_be_a_division text
      is_divided_text?(text).should be_true
    end

    it 'should recognize "The Houses divided: Ayes, 235; Noes, 118."' do
      should_be_a_division "The Houses divided: Ayes, 235; Noes, 118."
    end

    it 'should recognize "The House divided: Ayes, 235; Noes, 118."' do
      should_be_a_division "The House divided: Ayes, 235; Noes, 118."
    end

    it 'should recognize "The House having divided: Ayes 325, Noes 202."' do
      should_be_a_division "The House having divided: Ayes 325, Noes 202."
    end

    it 'should recognize "The Committee divided: Ayes 139, Noes 187."' do
      should_be_a_division "The Committee divided: Ayes 139, Noes 187."
    end

    it 'should recognize "The Committee divided:&#x2014;Aye, 162 Noes, 78. (Division List No. 205)."' do
      should_be_a_division "The Committee divided:&#x2014;Aye, 162 Noes, 78. (Division List No. 205)."
    end

    it 'should recognize "The House divided:&#x2014;Ayes, 149; Noes,. 38. (Division List No. 204.)"' do
      should_be_a_division "The House divided:&#x2014;Ayes, 149; Noes,. 38. (Division List No. 204.)"
    end

    it 'should recognize "The Committee divided: Ayes, 37; Noes, 217."' do
      should_be_a_division "The Committee divided: Ayes, 37; Noes, 217."
    end

    it 'should recognize "The Committee divided: Ayes, 0;Noes, 122."' do
      should_be_a_division "The Committee divided: Ayes, 0;Noes, 122."
    end

    it %Q|should recognize "The 'Committee divided: Ayes, 262; Noes, 37."| do
      should_be_a_division "The 'Committee divided: Ayes, 262; Noes, 37."
    end

    it 'should recognize "<i>The House divided:</i> Ayes 60, Noes 7."' do
      should_be_a_division '<i>The House divided:</i> Ayes 60, Noes 7.'
    end

    it 'should recognize "The <i>Committee divided:</i> Ayes 227, Noes 184."' do
      should_be_a_division 'The <i>Committee divided:</i> Ayes 227, Noes 184.'
    end

    it 'should recognize "<i>The House dividend</i>: Ayes 314, Noes 253"' do
      should_be_a_division '<i>The House dividend</i>: Ayes 314, Noes 253'
    end

    it 'should recognize "<i>Question put,</i> That those words be there inserted:&#x2014;<i>The Committee deveded:</i> Ayes 184, Noes 237."' do
      should_be_a_division  '<i>Question put,</i> That those words be there inserted:&#x2014;<i>The Committee deveded:</i> Ayes 184, Noes 237.'
    end

    it 'should recognize "The House divided: Ayes, 256; Noes,"' do
      should_be_a_division 'The House divided: Ayes, 256; Noes,'
    end
    
  end

  describe 'when handling division votes' do

    it 'should not create a vote if the member name is "NIL."' do
      division = mock_model(Division)
      vote_type = mock_model(AyeVote)
      vote_type.should_not_receive(:new)
      division.should_not_receive(:votes)
      handle_vote "NIL.", division, AyeVote, nil
    end

    it 'should recognize a nil vote' do
      is_nil_name?("NIL.").should be_true
    end

    it 'should handle Noe Teller heading and teller names in same cell, with "and" incorrectly recorded as "arid"' do
      tellers = %Q|Mr. Maxton arid Mr. McGovern|
      text = "TELLERS FOR THE NOES&#x2014; #{tellers}."
      division = mock('division')
      should_receive(:handle_vote).with(tellers, division, NoeTellerVote, nil)
      handle_the_vote(text, mock('cell'), division, mock('last_column_cells'))
    end

    it 'should handle Aye Teller heading and teller names in same cell, with "and" incorrectly recorded as "arid"' do
      tellers = %Q|Mr. Maxton arid Mr. McGovern|
      text = "TELLERS FOR THE AYES&#x2014; #{tellers}."
      division = mock('division')
      should_receive(:handle_vote).with(tellers, division, AyeTellerVote, nil)
      handle_the_vote(text, mock('cell'), division, mock('last_column_cells'))
    end

    it 'should not recognize "." as a teller name' do
      text = "TELLERS FOR THE AYES.&#x2014;"
      should_not_receive(:handle_vote)
      handle_the_vote(text, mock('cell'), mock('division'), mock('last_column_cells'))
    end

    it 'should not recognize "Mr." as a teller name' do
      text = "TELLERS FOR THE NOES, Mr."
      should_not_receive(:handle_vote)
      handle_the_vote(text, mock('cell'), mock('division'), mock('last_column_cells'))
    end
  end

  describe 'when recognizing tellers' do
  
    it 'should recognize when space has been incorrectly scanned as a single quote char' do
      is_noes_teller?("TELLERS FOR'THE NOES").should be_true
      is_ayes_teller?("TELLERS FOR'THE AYES").should be_true
    end

    it 'should recognize tellers with catastrophic mispelling of "the"' do
      is_ayes_teller?("TELLERS FOR TI-LE AYES:").should be_true
    end
    
  end
  
  describe 'when recognizing aye text' do 
  
    it 'should recognize "AYES"' do 
      is_ayes?("AYES").should be_true
    end
    
    it 'should recognize AVES.' do 
      is_ayes?("AVES").should be_true
    end
    
    it 'should not recognize ""' do 
      is_ayes?('').should be_false
    end
    
    it 'should not recognize "John Hayes"' do 
      is_ayes?("John Hayes").should be_false
    end
    
    it 'should recognize "AYES?"' do 
      is_ayes?("AYES?").should be_true
    end
     
  end
  
  describe 'when handling votes' do 
    
    it 'should raise a DivisionParsingException for any exception raised' do 
      stub!(:handle_vote).and_raise('test exception')
      lambda{ handle_the_vote('', nil, nil, nil) }.should raise_error(Hansard::DivisionParsingException, 'test exception')
    end
    
  end
  
  describe 'when handling votes table cells that indicate a time' do

    before do
      @cell = ''
      @division = mock_model(Division, :time => nil)
      @last_column_cells = ''
    end
    
    it 'should set the division time if given a text of "[7 pm" ' do
      text = '[7 pm'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end

    it 'should set the division time if given a text of "[7.00pm"' do
      text = '[7.00pm'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end
    
    it 'should set the division time if given a text of "[7.pm"' do 
      text = '[7.pm'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end
    
    it 'should set the division time if given a text of "[4:50 PM"' do 
      text = '[4:50 PM'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end
    
    it 'should set the division time if given a text of "[12 noon"' do 
      text = '[12 noon'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end
    
    it 'should set the division time if given a text of "[10.05"' do 
      text = '[10.05'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end

    it 'should set the division time if given a text of "[4:30"' do 
      text = '[4:30'
      @division.should_receive(:time=)
      handle_the_vote(text, @cell, @division, @last_column_cells)
    end
  end
  
  
end


