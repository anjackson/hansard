require File.dirname(__FILE__) + '/../../spec_helper'

describe "_sitting.haml", " in general" do

  before do
    @sitting = Sitting.new(:date => Date.new(982, 11, 16), :title => "test")
    series = mock_model(Series, :number => 4)
    volume = mock_model(Volume, :series => series, :number => 34)
    @sitting.stub!(:volume).and_return(volume)
  end

  def do_render
    render 'partials/_sitting.haml'
  end

  it "should not fail when passed a sitting with a bad date" do
    @sitting.stub!(:anchor).and_return 'sittings'
    @controller.template.stub!(:sitting).and_return(@sitting)
    lambda{ do_render }.should_not raise_error
  end

  it 'should contain an "h3" tag whose id is the sitting prefix of the sitting class' do
    @sitting.stub!(:anchor).and_return 'sittings'
    @controller.template.stub!(:sitting).and_return(@sitting)
    do_render
    response.should have_tag('h3[id=sittings]')
  end

end
