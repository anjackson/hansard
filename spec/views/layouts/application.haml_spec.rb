require File.dirname(__FILE__) + '/../../spec_helper'

describe "application.haml", " in general" do
  
  def do_render 
    render 'layouts/application.haml'
  end
  
  it 'should render the Google Custom Search box if we are online'
  
  it 'should not attempt to render the Google Custom Search box if we are offline'
  
  it 'should render the del.icio.us box'
  
end