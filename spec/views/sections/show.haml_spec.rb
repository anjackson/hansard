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
    @controller.template.should_receive(:render).with(:partial => "section", :object => @section, :locals => { :suppress_title => true })
    do_render
  end

end

# describe 'sections/show.haml', 'when passed a section with nested sections' do
  # before do
    # sitting = Sitting.create
#
    # parent = Section.create(:title => 'TRANSPORT', :sitting_id => sitting.id)
    # first  = Section.create(:title => 'Heavy Goods Vehicles (Public Weighbridge Facilities)', :sitting_id => sitting.id)
    # second = Section.create(:title => 'Driving Licences (Overseas Recognition)', :sitting_id => sitting.id)
    # third  = Section.create(:title => 'Public Boards (Appointments)', :sitting_id => sitting.id)
#
    # parent.sections = [first, second, third]
    # sitting.sections = [parent]
#
    # parent.sitting = sitting
    # sitting.save!
#
    # assigns[:section] = parent
  # end
#
  # it 'should render parent section title as h1 heading' do
    # render 'sections/show.haml'
    # puts response.inspect
    # response.should have_tag('h1')
  # end
#
  # after do
    # Sitting.find(:all).each {|s| s.destroy}
  # end
# end