require File.dirname(__FILE__) + '/../../spec_helper'

describe "offices show.haml", " when rendering an office page" do
  
  before do 
    @office = mock_model(Office, :null_object => true,
                                 :name => '', 
                                 :slug => '')
    assigns[:office] = @office
  end
  
  def do_render
    render "offices/show.haml"
  end

end
