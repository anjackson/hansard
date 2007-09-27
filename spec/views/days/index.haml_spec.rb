require File.dirname(__FILE__) + '/../../spec_helper'

describe "index.haml" do
  
  before do
    @sitting = Sitting.new(:date => Date.new(2005, 4, 20))
    assigns[:sitting] = @sitting
  end
  
  def do_render
    render "days/index.haml"
  end
  
  it "should display a calendar for the month and year of the sitting passed to it" do
    @controller.template.should_receive(:calendar).with(:year => 2005, :month => 4)
    do_render
  end

end