require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSession, 'the class' do
  fixtures :parliament_sessions

  after do
    ParliamentSession.delete_all
  end

  it 'should return series numbers for sessions in database' do
    series = ParliamentSession.series
    series.include?('SIXTH').should be_true
    series.include?('FIFTH').should be_true
  end

  it 'should return sessions grouped by volume in series numbers for a given series' do
    series_number_series = 'sixth-series'
    volumes = ParliamentSession.sessions_in_groups_by_volume_in_series(series_number_series)
    volumes[0][0].should == parliament_sessions(:commons_session)
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

describe ParliamentSession, 'volume_in_series_to_i' do

  it 'should be able to convert a roman numerial volume_in_series string to an integer' do
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
