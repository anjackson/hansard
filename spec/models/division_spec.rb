require File.dirname(__FILE__) + '/../spec_helper'

def mock_division_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:division)
  mock_builder
end

def mock_votes(division, vote_class)
  first_vote = mock_model(vote_class.constantize)
  second_vote = mock_model(vote_class.constantize)
  [first_vote, second_vote].each do |vote|
    vote.stub!(:first_col)
    division.send(vote_class.tableize) << vote
  end
end

def get_division
  division = Division.new
  division.name = "Test name"
  division.time_text = "[11.15 pm"
  division
end

describe Division do
  before(:each) do
    @model = get_division
    @mock_builder = mock_division_builder
  end

  it_should_behave_like "an xml-generating model"

end

describe Division, ".to_xml" do

  before do
    @division = get_division
  end

  it "should have a 'division' tag" do
    @division.to_xml.should have_tag("division")
  end
  
  it "should have a 'table' tag within the 'division' tag" do
    @division.to_xml.should have_tag("division table")
  end
  
  it "should have a first 'tr' tag whose first 'td' tag contains a 'b' tag containing the division name" do
    @division.to_xml.should have_tag("table tr:nth-child(1) td:nth-child(1) b", :text => "Test name")
  end 
  
  it "should have a first 'tr' tag whose second 'td' tag is right-aligned and contains a 'b' tag containing the division time text" do
    @division.to_xml.should have_tag("table tr:nth-child(1) td:nth-child(2)[align=right] b", :text => "[11.15 pm")
  end
   
  it "should have a second 'tr' tag containing a center-aligned 'td' tag spanning two columns and containing a 'b' tag with the text 'AYES'" do
    @division.to_xml.should have_tag("table tr:nth-child(2) td:nth-child(1)[align=center][colspan=2] b", :text => "AYES")
  end
  
  it "should ask each of it's aye votes for xml" do
    mock_votes(@division, "AyeVote")
    @division.aye_votes.each{ |aye_vote| aye_vote.should_receive(:to_xml) } 
    @division.to_xml
  end
  
  it "should ask each of it's aye teller votes for xml" do
    mock_votes(@division, "AyeTellerVote")
    @division.aye_teller_votes.each{ |aye_teller_vote| aye_teller_vote.should_receive(:to_xml) } 
    @division.to_xml
  end

  it "should ask each of it's no votes for xml" do 
    mock_votes(@division, "NoeVote")
    @division.noe_votes.each{ |no_vote| no_vote.should_receive(:to_xml) } 
    @division.to_xml
  end
  
  it "should ask each of it's noe teller votes for xml" do
    mock_votes(@division, "NoeTellerVote")
    @division.noe_teller_votes.each{ |noe_teller_vote| noe_teller_vote.should_receive(:to_xml) } 
    @division.to_xml
  end
  
  it "should have a 'tr' tag containing a center-aligned 'td' tag spanning two columns and containing a 'b' tag with the text 'NOES'" do
    @division.to_xml.should have_tag("table tr td:nth-child(1)[align=center][colspan=2] b", :text => "NOES")
  end
  
end


