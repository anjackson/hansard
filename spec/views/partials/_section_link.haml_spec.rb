require File.dirname(__FILE__) + '/../../spec_helper'

describe "_section_link.haml" do
  
  before do
    @super_section = mock_model(Section)
    @super_section.stub!(:linkable?).and_return(true)
    @super_section.stub!(:title?).and_return(true)
    @super_section.stub!(:title).and_return("Super Title")
    @super_section.stub!(:parent_section).and_return(false)
    @super_section.stub!(:contributions).and_return([])
    @first_section = mock_model(Section)
    @second_section = mock_model(Section)
    @super_section.stub!(:sections).and_return([@first_section, @second_section])
    @controller.template.stub!(:section_url).and_return("http://test.host")
    @controller.template.stub!(:section_link).and_return(@super_section)
    @controller.template.stub!(:render)
  end
  
  def do_render
    render "partials/_section_link.haml"
  end
  
  it "should display a link to the section with the title of the section" do
    do_render
    response.should have_tag('div.section-link', :text => "Super Title")
  end
  
  it "should actually link to the sections" do
    do_render
    response.should have_tag('div.section-link a[href=http://test.host]')
  end
  
  it "should render the template 'partials/section_link' with each of the section's subsections" do
    @controller.template.should_receive(:render).with(:partial => "partials/section_link", :collection => @super_section.sections)
    do_render
  end
  
  it "should render the template 'partials/section_link' with each of the section's subsections if the section does not have a title" do
    @super_section.stub!(:title?).and_return(false)
    @controller.template.should_receive(:render).with(:partial => "partials/section_link", :collection => @super_section.sections)
    do_render
  end
  
end