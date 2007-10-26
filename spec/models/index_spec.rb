require File.dirname(__FILE__) + '/../spec_helper'

describe Index, ', the class' do
  it 'should respond to find_by_date_span' do
    lambda {Index.find_by_date_span('1999-02-08', '1999-03-04')}.should_not raise_error
  end
end

describe Index, "find_all_in_groups_by_decade" do

  it "should return array of decade groups, each group being an array of index instances sorted date" do
    index_1919 = Index.create :title => 'APRIL 1 – JUNE 30 1919.',
      :start_date => Date.new(1919,4,1),
      :end_date => Date.new(1919,6,30)
    index_1918 = Index.create :title => 'JANUARY 29 – FEBRUARY 6 1918.',
      :start_date => Date.new(1918,1,29),
      :end_date => Date.new(1918,2,6)

    index_1956b = Index.create :title => '1st May – 22nd June 1956',
      :start_date => Date.new(1956,5,1),
      :end_date => Date.new(1956,6,22)
    index_1956a = Index.create :title => '28th February – 26th April 1956',
      :start_date => Date.new(1956,2,28),
      :end_date => Date.new(1956,4,26)

    groups = Index.find_all_in_groups_by_decade
    groups.size.should == 2
    groups[0][0].should == index_1918
    groups[0][1].should == index_1919

    groups[1][0].should == index_1956a
    groups[1][1].should == index_1956b
    Index.delete_all
  end

end

describe Index, ".find_by_date_span" do

  it "should return the first index whose start and end dates match those passed" do
    start_date = Date.new(2007, 1, 1)
    end_date = Date.new(2007, 6, 6)
    index = Index.create(:start_date => start_date,
                         :end_date   => end_date)
    Index.find_by_date_span(start_date.to_s, end_date.to_s).should == index
    Index.delete_all
  end

end

describe Index, ".entries, when supplied a letter of the alphabet" do

  it "should find index entries belonging to the index, and with the correct letter" do
    index = Index.create()
    entries = mock("index entries")
    index.stub!(:index_entries).and_return(entries)
    letter = "F"
    entries.should_receive(:find).with(:all, :conditions => ["letter = ?", letter])
    index.entries("F")
    Index.delete_all
  end

end

describe Index, " destroy" do

  it 'should destroy index_entries' do
    index = Index.create :title => 'APRIL 1 – JUNE 30 1919.',
      :start_date => Date.new(1919,4,1),
      :end_date => Date.new(1919,6,30)

    entry = IndexEntry.new(:text          => 'Alien Enemies',
                          :entry_context => '',
                          :letter        => 'A')
    child_entry = IndexEntry.new(:text          => 'German combatant prisoners, number and work of, 398.',
                           :entry_context => '',
                           :letter        => 'A',
                           :parent_entry  => entry)

    index.index_entries << entry
    index.index_entries << child_entry
    index.save!

    Index.find(:all).size.should == 1
    IndexEntry.find(:all).size.should == 2

    index.destroy

    Index.find(:all).size.should == 0
    IndexEntry.find(:all).size.should == 0
  end

end

describe Index, 'on creation' do

  before(:each) do
    @session = ParliamentSession.new
    @session.save!
    @index = Index.new :parliament_session_id => @session.id
  end

  after do
    ParliamentSession.delete_all
  end

  it "should be valid" do
    @index.should be_valid
  end

  it 'should be associated with parliament session' do
    @index.parliament_session.should == @session
  end

end
