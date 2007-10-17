require File.dirname(__FILE__) + '/../../spec_helper'

describe "application.haml", " in general" do
  
  before do
    
  end
  
  def do_render
    render 'layouts/application.haml'
  end
  
  it 'should render the HTML 5 doctype of "<!DOCTYPE html>"' do
    do_render
    response.body[0..14].should == "<!DOCTYPE html>"
  end
  
  it 'should have the lang type of "en-GB"' do
    do_render
    response.should have_tag("html[lang='en-GB']")
  end
  
end


describe "application.haml", " when on a day page" do

  before do
    @title = 'hello world'
    @day = Date.new(2004, 9, 16)
    @sitting = mock_model(HouseOfCommonsSitting)
    @sitting.stub!(:date).and_return(@day)
    @sitting.stub!(:part_id)
    assigns[:sitting] = @sitting
    assigns[:day] = @day
    assigns[:title] = @title
  end

  def do_render
    render 'layouts/application.haml'
  end

  it 'should have a link rel="alternate" with appropriate title pointing to the xml source ' do
    do_render
    
    response.body.should assert_tag(:link, :attributes => { 
      :rel => "alternate", 
      :type => "text/xml",
      :title => "Source file for: hello world", 
      :href => "/commons/source/2004/sep/16.xml"
    })
  end

  it 'should have a link rel="alternate" with appropriate title pointing to the xml output ' do
    do_render
    
    response.body.should assert_tag(:link, :attributes => { 
      :rel => "alternate", 
      :type => "text/xml",
      :title => "XML file for: hello world", 
      :href => "/commons/2004/sep/16.xml"
    })
  end

end