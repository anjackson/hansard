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
    @first_section.stub!(:title?).and_return(true)
    @first_section.stub!(:sections).and_return([])
    @second_section = mock_model(Section)
    @second_section.stub!(:title).and_return("Second Title")
    @second_section.stub!(:title?).and_return(true)
    @second_section.stub!(:sections).and_return([])
    @controller.template.stub!(:section_url).and_return("http://test.host")
    @debates.stub!(:sections).and_return([@first_section, @second_section])
  end

  def do_render
    render 'commons/show.haml'
  end

  it "should render the 'hansard_header' partial" do
    @controller.template.should_receive(:render).with(:partial => "partials/hansard_header")
    do_render
  end

  it "should render the 'partials/_section_link' partial, passing the sitting's debates' sections" do
    @controller.template.should_receive(:render).with(:partial => "partials/section_link", :collection => @sitting.debates.sections)
    do_render
  end

  it "should give the message 'No information from the Commons was found for this period.' if no sitting is passed to it" do
    assigns[:sitting] = nil
    do_render
    response.should have_tag("div.no-sittings", :text => "No information from the Commons was found for this period.")
  end

end

