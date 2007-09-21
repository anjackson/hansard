require File.dirname(__FILE__) + '/../../spec_helper'

describe "application.haml", " in general" do
  
  def do_render 
    render 'layouts/application.haml'
  end
  
  it 'should render the Google Custom Search box if we are online' do
  end
  
  it 'should not attempt to render the Google Custom Search box if we are offline' do
  end
  
end