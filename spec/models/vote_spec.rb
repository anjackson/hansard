require File.dirname(__FILE__) + '/../spec_helper'

def mock_vote_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:<<)
  mock_builder.stub!(:i)
  mock_builder
end

def setup_vote
  vote = Vote.new
  vote.name = "test name"
  vote.constituency = "test constituency"
  vote
end

describe Vote, " in general" do
  
  before(:each) do
    @model = setup_vote
    
    @mock_builder = mock_vote_builder
  end
  
  it_should_behave_like "an xml-generating model"

end

describe Vote, ".to_xml" do
  
  before do
    @mock_builder = mock_vote_builder
    @vote = setup_vote
  end

  it "should return the name of the voter" do
    @vote.to_xml.should match(/test name/)
  end
  
  it "should return an 'i' tag containing the constituency of the voter in brackets if there is one" do
    @vote.to_xml.should have_tag('i', :text => "(test constituency)")
  end

end