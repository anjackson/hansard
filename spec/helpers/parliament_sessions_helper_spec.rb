require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsHelper do
  fixtures :parliament_sessions

  it 'should create volumes in series title correctly' do
    volume_in_series_title('sixth-series').should == 'Volumes in Sixth Series, by number'
  end

  it 'should create link text to series url correctly' do
    series_link('SIXTH').should have_tag('a', :text => "Sixth Series")
  end

  it 'should create link text to monarch url correctly' do
    monarch_link('ELIZABETH II').should have_tag('a', :text => "Elizabeth II")
  end

  it 'should create link url to series url correctly' do
    series_link('SIXTH').should have_tag('a[href="/parliament_sessions/sixth-series"]')
  end

  it 'should create link text to volume url correctly when session is for Commons with a volume part number' do
    session = parliament_sessions(:commons_session)
    text = 'Volume 424 (Part 1), Commons, 19 July&#x2014;4 October 2004'
    volume_link(session).should  have_tag('a', :text => text)
  end

  it 'should create link text to volume url correctly when session is for Lords with a Roman numerial volume number' do
    session = parliament_sessions(:lords_session)
    text = 'Volume CXXI (121), Lords, Wednesday, 12th November, 1941, to Thursday, 19th February, 1942'
    volume_link(session).should have_tag('a', :text => text)
  end

end
