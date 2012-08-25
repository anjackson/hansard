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
    vote.stub!(:start_column)
    division.send(vote_class.tableize) << vote
  end
end

def get_division
  division = CommonsDivision.new
  division.name = "Test & name"
  division.time_text = "[11.15 &pm"
  division
end

describe CommonsDivision, "when creating XML export" do

  before do
    @model = @division = get_division
    @mock_builder = mock_division_builder
  end

  it_should_behave_like "an xml-generating model"
  
  it "should have a 'division' tag" do
    @division.to_xml.should have_tag("division")
  end

  it "should have a 'table' tag within the 'division' tag" do
    @division.to_xml.should have_tag("division table")
  end

  it "should have a first 'tr' tag whose first 'td' tag contains a 'b' tag containing the escaped division name" do
    @division.to_xml.should have_tag("table tr:nth-child(1) td:nth-child(1) b", :text => "Test &amp; name")
  end

  it "should have a first 'tr' tag whose second 'td' tag is right-aligned and contains a 'b' tag containing the escaped division time text" do
    @division.to_xml.should have_tag("table tr:nth-child(1) td:nth-child(2)[align=right] b", :text => "[11.15 &amp;pm")
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

  it 'should not throw an error for a division with no name' do 
    @division.name = nil
    lambda{ @division.to_xml }.should_not raise_error
  end
  
  it 'should not throw an error for a division with no time text' do 
    @division.time_text = nil
    lambda{ @division.to_xml }.should_not raise_error
  end
  
end

describe CommonsDivision, "start_of_division?" do

  def is_start year, values, series_number=nil
    CommonsDivision.start_of_division?(year, values, series_number).should be_true
  end

  def is_not_start year, values, series_number=nil
    CommonsDivision.start_of_division?(year, values, series_number).should be_false
  end

  it 'should return false if provided with a first value which matches a division title, but is not a pre-1981 three-column division or a post-1980 two-column division' do
    CommonsDivision.stub!(:pre_1981_and_three_columns).and_return false
    CommonsDivision.stub!(:post_1980_and_two_columns).and_return false
    is_not_start 1901, ['Division No. 1.]', 'AYES', '[9.59 p.m.']
  end

  it 'should return true for start of pre 1981 three column division table' do
    is_start 1901, ['AYES.']
  end

  it 'should return true for start of pre 1981 three column division table' do
    is_start 1957, ['Division No. 1.]', 'AYES', '[9.59 p.m.']
  end

  it 'should return true for start of post 1980 two column division table' do
    is_start 1983, ['Division No. 75]', '[10 pm']
  end

  it 'should return true for a three column division from 1926 without a number' do
    is_start 1926, ['Division', 'AYES', '[4 0 p.m.']
  end

  it 'should return true for a three column division from 1926' do
    is_start 1926, ['Division No. 92.]', 'AYES', '[7.51 p.m.' ]
  end

  it 'should return true for a two column division from 1986 with division misspelled' do
    is_start 1986, ['Divison No. 246]', '[4.45 pm']
  end

  it 'should return true for a two column series 3 division with List of NOES as heading' do
    is_start 1831, ['List of the NOES.'], 3
  end

  it 'should return false for continuation of pre 1981 three column division table' do
    is_not_start 1957, ['Mallalieu, J. P. W. (Huddersfd, E.)', 'Probert, A. R.', 'Swingler, S. T.']
  end
end

describe CommonsDivision, "continuation_of_division?" do
  def is_continuation year, values
    CommonsDivision.continuation_of_division?(year, values).should be_true
  end

  def is_not_continuation year, values
    CommonsDivision.continuation_of_division?(year, values).should be_false
  end

  it 'should return true if pre 1981, and row has three names' do
    is_continuation 1957, ['Mallalieu, J. P. W. (Huddersfd, E.)', 'Probert, A. R.', 'Swingler, S. T.']
  end

  it 'should return true if pre 1981, and row has text "NOES"' do
    is_continuation 1957, ['NOES']
  end

  it 'should return true if pre 1981, and row has text "NOES."' do
    is_continuation 1926, ['NOES.']
  end

  it 'should return false for start of pre 1981 three column division table' do
    is_not_continuation 1957, ['Division No. 1.]', 'AYES', '[9.59 p.m.']
  end

  it 'should return false for start of post 1980 two column division table' do
    is_not_continuation 1983, ['Division No. 75]', '[10 pm']
  end

  it 'should return false if header value is empty' do
    is_not_continuation 1983, ["", "&#x2014;(1) After section 18"]
  end
