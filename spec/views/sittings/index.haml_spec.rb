require File.dirname(__FILE__) + '/../../spec_helper'

describe "sittings index.haml", " in general" do

  before do 
    @date = Date.today
    assigns[:date] = @date
    @start_date = Date.new(2004, 1, 1)
    @end_date = Date.new(2005, 1, 1)
    assigns[:resolution] = nil
    assigns[:timeline_resolution] = "timeline resolution"
  end
  
  def do_render
    render 'sittings/index.haml', :layout => 'application'
  end
  
  it 'should have an appropriate title for the resolution' do 
    @controller.template.should_receive(:resolution_title).and_return("a good title")
    do_render
    response.should have_tag('h1', :text => "a good title")
  end
  
  it 'should display the sittings if the resolution is :day' do
    assigns[:resolution] = :day
    assigns[:sittings] = []
    @controller.template.should_receive(:render).with(:partial => "partials/sitting", :collection => [])
    do_render
  end
  
  it 'should otherwise render a timeline for the resolution assigned in @timeline_resolution' do
    assigns[:resolution] = nil
    @controller.template.stub!(:timeline_options).and_return({})
    @controller.template.should_receive(:timeline).with(@date, "timeline resolution", {})
    do_render
  end

  it 'should display frequent section titles for the timeline resolution' do
    @controller.template.should_receive(:frequent_section_titles).with(@date, "timeline resolution")
    do_render
  end
  
  it 'should get all the sections for each frequent title' do
    @controller.template.should_receive(:frequent_section_titles).with(@date, "timeline resolution").and_yield("a title", @start_date, @end_date)    
    Section.should_receive(:find_by_title_in_interval).with("a title", @start_date, @end_date).and_return([])
    do_render
  end
  
  it 'should display the date of each section' do
    section = mock_model(Section)
    section.stub!(:date).and_return(@date)
    section.stub!(:year).and_return(@date.year)
    section.stub!(:first_member)
    @controller.template.should_receive(:section_url).with(section).and_return('http://test.url')
    @controller.template.should_receive(:frequent_section_titles).with(@date, "timeline resolution").and_yield("a title", @start_date, @end_date)    
    Section.should_receive(:find_by_title_in_interval).with("a title", @start_date, @end_date).and_return([section])
    do_render
  end
  
  it 'should get a list of occurrences for each section ' do 
    @controller.template.stub!(:frequent_section_titles).and_yield("a title", @start_date, @end_date)    
    @controller.template.should_receive(:section_occurrences).with("a title", @start_date, @end_date, "timeline resolution")
    do_render
  end
    
  it 'should, for each date and section list yielded from the occurrences for each section, display the frequent section links' do
    sections = ["section", "section"]
    @controller.template.stub!(:frequent_section_titles).and_yield("a title", @start_date, @end_date)    
    @controller.template.stub!(:section_occurrences).and_yield(@start_date, sections)
    @controller.template.should_receive(:frequent_section_links).with(sections)
    do_render
  end
  
end