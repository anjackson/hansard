require File.dirname(__FILE__) + '/../../spec_helper'

describe "sections/show.haml", " in general" do

  before do
    @section = mock_model(Section)
    @section.stub!(:title).and_return("section name")
    @controller.template.stub!(:render)
    @controller.template.stub!(:section_url)
    assigns[:section] = @section
  end
  
  def do_render
    render 'sections/show.haml'
  end
  
  it "should render the 'section' partial passing the section" do
    @controller.template.should_receive(:render).with(:partial => "section", :locals => {:section => @section})
    do_render
  end
  
end