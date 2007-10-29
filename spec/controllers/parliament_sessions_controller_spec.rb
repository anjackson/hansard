require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsController do

  it "should map { :controller => 'parliament_sessions', :action => 'index' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'index' }
    route_for(params).should == '/parliament_sessions'
  end

  it "should map { :controller => 'parliament_sessions', :action => 'series_index', :series_number_series => 'sixth-series' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'series_index', :series_number_series => 'sixth-series' }
    route_for(params).should == "/parliament_sessions/sixth-series"
  end

  it "should map { :controller => 'parliament_sessions', :action => 'series_index', :series_number_series => 'elizabeth_ii' } to /parliament_sessions " do
    params = { :controller => 'parliament_sessions', :action => 'series_index', :series_number_series => 'elizabeth_ii' }
    route_for(params).should == "/parliament_sessions/elizabeth_ii"
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

  it 'should assign volumes in series_index action' do
    @series_number_series = 'sixth-series'
    @sessions_grouped_by_volume = [[]]

    ParliamentSession.should_receive(:sessions_in_groups_by_volume_in_series).
        with(@series_number_series).and_return(@sessions_grouped_by_volume)

    get 'series_index', :series_number_series => @series_number_series
    assigns[:sessions_grouped_by_volume_in_series].should == @sessions_grouped_by_volume
  end

end
