require File.dirname(__FILE__) + '/../../spec_helper'

describe "_hansard_header partial" do

  before do
    @title = 'House of Commons'
    @date_text = 'Monday 8 February 1999'
    @sitting = HouseOfCommonsSitting.new
    @sitting.stub!(:title).and_return(@title)
    @sitting.stub!(:date_text).and_return(@date_text)
    @sitting.stub!(:date).and_return(Date.new(1999,2,8))
    @sitting.stub!(:start_column).and_return(1)
    @sitting.stub!(:start_image_src).and_return('S6CV0325P0I0008')
    @sitting.stub!(:text).and_return("<p><i>The House met at half-past Two o'clock</i></p>")
    @sitting.stub!(:id_hash).and_return(:year => 1999, :month=>'feb',:day => '08',:type=>'commons')
    assigns[:sitting] = @sitting
  end

  def do_render
    render "/partials/_hansard_header.haml"
  end

  it 'should show title as h1' do
    do_render
    response.should have_tag('h1.title', @title)
  end

  it 'should show date text in element with class "date"' do
    do_render
    response.should have_tag('.date', @date_text)
  end

  it "should show a link to 'edit this page'" do
    do_render
    response.should have_tag("a")
    response.should have_tag("a", 'edit this page')
  end

end
