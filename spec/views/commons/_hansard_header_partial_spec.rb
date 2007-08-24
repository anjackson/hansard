require File.dirname(__FILE__) + '/../../spec_helper'

describe "_hansard_header partial" do

  before do
    @title = 'House of Commons'
    @date_text = 'Monday 8 February 1999'

    @sitting = mock_model(HouseOfCommonsSitting)
    @sitting.stub!(:markers)
    @sitting.stub!(:title).and_return(@title)
    @sitting.stub!(:date_text).and_return(@date_text)
    @sitting.stub!(:date).and_return(Date.new(1999,2,8))
    @sitting.stub!(:start_column).and_return(1)
    @sitting.stub!(:start_image_src).and_return('S6CV0325P0I0008')
    @sitting.stub!(:text).and_return("<p><i>The House met at half-past Two o'clock</i></p>")
    assigns[:sitting] = @sitting


  end
  
  def do_render
    render "/commons/_hansard_header.haml"
  end

  it 'should show title as h1' do
    do_render
    response.should have_tag('h1.title', @title)
  end

  it 'should show date text as p' do
    do_render
    response.should have_tag('p.date', @date_text)
  end

  it 'should show date text as p' do
    do_render
    response.should have_tag('p', @text)
  end
  
  it "should ask the sitting assigned to it for it's marker html" do
    @controller.template.should_receive(:marker_html).and_return("")
    do_render
  end

end
