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
  
  it 'should not have a title which is "Historic Hansard: Please give me a title"'
  
  it 'should render the Google Custom Search box if we are online'
  
  it 'should not render the Google Custom Search box if we are offline'
  
  it 'should render the del.icio.us box'
  
  it 'should have a link rel="alternate" with appropriate title pointing to the xml source if on a day page'
  
  it 'should have a link rel="alternate" with appropriate title pointing to the xml output if on a day page'
  
  it 'should have a link rel="author"'
  
  it 'should have a link rel="bookmark"'
  
  it 'should have a link rel="contact"'
  
  it 'should have a link rel="first"'
  
  it 'should have a link rel="help"'
  
  it 'should have a link rel="index"'
  
  it 'should have a link rel="last"'
  
  it 'should have a link rel="license"'
  
  it 'should have a link rel="licence"'
  
  it 'should have a link rel="next"'
  
  it 'should have a link rel="prev"'
  
  it 'should have a link rel="tag"'
  
  it 'should have a link rel="up"'
  
end