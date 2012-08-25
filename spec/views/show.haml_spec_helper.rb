require File.dirname(__FILE__) + '/../spec_helper'

describe "show.haml for a sitting type", :shared => true do

  before do
    @sitting = mock_model(Sitting, :anchor => 'sitting', :all_sections => ['a section'])
    assigns[:sitting_type] = Sitting
    assigns[:date] = Date.new(2004, 1, 2)
    assigns[:day] = true
    @controller.template.stub!(:render)
    assigns[:sittings] = [@sitting]
  end

  def do_render
    render "sittings/show.haml", :layout => "application"
  end

  it 'should return an unordered list of links to anchors made of the sitting uri component' do
    assigns[:sittings] = [@sitting, @sitting]
    @controller.template.should_receive(:link_to_sitting_anchor).with(assigns[:sittings][0]).twice.and_return 'x'
    @controller.template.should_receive(:link_to_parliament_uk).with(assigns[:sittings][0]).twice.and_return ''
    do_render
    response.should have_tag('ul[class=jumplist] li[class=jumplist-item]', :text => "Skip to x" )
  end
  
  it 'should not show links to anchors if there are no sections in the sittings' do 
    @sitting = mock_model(Sitting, :anchor => 'sitting', :all_sections => [])
    assigns[:sittings] = [@sitting]
  end

  it "should render the 'partials/_sitting' partial, passing the sittings" do
    @controller.template.should_receive(:render).with(:partial => "partials/sitting", :collection => [@sitting])
    do_render
  end

  it "should give the message 'No information is available for this date.' if no information is available for that date" do
    assigns[:sittings] = []
    do_render
    response.should have_tag("div.no-sittings", :text => "No information is available for this date.")
  end

  it 'should show a link to the previous and next sitting day with content if no information is available for that date' do
    assigns[:sittings] = []
    @controller.template.should_receive(:day_navigation).with(assigns[:sitting_type], assigns[:date])
    do_render
  end

end
