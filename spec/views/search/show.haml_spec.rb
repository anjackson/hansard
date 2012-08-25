require File.dirname(__FILE__) + '/../../spec_helper'

describe "search/show.haml" do
  
  before do 
    @mickey_mouse = mock_model(Person, :name => "Mickey Mouse", :slug => "mickey-mouse")
    @john_wayne = mock_model(Person, :name => "John Wayne", :slug => "john-wayne")
    template.stub!(:will_paginate)
    template.stub!(:search_timeline)
    @search = mock_model(Search, :null_object => true,
                                 :date_match => nil, 
                                 :speaker_matches => [], 
                                 :show_facets_and_matches => true)
    assigns[:search] = @search
  end
  
  describe "in general" do

    before do
      template.stub!(:params).and_return(:controller => 'search', :action => 'show')
    end
  
    it 'should not have an "ol" with id "by-member-facet" when only one frequent speaker is found' do
      @search.stub!(:display_speaker_facets).and_return([[@mickey_mouse, 5]])
      render 'search/show.haml'
      response.should_not have_tag('ol#by-member-facet')
    end

    it 'should have an "ol" with id "by-member-facet" when more than one frequent speaker is found' do
      facets = [[@mickey_mouse, 5], [@john_wayne, 3]]
      @search.stub!(:display_speaker_facets).and_return(facets)
      @search.stub!(:speaker_facets).and_return(facets)
      @search.stub!(:speakers_to_display).and_return(2)
      render 'search/show.haml'
      response.should have_tag('ol#by-member-facet')
    end
  
    it 'should have a link to "/sittings/1910/feb/15" in a "div" with id "sitting-date-matches" and text "Sitting of 15 Feb 1910" when assigned a date hash {:year => 1910, :month => "feb", :day => 15, :resolution => :day}' do
      @search.stub!(:date_match).and_return({:year => 1910, :month => 'feb', :day => 15, :resolution => :day})
      render 'search/show.haml'
      response.should have_tag('div#sitting-date-matches a[href=/sittings/1910/feb/15]', :text => 'Sitting of 15 Feb 1910')
    end

    it 'should have a link to "/sittings/1910/feb" in a "div" with id "sitting-date-matches" and text "Sittings in Feb 1910" when assigned a date hash {:year => 1910, :month => "feb", :resolution => :month}' do
      @search.stub!(:date_match).and_return({:year => 1910, :month => 'feb', :resolution => :month})
      render 'search/show.haml'
      response.should have_tag('div#sitting-date-matches a[href=/sittings/1910/feb]', :text => 'Sittings in Feb 1910')
    end

    it 'should have a link to "/sittings/1910" in a "div" with id "sitting-date-matches" and text "Sittings in 1910" when assigned a date hash {:year => 1910, :resolution => :year}' do
       @search.stub!(:date_match).and_return({:year => 1910, :resolution => :year})
      render 'search/show.haml'
      response.should have_tag('div#sitting-date-matches a[href=/sittings/1910]', :text => 'Sittings in 1910')
    end

  end

  describe "when displaying member matches" do 

    before do
      template.stub!(:url_for)
    end

    it 'should have an id "speaker-matches" when at least one person match is found' do
      @search.stub!(:speaker_matches).and_return([@mickey_mouse, @john_wayne])
      render 'search/show.haml'
      response.should have_tag('#speaker-matches')
    end

    it 'should have an "a" with class "speaker-match" when a person match is found' do
      @search.stub!(:speaker_matches).and_return([@john_wayne])
      render 'search/show.haml'
      response.should have_tag('a.speaker-match')
    end
  
  end
end