require File.dirname(__FILE__) + '/../spec_helper'

describe DateParser do


  before do
    @mock_results = mock("search results")
    @mock_results.stub!(:facets).and_return({"facet_fields" => []})
    @mock_results.stub!(:total_hits)
    Sitting.stub!(:find_in_resolution).and_return([mock_model(Sitting)])
    Contribution.stub!(:find_by_solr).and_return(@mock_results)
  end

  it 'should return a date_match of 15 Feb 1910 from text "15 Feb 1910, c. 999"' do
    DateParser.date_match("15 Feb 1910, c. 999").should == {:year => 1910, 
                                                            :month => 'feb', 
                                                            :day => 15, 
                                                            :resolution => :day}
  end

  it 'should return a date_match of 15 Feb 1910 from text "15 Feb 1910, c999"' do
    DateParser.date_match("15 Feb 1910, c999").should == {:year => 1910, 
                                                          :month => 'feb', 
                                                          :day => 15, 
                                                          :resolution => :day}
  end

  it 'should return a date_match of 15 Feb 1910 from text "Tuesday, 15th February, 1910."' do
    DateParser.date_match("Tuesday, 15th February, 1910.").should == {:year => 1910, 
                                                                      :month => 'feb', 
                                                                      :day => 15, 
                                                                      :resolution => :day}
  end

  it 'should return a date_match of 15 Feb 1910 from text "Tuesday 15 February 1910"' do
    DateParser.date_match("Tuesday 15 February 1910").should == {:year => 1910, 
                                                                 :month => 'feb', 
                                                                 :day => 15, 
                                                                 :resolution => :day}
  end

  it 'should return a date_match of 15 Feb 1910 from text "15 Feb 1910"' do
    DateParser.date_match("15 Feb 1910").should == {:year => 1910, 
                                                    :month => 'feb', 
                                                    :day => 15, 
                                                    :resolution => :day}
  end

  it 'should return a date_match of Feb 1910 from text "February 1910."' do
    DateParser.date_match("February 1910.").should == {:year => 1910, 
                                                       :month => 'feb', 
                                                       :resolution => :month}
  end

  it 'should return a date_match of Feb 1910 from text "Feb 1910"' do
    DateParser.date_match("Feb 1910").should == {:year => 1910, 
                                                 :month => 'feb', 
                                                 :resolution => :month}
  end

  it 'should return a date_match of 1910 from text "1910."' do
    DateParser.date_match("1910.").should == {:year => 1910, :resolution => :year}
  end

  it 'should return a date_match of 1910 from text "1910"' do
    DateParser.date_match("1910").should == {:year => 1910, :resolution => :year}
  end

  it 'should not return a date_match from text with a date in the future such as "2010"' do
    DateParser.date_match("2010").should be_nil
  end

  it 'should not return a date_match from text with a date in the future such as "Feb 2010"' do
    DateParser.date_match("Feb 2010").should be_nil
  end

  it 'should not assign a date_match when given a query with a date in the future such as "28 Feb 2010"' do
    DateParser.date_match("28 Feb 2010").should be_nil
  end

  it 'should assign a date_match of 22 October 2002 when given a query of "22 October 2002, Official Report, columns 182–83"' do
    DateParser.date_match("22 October 2002, Official Report, columns 182–83").should == {:year => 2002, 
                                                                                         :month => 'oct', 
                                                                                         :day => 22, 
                                                                                         :resolution => :day}
  end

  it 'should not assign a date match for when given a date for which no material is present' do
    Sitting.stub!(:find_in_resolution).and_return([])
    DateParser.date_match("28 Feb 1911").should be_nil
  end

end