end

describe CommonsDivision, 'with votes' do

  it 'should return vote count, as sum of votes excluding tellers' do
    division = CommonsDivision.new
    ayes = [mock_model(AyeVote), mock_model(AyeVote)]
    noes = [mock_model(NoeVote)]
    tellers = [mock_model(AyeTellerVote), mock_model(NoeTellerVote)]

    division.stub!(:votes).and_return ayes + noes + tellers

    division.vote_count.should == ayes.size + noes.size
  end
end

describe CommonsDivision, 'when counting votes in divided text' do

  def should_have_vote_count text, count
    CommonsDivision.vote_count(text).should == count
  end

  it 'should count votes in "The Houses divided: Ayes, 235; Noes, 118."' do
    should_have_vote_count "The Houses divided: Ayes, 235; Noes, 118.", 353
  end

  it 'should count votes in "The House divided: Ayes, 235; Noes, 118."' do
    should_have_vote_count "The House divided: Ayes, 235; Noes, 118.", 353
  end

  it 'should count votes in "The House having divided: Ayes 325, Noes 202."' do
    should_have_vote_count "The House having divided: Ayes 325, Noes 202.", 527
  end

  it 'should count votes in "The Committee divided: Ayes 139, Noes 187."' do
    should_have_vote_count "The Committee divided: Ayes 139, Noes 187.", 326
  end

  it 'should count votes in "The Committee divided: Ayes, 37; Noes, 217."' do
    should_have_vote_count "The Committee divided: Ayes, 37; Noes, 217.", 254
  end

  it 'should count votes in "The Committee divided: Ayes, 0;Noes, 122."' do
    should_have_vote_count "The Committee divided: Ayes, 0;Noes, 122.", 122
  end

  it %Q|should count votes in "The 'Committee divided: Ayes, 262; Noes, 37."| do
    should_have_vote_count "The 'Committee divided: Ayes, 262; Noes, 37.", 299
  end

  it 'should count votes in "The Committee divided:&#x2014;Aye, 162 Noes, 78. (Division List No. 205)."' do
    should_have_vote_count "The Committee divided:&#x2014;Aye, 162 Noes, 78. (Division List No. 205).", 240
  end

  it 'should count votes in "The House divided:&#x2014;Ayes, 149; Noes,. 38. (Division List No. 204.)"' do
    should_have_vote_count "The House divided:&#x2014;Ayes, 149; Noes,. 38. (Division List No. 204.)", 187
  end

  it 'should count votes in "<i>Question put,</i> That those words be there inserted:&#x2014;<i>The Committee deveded:</i> Ayes 184, Noes 237."' do
    should_have_vote_count '<i>Question put,</i> That those words be there inserted:&#x2014;<i>The Committee deveded:</i> Ayes 184, Noes 237.', 421
  end
end

describe CommonsDivision, 'when determining if complete compared to divided text' do
  it 'should be complete if votes count matches count of votes in divided text' do
    division = CommonsDivision.new
    division.should_receive(:vote_count).and_return 254

    divided_text = "The Committee divided: Ayes, 37; Noes, 217."
    CommonsDivision.should_receive(:vote_count).with(divided_text).and_return 254

    division.have_a_complete_division?(divided_text).should be_true
  end

  def teller_complete_division
    division = CommonsDivision.new
    division.stub!(:aye_teller_count).and_return 2
    division.stub!(:noe_teller_count).and_return 2
    division
  end

  it 'should be complete if there are two aye tellers and two noe tellers and totals are within two votes of each other' do
    division = teller_complete_division
    division.stub!(:vote_count).and_return 252
    divided_text = "The Committee divided: Ayes, 37; Noes, 217."
    CommonsDivision.stub!(:vote_count).and_return 254
    division.have_a_complete_division?(divided_text).should be_true

    division = teller_complete_division
    division.stub!(:vote_count).and_return 256
    divided_text = "The Committee divided: Ayes, 37; Noes, 217."
    CommonsDivision.stub!(:vote_count).and_return 254
    division.have_a_complete_division?(divided_text).should be_true
  end

  it 'should be not complete if there are two aye tellers and two noe tellers and totals are more than two votes different from each other' do
    division = teller_complete_division
    division.stub!(:vote_count).and_return 250
    divided_text = "The Committee divided: Ayes, 37; Noes, 217."
    CommonsDivision.stub!(:vote_count).and_return 254
    division.have_a_complete_division?(divided_text).should be_false
  end
