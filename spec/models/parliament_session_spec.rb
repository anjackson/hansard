require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSession, 'the class' do
  fixtures :parliament_sessions

  after do
    ParliamentSession.delete_all
  end

  it 'should return monarchs for sessions in database' do
    monarchs = ParliamentSession.monarchs
    monarchs.include?('ELIZABETH II').should be_true
    monarchs.include?('GEORGE VI').should be_true
  end

  it 'should return series numbers for sessions in database' do
    series = ParliamentSession.series
    series.include?('SIXTH').should be_true
    series.include?('FIFTH').should be_true
  end

  it 'should return sessions in groups by volume in series numbers for a given series' do
    series_number = 'sixth'
    groups = ParliamentSession.sessions_in_groups_by_volume_in_series(series_number)
    groups[0][0].should == parliament_sessions(:commons_session)
  end

  it 'should return sessions in groups by year of the reign of a given monarch' do
    monarch_name = 'elizabeth_ii'
    groups = ParliamentSession.sessions_in_groups_by_year_of_the_reign(monarch_name)
    groups[0][0].should == parliament_sessions(:commons_session)
  end

  it 'should return sittings for a HouseOfCommonsSession based on a series, volume and part number' do
    series_number = 'sixth'
    volume_number = '424_1'
    session = HouseOfCommonsSession.find_volume(series_number, volume_number)
    session.should == parliament_sessions(:commons_session)
  end

  it 'should return sittings for a HouseOfLordsSession based on a series, volume number' do
    series_number = 'fifth'
    volume_number = '121'
    session = HouseOfLordsSession.find_volume(series_number, volume_number)
    session.should == parliament_sessions(:lords_session)
  end
end

describe ParliamentSession, 'when source_file_id is set' do
  it 'should be associated with source file' do
    session = ParliamentSession.new :source_file_id => 123
    session.save!

    source_file = mock_model(SourceFile)
    SourceFile.stub!(:find).and_return(source_file)
    session.source_file.should == source_file
    ParliamentSession.delete_all
  end
end

describe ParliamentSession, 'on creation' do
  it 'should populate volume_in_series_number when volume number is a roman numeral' do
    session = HouseOfCommonsSession.new :volume_in_series => '424'
    session.valid?.should be_true
    session.volume_in_series_number.should == 424
  end

  it 'should populate volume_in_series_number when volume number is an arabic numeral' do
    session = HouseOfLordsSession.new :volume_in_series => 'CXXI'
    session.valid?.should be_true
    session.volume_in_series_number.should == 121
  end
end

describe ParliamentSession, 'volume_in_series_to_i' do

  it 'should be able to convert a roman numeral volume_in_series string to an integer' do
    session = ParliamentSession.new :volume_in_series => 'CXXI'
    session.volume_in_series_to_i.should == 121
  end

  it 'should be able to convert an integer volume_in_series string to an integer' do
    session = ParliamentSession.new :volume_in_series => '121'
    session.volume_in_series_to_i.should == 121
  end

  it "should raise exception for a volume_in_series string that doesn't represent a number" do
    session = ParliamentSession.new :volume_in_series => 'ABC'
    lambda { session.volume_in_series_to_i }.should raise_error
  end

  it "should raise exception for a volume_in_series string that is nil" do
    session = ParliamentSession.new :volume_in_series => nil
    lambda { session.volume_in_series_to_i }.should raise_error
  end
end


describe HouseOfCommonsSession do
  it 'should return house as "Commons"' do
    session = HouseOfCommonsSession.new
    session.house.should == "Commons"
  end
end

describe HouseOfLordsSession do
  it 'should return house as "Lords"' do
    session = HouseOfLordsSession.new
    session.house.should == "Lords"
  end
end
