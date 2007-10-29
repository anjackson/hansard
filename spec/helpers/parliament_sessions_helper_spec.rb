require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsHelper do

  it 'should create link text to series url correctly' do
    series_link('SIXTH').should have_tag("a", :text => "SIXTH")
  end

  it 'should create link url to series url correctly' do
    series_link('SIXTH').should have_tag('a[href="/parliament_sessions/sixth-series"]')
  end
end
