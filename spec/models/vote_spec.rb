require File.dirname(__FILE__) + '/../spec_helper'

def mock_vote_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:<<)
  mock_builder.stub!(:i)
  mock_builder
end

def setup_vote
  vote = Vote.new
  vote.name = "test &name"
  vote.constituency = "test & constituency"
  vote
end

describe Vote do 

  before do
    @model = setup_vote
    @mock_builder = mock_vote_builder
  end
  
  describe "in general" do
    
    it_should_behave_like "an xml-generating model"

  end

  describe Vote, ".to_xml" do

    before do 
       @vote = setup_vote
    end
    
    it "should return the name of the voter" do
      @vote.to_xml.should match(/test &amp;name/)
    end

    it "should return an 'i' tag containing the escaped constituency of the voter in brackets if there is one" do
      @vote.to_xml.should have_tag('i', :text => "(test &amp; constituency)")
    end

  end

  describe Vote, "when asked for its end column" do

    it "should return the first column" do
      vote = Vote.new(:column => "2")
      vote.start_column.should == 2
    end

    it "should return nil if the vote has no column" do
      vote = Vote.new(:column => nil)
      vote.start_column.should be_nil
    end

  end

  describe Vote, " when asked for its end column" do

    it "should return the column" do
      vote = Vote.new(:column => "2")
      vote.end_column.should == 2
    end

    it "should return nil if the vote has no column" do
      vote = Vote.new(:column => nil)
      vote.end_column.should be_nil
    end

  end
  
end