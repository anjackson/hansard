require File.dirname(__FILE__) + '/../../spec_helper'

describe "sittings index.haml", " in general" do

  before do 
    @date = Date.today
    assigns[:date] = @date
    assigns[:resolution] = nil
    @controller.template.stub!(:lower_resolution).and_return "resolution"
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
  
  it 'should otherwise render a timeline for the next resolution down' do
    resolution = nil
    assigns[:resolution] = resolution
    @controller.template.stub!(:lower_resolution).and_return "resolution"
    @controller.template.should_receive(:timeline).with(@date, "resolution", {:num_years => 200, :first_of_month => false})
    do_render
  end

  it 'should display frequent section titles for the next resolution down' do
    @controller.template.should_receive(:frequent_section_titles).with(@date, "resolution")
    do_render
  end
  
  it 'should get all the sections for each frequent title' do
    @controller.template.should_receive(:frequent_section_titles).with(@date, "resolution").and_yield("a title", @start_date, @end_date)    
    Section.should_receive(:find_by_title_in_interval).with("a title", @start_date, @end_date).and_return([])
    do_render
  end
  
  it 'should display the date of each section with a link to the section url' do
    section = mock_model(Section)
    section.stub!(:date).and_return(@date)
    @controller.template.should_receive(:section_url).with(section).and_return('http://test.url')
    @controller.template.should_receive(:frequent_section_titles).with(@date, "resolution").and_yield("a title", @start_date, @end_date)    
    Section.should_receive(:find_by_title_in_interval).with("a title", @start_date, @end_date).and_return([section])
    do_render
  end
  
end