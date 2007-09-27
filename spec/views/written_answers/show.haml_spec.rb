require File.dirname(__FILE__) + '/../../spec_helper'

describe "show.haml", " in general" do

  before do
    @group = mock_model(WrittenAnswersGroup)
    @group.stub!(:title).and_return("group title")
    @sitting = mock_model(Sitting)
    @sitting.stub!(:groups).and_return([@group])
    @controller.template.stub!(:render)
    assigns[:sitting] = @sitting
    @group.stub!(:sections).and_return([@first_section, @second_section])
  end
  
  def do_render 
    render 'written_answers/show.haml'
  end
  
  it "should render the 'hansard_header' partial" do
    @controller.template.should_receive(:render).with(:partial => "hansard_header")
    do_render
  end

  it "should render the 'partials/section_link' partial, passing the sitting's groups" do
    @controller.template.should_receive(:render).with(:partial => "partials/section_link", :collection => @sitting.groups)
    do_render
  end
  
end
