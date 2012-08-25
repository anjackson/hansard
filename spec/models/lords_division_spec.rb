require File.dirname(__FILE__) + '/../spec_helper'

describe LordsDivision, "start_of_division?" do
  def is_start year, values
    LordsDivision.start_of_division?(year, values).should be_true
  end

  def is_not_start year, values
    LordsDivision.start_of_division?(year, values).should be_false
  end

  it 'should return true for start of pre 1981 three column division table' do
    is_not_start 1957, ['Division No. 1.]', 'AYES', '[9.59 p.m.']
  end

  it 'should return true for start of post 1980 two column division table' do
    is_not_start 1983, ['Division No. 75]', '[10 pm']
  end

  it 'should return false for continuation of pre 1981 three column division table' do
    is_not_start 1957, ['Mallalieu, J. P. W. (Huddersfd, E.)', 'Probert, A. R.', 'Swingler, S. T.']
  end

  it 'should return true for various forms of Contents title' do
    titles =['CONTENTES',
        'CONTENTS',
        'CONTENTS>',
        'CONTENTS:',
        'CONTENTS.']
    titles.each do |t|
      is_start 1979, [t]
    end
  end

  it 'should return true for various forms of Division title' do
    titles = ['Division',
        'DIVISION 1',
        'DIVISION N0.1',
        'Division no. 1',
        'Division No 1',
        'Division No.1',
        'Division No. 1',
        'DIVISION No.1',
        'DIVISION No. 1',
        'DIVISION NO 1',
        'DIVISION NO, 1',
        'DIVISION NO.1',
        'DIVISION NO. 1',
        'Division No. 167',
        'Division No.2',
        'Division No. 2',
        'Division NO.2',
        'DIVISION NO.2',
        'Divison No.1',
        'DIVISION NO. 2',
        'DIVISION NO. 21',
        'Division No.3',
        'Division No. 3',
        'DIVISION No. 3',
        'DIVISION NO 3',
        'DIVISION NO.3',
        'DIVISION NO. 3',
        'DIVISION NO.3>',
        'Division No.4',
        'Division No. 4',
        'DIVISION No.4',
        'DIVISION No. 4',
        'DIVISION NO.4',
        'DIVISION NO. 4',
        'DIVISION NO. 4.',
        'Division No.5',
        'Division No. 5',
        'DIVISION No. 5',
        'DIVISION NO.5',
        'DIVISION NO. 5',
        'Division No.6',
        'Division No. 6',
        'DIVISION NO.6',
        'DIVISION NO. 6',
        'Division No. 7',
        'DIVISION NO.7',
        'DIVISION NO. 7',
        'DIVISION NO.8',
        'DIVISION NO. 8',
        'DIVISION NO. 9',
        'DIVISION NO. I',
        'DIVISIION NO. 6',
        'DIVISON NO. 2']
    titles.each do |t|
      is_start 1983, [t]
    end
  end
end

describe LordsDivision, "continuation_of_division?" do
  def is_continuation year, values
    LordsDivision.continuation_of_division?(year, values).should be_true
  end

  def is_not_continuation year, values
    LordsDivision.continuation_of_division?(year, values).should be_false
  end

  it 'should return true if pre 1981, and row has three names' do
    is_continuation 1957, ['Saye and Sele, L.', 'Sydenham of Combe, L.', 'Walsingham, L.']
  end

  it 'should return true if row contains NOT-CONTENTS.' do
    is_continuation 1957, ['NOT-CONTENTS.']
  end

  it 'should return true if row contains NOT-CONTENTS' do
    is_continuation 1957, ['NOT-CONTENTS']
  end

  it 'should return false if row contains NOES' do
    is_not_continuation 1957, ['NOES']
  end

  it 'should return false for start of pre 1983 division table' do
    titles =['CONTENTES',
        'CONTENTS',
        'CONTENTS>',
        'CONTENTS:',
        'CONTENTS.']
    titles.each do |t|
      is_not_continuation 1979, [t]
    end
  end

  it 'should return false for start of post 1983 division table' do
    is_not_continuation 1983, ['Division No. 75']
  end
end

describe LordsDivision, 'with votes' do
  it 'should return count of votes' do
    division = LordsDivision.new
    division.stub!(:votes).and_return [mock('vote')]
    division.vote_count.should == 1
  end
end

describe LordsDivision, 'when getting name from text' do
  it 'should correct "Divison No.1" to "Division No. 1"' do
    LordsDivision.name_from("Divison No.1").should == 'Division No. 1'
  end
end

