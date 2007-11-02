require File.dirname(__FILE__) + '/../spec_helper'

describe MemberContribution, " on creation" do
  it 'should create a member model if one does not exist' do
    Member.delete_all
    member_name = 'Mr Tickle'
    contribution = MemberContribution.new :member_name => member_name
    member = mock_model(Member)
    Member.should_receive(:find_or_create_from_name).and_return(member)
    contribution.save!
    contribution.member.should == member
    MemberContribution.delete_all
    Member.delete_all
  end
end

describe MemberContribution, " in general" do

  before(:each) do
    @model = MemberContribution.new
    @model.stub!(:member_name).and_return("test member")
    @mock_builder = mock("xml builder")
    @mock_builder.stub!(:p)
  end

  it_should_behave_like "an xml-generating model"

end

describe MemberContribution, ".to_xml" do

  before do
    @contribution = MemberContribution.new
    @contribution.member_name = "test member"
  end

  it "should return one 'p' tag with no content if the text of the member contribution is nil" do
    @contribution.text = nil
    @contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
  end

  it "should return a 'p' tag containing one 'membercontribution' tag containing the text of the oral question contribution if it exists" do
    the_expected_text = "Some text I expected"
    @contribution.text = the_expected_text
    @contribution.to_xml.should have_tag('p membercontribution', :text => the_expected_text, :count => 1)
  end

  it "should have a 'memberconstituency' tag inside the 'member' tag containing the constituency if the contribution has a constituency" do
    @contribution.member_constituency = "test constituency"
    @contribution.to_xml.should have_tag('member memberconstituency', :text => "test constituency", :count => 1)
  end

  it "should return one 'member' tag containing the member attribute of member contribution" do
    @contribution.member_name = "John Q. Member"
    @contribution.to_xml.should have_tag('member', :text => "John Q. Member", :count => 1)
  end

  it "should contain one 'membercontribution' tag containing the member contribution text" do
    @contribution.text = "Is this a question?"
    @contribution.to_xml.should have_tag("membercontribution", "Is this a question?")
  end

  it "should return a 'p' tag containing one member tag (and no text) if there's no oral question number" do
    @contribution.question_no = nil
    @contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
    @contribution.to_xml.should have_tag('p member', :count => 1)
  end

  it "should return a 'p' tag whose text starts with the oral question number if the contribution has one" do
    the_question_no = "1."
    @contribution.question_no = the_question_no
    @contribution.to_xml.should have_tag('p', :text => /^#{the_question_no}/, :count => 1)
  end

  it_should_behave_like "a contribution"

end
