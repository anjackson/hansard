require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::IndexParser do
  
  before(:all) do
    file = 'index_example.xml'
    @index = Hansard::IndexParser.new(File.dirname(__FILE__) + "/../data/#{file}").parse
    @index.save!
    @first_index_entry =  @index.index_entries[0]
    @second_index_entry = @index.index_entries[1]
  end
  
  it "should create an index model" do
    @index.should_not be_nil
    @index.should be_a_kind_of Index
  end
  
  it "should set the title of the index model" do
    @index.title.should == "INDEX TO THE<lb/> PARLIAMENTARY DEBATES"
  end
  
  it "should set the start date text of the index model" do
    @index.start_date_text.should == "16th December 1985"
  end
  
  it "should set the end date text of the index model" do
    @index.end_date_text.should == "17th January 1986"
  end
  
  it "should set the start date of the index model" do
    @index.start_date.should == Date.new(1985, 12, 16)
  end
  
  it "should set the end date of the index model" do
    @index.end_date.should == Date.new(1986, 1, 17)
  end
  
  it "should create the first index entry for the index with text 'Abortion deaths 81&#x2013;4w' and letter 'A'" do
    @first_index_entry.text.should == "Abortion deaths 81&#x2013;4w"
  end
  
  it "should create the second index entry for the index with text 'Scotland 63&#x2013;4w' and parent the first index entry" do
    @second_index_entry.text.should == 'Scotland 63&#x2013;4w'
    @second_index_entry.parent_entry.should == @first_index_entry
  end
  
  it "should set the letter on the first index entry" do
    @first_index_entry.letter.should == 'A'
  end
  
  it "should set the context on an index entry that appears under a context" do
    context_entry = @index.index_entries[5]
    context_entry.text.should == 'Hong Kong, Nationality (16.01.86) 1272, 1273, 1292&#x2013;5'
    context_entry.entry_context.should == "Debates etc"
  end
  
  it "should clear the context on entries that appear under a top level entry after an entry that had context set on it" do
    new_top_level_entry_after_context = @index.index_entries[14]
    new_top_level_entry_after_context.text.should == "Administrative costs"
    new_top_level_entry_after_context.entry_context.should be_nil
  end
  
  after(:all) do
    Index.delete_all
    IndexEntry.delete_all
  end

end