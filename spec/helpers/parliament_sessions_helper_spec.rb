require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsHelper do
  fixtures :parliament_sessions

  it 'should create link text to series url correctly' do
    series_link('SIXTH').should have_tag('a', :text => "SIXTH")
  end

  it 'should create link url to series url correctly' do
    series_link('SIXTH').should have_tag('a[href="/parliament_sessions/sixth-series"]')
  end

  it 'should create link text to volume url correctly when session has a volume part number' do
    session = parliament_sessions(:commons_session)
    volume_link(session).should have_tag('a', :text => 'Volume 424 (Part 1)')
  end

  it 'should create link text to volume url correctly when session has no volume part number' do
    session = parliament_sessions(:lords_session)
    volume_link(session).should have_tag('a', :text => 'Volume 121')
  end
end
