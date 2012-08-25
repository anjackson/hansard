require File.dirname(__FILE__) + '/../spec_helper'


describe CommonsWrittenAnswersSitting do

  it 'should have "Commons" as house' do
    CommonsWrittenAnswersSitting.house.should == 'Commons'
  end

  describe 'creating hansard reference' do
    before do
      @sitting = CommonsWrittenAnswersSitting.new(
                            :start_column    => "1",
                            :date            => Date.new(1985, 12, 16),
                            :date_text       => "Monday 16th December 1985",
                            :volume => mock_model(Volume, :number => 5))
    end

    it 'should create reference correctly' do
      @sitting.hansard_reference('1').should == 'HC Deb 16 December 1985 vol 5 c1W'
    end

    it 'should create reference correctly for column variant' do
      @sitting.start_column = "W 1"
      @sitting.hansard_reference(@sitting.start_column).should == 'HC Deb 16 December 1985 vol 5 c1W'
    end

    it 'should create reference correctly for column variant' do
      @sitting.hansard_reference("W 23", "W 24").should == 'HC Deb 16 December 1985 vol 5 cc23-4W'
    end

    it 'should create reference correctly for column variant' do
      @sitting.hansard_reference("W 23", "W24").should == 'HC Deb 16 December 1985 vol 5 cc23-4W'
    end

    it 'should create a reference correctly for a section with start column "444ee" and end column "444ff"' do
      @sitting.hansard_reference('444ee', '444ff').should == 'HC Deb 16 December 1985 vol 5 cc444ee-ff W'
    end

    it 'should create a reference correctly for a section with column "444ee"' do
      @sitting.hansard_reference('444ee').should == 'HC Deb 16 December 1985 vol 5 c444ee W'
    end
  end
end