end

describe CommonsDivision, 'when retrieving names of members voting' do
  before do
    @division = CommonsDivision.new
  end

  def mock_votes vote_type, votes_method
    @mp = 'Appleton'
    @mp2 = 'Brown'
    votes = [ mock_model(vote_type, :name => @mp2), mock_model(vote_type, :name => @mp) ]
    @division.stub!(votes_method).and_return votes
  end

  it 'should return aye votes names' do
    mock_votes AyeVote, :aye_votes
    @division.aye_vote_names.should == [@mp,@mp2]
  end

  it 'should return noe votes names' do
    mock_votes NoeVote, :noe_votes
    @division.noe_vote_names.should == [@mp,@mp2]
  end

  it 'should return aye teller names' do
    mock_votes AyeTellerVote, :aye_teller_votes
    @division.aye_teller_names.should == [@mp,@mp2]
  end

  it 'should return noe teller names' do
    mock_votes NoeTellerVote, :noe_teller_votes
    @division.noe_teller_names.should == [@mp,@mp2]
  end
end

describe CommonsDivision, 'when exporting to csv' do

  before do
    @division = CommonsDivision.new
    @division.stub!(:date).and_return nil
    @division.stub!(:section_title).and_return nil
    @division.stub!(:divided_text).and_return nil
    @division.stub!(:result_text).and_return nil
  end

  it 'should include its url' do
    url = 'http://localhost:80/commons/2004/sep/08/hospital-acquired-infection/division_239'
    @division.to_csv(url).should include(url.sub(':80',''))
  end

  it 'should include section title' do
    title = 'BELFAST (No. 2)'
    @division.stub!(:section_title).and_return title
    @division.to_csv.should include(%Q|"#{title}"|)
  end

  it 'should include house name' do
    @division.to_csv.should include('House of Commons')
  end

  it 'should include date' do
    date = Date.new(1898,12,12)
    @division.stub!(:date).and_return date
    @division.to_csv.should include('1898-12-12')
  end

  it 'should include name' do
    name = 'Division No. 156]'
    @division.stub!(:name).and_return name
    @division.to_csv.should include(name)
  end

  it 'should include "Division" if there is no name' do
    name = nil
    @division.stub!(:name).and_return name
    @division.to_csv.should include('Division')
  end

  it 'should include time_text' do
    time = '[4:20pm'
    @division.stub!(:time_text).and_return time
    @division.to_csv.should include(time)
  end

  it 'should include divided_text' do
    divided_text = 'The House divided: Ayes, 43; Noes, 81. '
    @division.stub!(:divided_text).and_return divided_text
    @division.to_csv.should include(%Q|"#{divided_text}"|)
  end

  it 'should include result_text' do
    result_text = 'Question accordingly negatived.'
    @division.stub!(:result_text).and_return result_text
    @division.to_csv.should include(%Q|"#{result_text}"|)
  end

  it 'should include Ayes' do
    mp = 'Simon, Siôn'
    @division.stub!(:aye_vote_names).and_return [mp]
    @division.to_csv.should include("\n\n# Ayes")
    @division.to_csv.should include(%Q|"#{mp}"|)
  end

  it 'should include Noes' do
    mp = 'mp'
    @division.stub!(:noe_vote_names).and_return [mp]
    @division.to_csv.should include("\n\n# Noes")
    @division.to_csv.should include(%Q|"#{mp}"|)
  end

  it 'should include Aye tellers' do
    mp = 'mp'
    @division.stub!(:aye_teller_names).and_return [mp]
    @division.to_csv.should include("\n\n# Tellers for the Ayes")
    @division.to_csv.should include(%Q|"#{mp}"|)
  end

  it 'should include Noe tellers' do
    mp = 'mp'
    @division.stub!(:noe_vote_names).and_return [mp]
    @division.to_csv.should include("\n\n# Tellers for the Noes")
    @division.to_csv.should include(%Q|"#{mp}"|)
  end

end
