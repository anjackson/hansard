require File.dirname(__FILE__) + '/../../spec_helper'

describe "show.haml", " in general" do

  before do
    @group = mock_model(WrittenAnswersGroup)
    @group.stub!(:title).and_return("group title")
    @sitting = mock_model(Sitting)
    @sitting.stub!(:date_text)
    @sitting.stub!(:groups).and_return([@group])
    @controller.template.stub!(:render)
    assigns[:sitting] = @sitting
    @first_section = mock_model(Section)
    @first_section.stub!(:title).and_return("First Title")
    @second_section = mock_model(Section)
    @second_section.stub!(:title).and_return("Second Title")
    @controller.template.stub!(:section_url).and_return("http://test.host")
    @group.stub!(:sections).and_return([@first_section, @second_section])
  end
  
  def do_render 
    render 'written_answers/show.haml'
  end
  
  it "should render the 'hansard_header' partial" do
    @controller.template.should_receive(:render).with(:partial => "hansard_header")
    do_render
  end
  
  it "should display a link to each of the groups, with nested links for each section within that group" do
    do_render
    response.should have_tag('div.groups') do
      with_tag('div.section-link', :text => "group title")  
      with_tag('div.sub-section-link', :text => "First Title")
      with_tag('div.sub-section-link', :text => "Second Title") 
    end
  end
  
  it "should actually link to the sections" do
    do_render
    response.should have_tag('div.groups') do
      with_tag('div.section-link a[href=http://test.host]')
      with_tag('div.section-link a[href=http://test.host]') 
    end
  end
  
end
