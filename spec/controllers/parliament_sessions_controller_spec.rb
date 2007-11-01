require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsController do

  it "should map { :controller => 'parliament_sessions', :action => 'index' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'index' }
    route_for(params).should == '/parliament_sessions'
  end

  it "should map { :controller => 'parliament_sessions', :action => 'series_index', :series_number => 'sixth' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'series_index', :series_number => 'sixth' }
    route_for(params).should == "/parliament_sessions/series/sixth"
  end

  it "should map { :controller => 'parliament_sessions', :action => 'volume_index', :series_number => 'sixth', :volume_number => '424_1' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'volume_index', :series_number => 'sixth', :volume_number => '424_1' }
    route_for(params).should == "/parliament_sessions/series/sixth/volume/424_1"
  end

  it "should map { :controller => 'parliament_sessions', :action => 'monarch_index', :monarch_name => 'elizabeth_ii' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'monarch_index', :monarch_name => 'elizabeth_ii' }
    route_for(params).should == "/parliament_sessions/monarch/elizabeth_ii"
  end

  it "should map { :controller => 'parliament_sessions', :action => 'years_of_reign_index', :monarch_name => 'elizabeth_ii', :years_of_reign => '1_and_2' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'years_of_reign_index', :monarch_name => 'elizabeth_ii', :years_of_reign => '1_and_2' }
    route_for(params).should == "/parliament_sessions/monarch/elizabeth_ii/years_of_reign/1_and_2"
  end

  it 'should assign series and monarchs in index action' do
    @series = []
    @monarchs = []
    ParliamentSession.stub!(:series).and_return(@series)
    ParliamentSession.stub!(:monarchs).and_return(@monarchs)
    get 'index'
    assigns[:series].should == @series
    assigns[:monarchs].should == @monarchs
  end

  it 'should assign sessions_in_groups_by_volume_in_series in series_index action' do
    @series_number = 'sixth'
    @sessions_grouped_by_volume = [[]]

    ParliamentSession.should_receive(:sessions_in_groups_by_volume_in_series).
        with(@series_number).and_return(@sessions_grouped_by_volume)

    get 'series_index', :series_number => @series_number
    assigns[:sessions_grouped_by_volume_in_series].should == @sessions_grouped_by_volume
  end

  it 'should assign sessions in volume_index action' do
    @series_number = 'sixth'
    @volume_number = '424_1'
    @commons_session = HouseOfCommonsSession.new
    @lords_session = HouseOfLordsSession.new

    HouseOfCommonsSession.should_receive(:find_volume).
        with(@series_number,@volume_number).and_return(@commons_session)
    HouseOfLordsSession.should_receive(:find_volume).
        with(@series_number,@volume_number).and_return(@lords_session)

    get 'volume_index', :series_number => @series_number, :volume_number => @volume_number
    assigns[:commons_session].should == @commons_session
    assigns[:lords_session].should == @lords_session
  end

  it 'should assign sessions in years_of_reign_index action' do
    @monarch_name = 'elizabeth_ii'
    @years_of_reign = '1_and_2'
    @commons_session = HouseOfCommonsSession.new
    @lords_session = HouseOfLordsSession.new

    HouseOfCommonsSession.should_receive(:find_by_monarch_and_reign).
        with(@monarch_name, @years_of_reign).and_return(@commons_session)
    HouseOfLordsSession.should_receive(:find_by_monarch_and_reign).
        with(@monarch_name, @years_of_reign).and_return(@lords_session)

    get 'years_of_reign_index', :monarch_name => @monarch_name, :years_of_reign => @years_of_reign
    assigns[:commons_session].should == @commons_session
    assigns[:lords_session].should == @lords_session
  end

  it 'should assign sessions_in_groups_by_year_of_the_reign in monarch_index action' do
    @monarch_name = 'elizabeth_ii'
    @sessions_grouped_by_year_of_reign = [[]]

    ParliamentSession.should_receive(:sessions_in_groups_by_year_of_the_reign).
        with(@monarch_name).and_return(@sessions_grouped_by_year_of_reign)

    get 'monarch_index', :monarch_name => @monarch_name
    assigns[:sessions_in_groups_by_year_of_the_reign].should == @sessions_grouped_by_year_of_reign
  end
end
