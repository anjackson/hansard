require File.dirname(__FILE__) + '/../../lib/regexp_generator'
require File.dirname(__FILE__) + '/../spec_helper'

describe 'creating a regexp' do
  before do
    @pattern = 'pattern'
    @regexp = mock('regexp')
  end

  describe 'when using oniguruma' do
    it 'should return oniguruma regexp' do
      option = mock('option')
      encoding = mock('encoding')
      Hansard.stub!(:use_oniguruma).and_return true
      Oniguruma::ORegexp.should_receive(:new).with(@pattern, option, encoding).and_return @regexp
      regexp(@pattern, option, encoding).should == @regexp
    end
  end

  describe 'when not using oniguruma' do
    before do
      Hansard.stub!(:use_oniguruma).and_return false
    end
    it 'should return normal regexp' do
      regexp(@pattern).should == /#{@pattern}/
    end
    it 'should return normal regexp ignore case if option is "i"' do
      regexp(@pattern,'i').should == /#{@pattern}/i
    end
    it 'should raise exception if option specified is not "i"' do
      lambda { regexp(@pattern,'x') }.should raise_error(Exception)
    end
  end

  describe 'when using creating line regexp i' do
    it 'should call use regexp method' do
      should_receive(:regexp).with('\A' + @pattern + '\Z', 'i').and_return @regexp
      line_regexp_i(@pattern).should == @regexp
    end
  end
end

describe 'a correct text substitutor', :shared => true do
  it 'should globally replace in text' do
    ogsub!(@text, @regexp, @replacement).should == @global_replace
    @text.should == @global_replace
  end
  it 'should globally replace in result text' do
    ogsub(@text, @regexp, @replacement).should == @global_replace
    @text.should == 'some text some'
  end
  it 'should replace first in text' do
    osub!(@text, @regexp, @replacement).should == @first_instance_replace
    @text.should == @first_instance_replace
  end
end

describe 'doing a text substitution using regexp' do
  before do
    @text = 'some text some'
    @replacement = 'other'
    @global_replace = 'other text other'
    @first_instance_replace = 'other text some'
  end

  describe 'when not using oniguruma' do
    before do
      Hansard.stub!(:use_oniguruma).and_return false
      @regexp = /some/
    end

    it_should_behave_like 'a correct text substitutor'
  end
  describe 'when using oniguruma' do
    before do
      Hansard.stub!(:use_oniguruma).and_return true
      @regexp = Oniguruma::ORegexp.new('some')
    end

    it_should_behave_like 'a correct text substitutor'
  end
end