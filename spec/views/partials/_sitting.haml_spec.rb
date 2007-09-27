require File.dirname(__FILE__) + '/../../spec_helper'

describe "_sitting.haml", " in general" do

  def do_render 
    render 'partials/_sitting.haml'
  end

  it "should not fail when passed a sitting with a bad date" do
    sitting = Sitting.new(:date => Date.new(982, 11, 16), :title => "test")
    @controller.template.stub!(:sitting).and_return(sitting)
    lambda{ do_render }.should_not raise_error 
  end
   
end
