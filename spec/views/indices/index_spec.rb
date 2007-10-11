require File.dirname(__FILE__) + '/../../spec_helper'

describe "index", " in general" do

  before do
    @index = mock_model(Index)
    @index.stub!(:title)
    @index.stub!(:decade).and_return(1920)
    assigns[:indices_by_decade] = [[@index]]
  end

  it "should have an 'h1' tag containing the text 'Historical Hansard: Indices'" do
    @controller.stub_render(:partial => 'index', :collection => [@index])
    render 'indices/index.haml'
    response.should have_tag("h1", :text => "Hansard: Indices")
  end

  it "should render the index partial for each index" do
    @controller.expect_render(:partial => 'index', :collection => [@index])
    render 'indices/index.haml'
  end

end