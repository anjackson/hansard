require File.dirname(__FILE__) + '/../../spec_helper'

describe "sections/show.haml", " in general" do

  before do
    @section = mock_model(Section, :null_object => true,
                                   :title => "section name",
                                   :hansard_reference => "hansard reference",
                                   :tag_list => 'interesting stuff')
    @controller.template.stub!(:render)
    @controller.template.stub!(:date).and_return(Date.new(1998,12,21))
    @controller.template.stub!(:section_url).and_return('/section/url')
    assigns[:section] = @section
  end

  def do_render
    render 'sections/show.haml'
  end

  it "should render the 'section' partial passing the section" do
    @controller.template.should_receive(:render).with(:partial => "sections/section", :object => @section, :locals => { :suppress_title => true })
    do_render
  end

end

describe 'sections/show.haml', 'when passed a section with no contributions' do

  it "should not render the section's marker html" do
    @date = Date.new(2005, 1, 12)
    @title = 'TRANSPORT'
    template.stub!(:marker_html).and_return("MARKERS_BEING_RETURNED")
    template.stub!(:section_breadcrumbs).and_return("BREADCRUMB")
    template.stub!(:section_navigation).and_return("NAV")
    template.stub!(:section_url).and_return('url')
    template.stub_render(:partial => "partials/front_page")
    section = mock_model(Section, :title_via_associations => @title,
                                  :title => @title,
                                  :mentions => [],
                                  :contributions => [],
                                  :sections => [],
                                  :hansard_reference => '',
                                  :tag_list => [],
                                  :date => @date)
    assigns[:section] = section
    assigns[:title] = @title
    assigns[:date] = @date
    render 'sections/show.haml', :layout => 'application'
    response.body.include?("MARKERS_BEING_RETURNED").should be_false
  end

end