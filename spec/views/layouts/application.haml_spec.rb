require File.dirname(__FILE__) + '/../../spec_helper'

describe "application.haml", " in general" do
  
  def do_render 
    render 'layouts/application.haml'
  end
  
  it 'should render the HTML 5 doctype'
  
  it 'should render the Google Custom Search box if we are online'
  
  it 'should not render the Google Custom Search box if we are offline'
  
  it 'should render the del.icio.us box'
  
  it 'should should have a link rel="alternate" with appropriate title pointing to the xml source if on a day page'
  
  it 'should should have a link rel="alternate" with appropriate title pointing to the xml output if on a day page'
  
end