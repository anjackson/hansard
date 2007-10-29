require File.dirname(__FILE__) + '/../../spec_helper'

describe "index", " in general" do

  before do
    @index = mock_model(Index)
    @index.stub!(:title)
    @index.stub!(:decade).and_return(1920)
    assigns[:indices_by_decade] = [[@index]]
  end

  it "should render the index partial for each index" do
    @controller.expect_render(:partial => 'index', :collection => [@index])
    render 'indices/index.haml'
  end

end