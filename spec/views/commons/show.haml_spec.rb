require File.dirname(__FILE__) + '/../../spec_helper'

describe "show.haml", " in general" do

  before do
    @debates = mock_model(Debates)
    @debates.stub!(:sections).and_return([])
    @sitting = mock_model(Sitting)
    @sitting.stub!(:date_text)
    @sitting.stub!(:debates).and_return(@debates)
    @controller.template.stub!(:render)
    assigns[:sitting] = @sitting
    @first_section = mock_model(Section)
    @first_section.stub!(:title).and_return("First Title")
    @second_section = mock_model(Section)
    @second_section.stub!(:title).and_return("Second Title")
    @controller.template.stub!(:section_url).and_return("http://test.host")
  end
  
  def do_render 
    render 'commons/show.haml'
  end
  
  it "should render the 'hansard_header' partial" do
    @controller.template.should_receive(:render).with(:partial => "hansard_header")
    do_render
  end
  
  it "should display a link to each of the sections belonging to the sitting's debates with the title of the section" do
    @debates.should_receive(:sections).and_return([@first_section, @second_section])
    do_render
    response.should have_tag('div.debates') do
      with_tag('div.section-link', :text => "First Title")
      with_tag('div.section-link', :text => "Second Title") 
    end
  end
  
  it "should actually link to the sections" do
    @debates.should_receive(:sections).and_return([@first_section, @second_section])
    do_render
    response.should have_tag('div.debates') do
      with_tag('div.section-link a[href=http://test.host]')
      with_tag('div.section-link a[href=http://test.host]') 
    end
  end
  
end

