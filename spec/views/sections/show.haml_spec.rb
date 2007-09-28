require File.dirname(__FILE__) + '/../../spec_helper'

describe "sections/show.haml", " in general" do

  before do
    @section = mock_model(Section)
    @section.stub!(:title).and_return("section name")
    assigns[:section] = @section
  end
  
  def do_render
    render 'sections/show.haml'
  end
  
  it "should render the 'section' partial passing the section" do
    @controller.template.should_receive(:render).with(:partial => "section", :locals => {:section => @section})
    do_render
  end

  it "should have a link to the next section if there is one"
  it "should have a link to the previous section if there is one"
  
end