describe LordsDivision, 'when counting votes in divided text' do

  def should_have_vote_count text, count
    LordsDivision.vote_count(text).should == count
  end

  it 'should count votes in "Their Lordships divided: Contents, 3; Not-Contents, 3."' do
    should_have_vote_count "Their Lordships divided: Contents, 3; Not-Contents, 3.", 6
  end

  it 'should count votes in "Their Lordships divided: Contents,"55; Not-Contents, 17"' do
    should_have_vote_count %Q|Their Lordships divided: Contents,"55; Not-Contents, 17|, 72
  end

  it 'should count votes in "Their Lordships divided:&#x2014;Contents, 33; Not Contents, 48."' do
    should_have_vote_count "Their Lordships divided:&#x2014;Contents, 33; Not Contents, 48.", 81
  end

  it 'should count votes in "Their Lordships divided: Contents. 14; Not-Contents, 21."' do
    should_have_vote_count "Their Lordships divided: Contents. 14; Not-Contents, 21.", 35
  end

  it 'should count votes in "On Question, whether the proposed new clause shall be here inserted&#x2014;Their Lordships divided:&#x2014;Contents, 4; Not-Contents, 34."' do
    should_have_vote_count "On Question, whether the proposed new clause shall be here inserted&#x2014;Their Lordships divided:&#x2014;Contents, 4; Not-Contents, 34.", 38
  end

  it 'should count votes in "Their Lordships divided:&#x2014;Contents, 11; Not-Content; 30."' do
    should_have_vote_count "Their Lordships divided:&#x2014;Contents, 11; Not-Content; 30.", 41
  end
end


describe LordsDivision, 'when retrieving names of members voting' do
  before do
    @division = LordsDivision.new
  end

  def mock_votes vote_type, votes_method
    @peer = 'Appleton, L.'
    @peer2 = 'Brown, L.'
    votes = [ mock_model(vote_type, :name => @peer2), mock_model(vote_type, :name => @peer) ]
    @division.stub!(votes_method).and_return votes
  end

  it 'should return content votes names in alphabetic order' do
    mock_votes ContentVote, :contents
    @division.content_vote_names.should == [@peer,@peer2]
  end

  it 'should return not-content votes names in alphabetic order' do
    mock_votes NotContentVote, :not_contents
    @division.not_content_vote_names.should == [@peer,@peer2]
  end

  it 'should return content teller names in alphabetic order' do
    mock_votes ContentTellerVote, :contents
    teller_label = ', teller'
    @division.content_vote_names(teller_label).should == [@peer+teller_label,@peer2+teller_label]
  end

  it 'should return not-content teller names in alphabetic order' do
    mock_votes NotContentTellerVote, :not_contents
    teller_label = ', teller'
    @division.not_content_vote_names(teller_label).should == [@peer+teller_label,@peer2+teller_label]
  end
end

describe CommonsDivision, 'when exporting to csv' do

  before do
    @division = LordsDivision.new
    @division.stub!(:date).and_return nil
    @division.stub!(:section_title).and_return nil
    @division.stub!(:divided_text).and_return nil
    @division.stub!(:result_text).and_return nil
  end

  it 'should include its url' do
    url = 'http://localhost:80/lords/1972/may/02/hare-coursing-abolition-no-2-bill-hl/division_1.csv'
    @division.to_csv(url).should include(url.sub(':80',''))
  end

  it 'should include section title' do
    title = 'BELFAST (No. 2)'
    @division.stub!(:section_title).and_return title
    @division.to_csv.should include(%Q|"#{title}"|)
  end

  it 'should include house name' do
    @division.to_csv.should include('House of Lords')
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
    name = ''
    @division.stub!(:name).and_return name
    @division.to_csv.should include('Division')
  end

  it 'should include time_text' do
    time = '[4:20pm'
    @division.stub!(:time_text).and_return time
    @division.to_csv.should include(time)
  end

  it 'should include divided_text' do
    divided_text = 'Their Lordships divided: Contents, 43; Not-Contents, 81.'
    @division.stub!(:divided_text).and_return divided_text
    @division.to_csv.should include(%Q|"#{divided_text}"|)
  end

  it 'should include result_text' do
    result_text = 'Question accordingly negatived.'
    @division.stub!(:result_text).and_return result_text
    @division.to_csv.should include(%Q|"#{result_text}"|)
  end

  it 'should include Contents' do
    peer = 'Appleton, L.'
    peer2 = 'Brown, L.'
    @division.stub!(:content_vote_names).and_return [peer, peer2]
    @division.to_csv.should include("\n\n# Contents")
    @division.to_csv.should include(%Q|"#{peer}"\n"#{peer2}"|)
  end

  it 'should include Not-Contents' do
    peer = 'peer'
    @division.stub!(:not_content_vote_names).and_return [peer]
    @division.to_csv.should include("\n\n# Not-Contents")
    @division.to_csv.should include(%Q|"#{peer}"|)
  end

  it 'should include Contents tellers' do
    peer = 'Appleton, L., [Teller]'
    peer2 = 'Brown, L., [Teller]'
    @division.stub!(:content_vote_names).with(', [Teller]').and_return [peer, peer2]
    @division.to_csv.should include("\n\n# Contents")
    @division.to_csv.should include(%Q|"Appleton, L.", [Teller]\n"Brown, L.", [Teller]|)
  end

  it 'should include Not-Contents tellers' do
    peer = 'name, [Teller]'
    @division.stub!(:not_content_vote_names).with(', [Teller]').and_return [peer]
    @division.to_csv.should include("\n\n# Not-Contents")
    @division.to_csv.should include(%Q|"name", [Teller]|)
  end

end
