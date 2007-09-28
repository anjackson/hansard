require File.dirname(__FILE__) + '/../../spec_helper'

describe "sections/show.haml", " in general" do

  before do
    @section = mock_model(Section)
    @prev = mock_model(Section)
    @prev.stub!(:linkable?)
    @next = mock_model(Section)
    @next.stub!(:linkable?)    
    @section.stub!(:title).and_return("section name")
    @controller.template.stub!(:render)
    @section.stub!(:previous_section).and_return(@prev)
    @section.stub!(:next_section).and_return(@next)  
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

  it "should not have any text about the previous section if there isn't one" do
    @section.stub!(:previous_section).and_return(nil)
    do_render
    response.should_not have_tag("a.prev-section")
  end

  it "should not have any text about the next section if there isn't one" do
    @section.stub!(:next_section).and_return(nil)
    do_render
    response.should_not have_tag("a.next-section")
  end

  it "should not have any text about the previous section if it is not linkable" do
    @prev.stub!(:linkable?).and_return(false)
    do_render
    response.should_not have_tag("a.prev-section")
  end
  
  it "should not have any text about the next section if it is not linkable" do
    @next.stub!(:linkable?).and_return(false)
    do_render
    response.should_not have_tag("a.next-section")
  end  
  
  it "should have a link to the previous section if there is one and it is linkable" do
    @prev.stub!(:linkable?).and_return(true)
    @controller.template.should_receive(:section_url).with(@prev).and_return("http://www.test-prev.url")      
    do_render
    response.should have_tag("a.prev-section[href=http://www.test-prev.url]", :text => "Previous section")
  end
    
  it "should have a link to the next section if there is one and it is linkable" do
    @next.stub!(:linkable?).and_return(true)
    @controller.template.should_receive(:section_url).with(@next).and_return("http://www.test-next.url")
    do_render
    response.should have_tag("a.next-section[href=http://www.test-next.url]", :text => "Next section")
  end
  
end