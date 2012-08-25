require File.dirname(__FILE__) + '/../spec_helper'

describe Volume, " when giving its name" do

  it 'should give "Volume 235" if its number is 235 and part is zero' do
    Volume.new(:number => 235, :part => 0).name.should == "Volume 235"
  end

  it 'should give "Volume 235 (Part 2)" if its number is 235 and part is 2' do
    Volume.new(:number => 235, :part => 2).name.should == "Volume 235 (Part 2)"
  end

end

describe Volume, 'on creation' do

  def expect_regnal_years text, first, last
    volume = Volume.new :regnal_years => text
    volume.should be_valid
    volume.first_regnal_year.should == first
    volume.last_regnal_year.should == last
  end
  
  def expect_monarch original, expected
    volume = Volume.new :monarch => original
    volume.valid?
    volume.monarch.should == expected
  end

  it 'should populate first regnal year and last regnal year with 17 from regnal years "SEVENTEENTH"' do
    expect_regnal_years("SEVENTEENTH", 17, 17)
  end

  it 'should populate first regnal year and last regnal year with 53 from regnal years "FIFTY-THIRD"' do
    expect_regnal_years("FIFTY-THIRD", 53, 53)
  end

  it 'should populate first regnal year and last regnal year with 18 and 19 from regnal years "18 &amp; 19"' do
    expect_regnal_years("18 &amp; 19", 18, 19)
  end

  it 'should populate first regnal year and last regnal year with 5 and 6 from regnal years "5 &amp; 6"' do
    expect_regnal_years("5 &amp; 6", 5, 6)
  end

  it 'should populate first regnal year and last regnal year with 48 from regnal years "48#x00B0;"' do
    expect_regnal_years("48#x00B0;", 48, 48)
  end

  it 'should populate first regnal year and last regnal year with 48 from regnal years ""' do
    expect_regnal_years("FORTY-EIGHTH", 48, 48)
  end
  
  it 'should set a monarch of "VICTORI&#x00C6;" to "VICTORIA"' do 
    expect_monarch("VICTORI&#x00C6;", 'VICTORIA')
  end
  
  it 'should set a monarch of "ELIZABETH" to "ELIZABETH II"' do 
    expect_monarch("ELIZABETH", 'ELIZABETH II')
  end
  
end

describe Volume, " when finding volumes by identifiers" do

  before do
    Series.stub!(:find_by_series).with('5L').and_return(mock_model(Series, :id => 4))
  end

  it 'should look for the series corresponding to the series number passed to it' do
    Series.should_receive(:find_by_series).with('5L').and_return(mock_model(Series))
    Volume.find_all_by_identifiers('5L', 102, 1)
  end

  it 'should return an empty list if there is no series corresponding to the series number passed to it' do
    Series.should_receive(:find_by_series).with('5L').and_return(nil)
    Volume.find_all_by_identifiers('5L', 102, 1).should == []
  end

  it 'should look for volumes by series, number and part if a part is specified and the series exists' do
    Volume.should_receive(:find_all_by_series_id_and_number_and_part).with(4, 102, 1)
    Volume.find_all_by_identifiers('5L', 102, 1)
  end

  it 'should look for volumes by series and number sorted by part if no part is specified and the series exists' do
    Volume.should_receive(:find_all_by_series_id_and_number).with(4, 102, :order => "part asc")
    Volume.find_all_by_identifiers('5L', 102, nil)
  end

end

describe Volume, " when creating an id hash" do

  before do
    @series = mock_model(Series, :id_hash => {})
    @volume = Volume.new(:series => @series,
                         :number => 4,
                         :part => 2)
  end

  it 'should ask its series for an id hash' do
    @series.should_receive(:id_hash).and_return({})
    @volume.id_hash
  end

  it 'should return the series id hash updated with its volume number' do
    @volume.id_hash[:volume_number].should == 4
  end

  it 'should return the series id hash updated with its part it has a non-zero part' do
    @volume.id_hash[:part].should == 2
  end

  it 'should not return a hash with a part key if it doesn\'t have a non-zero part' do
    @volume.part = 0
    @volume.id_hash.should_not have_key(:part)
  end
end

describe Volume, " when asked for its house" do

  before do
    @series = mock_model(Series, :house => "commons")
    @volume = Volume.new(:series => @series)
  end

  it 'should return its series\' house if its series house is "commons"' do
    @volume.house.should == 'commons'
  end

  it 'should return nil if its series\' house is "both"' do
    @series.stub!(:house).and_return('both')
    @volume.house.should be_nil
  end

end

describe Volume, ' when extracting a start and end date from period text' do

  def expect_dates(period, start_date, end_date, year=nil)
    start_date = Date.parse(start_date)
    end_date = Date.parse(end_date)
    Volume.start_and_end_date_from_period(period, year).should == [start_date, end_date]
  end
  
  it 'should extract 1942-11-11 and 1943-11-23 from "11th NOVEMBER, 1942 to 23rd NOVEMBER, 1943"' do 
    expect_dates('11th NOVEMBER, 1942 to 23rd NOVEMBER, 1943', '1942-11-11', '1943-11-23')
  end

  it 'should extract 24/06/1996 and 04/07/1996 from "24 June&#x2013;4 July 1996"' do
    expect_dates('24 June&#x2013;4 July 1996', '1996-06-24', '1996-07-04')
  end

  it 'should extract 1805-01-15 and 1805-03-12 from "BETWEEN THE 15th OF JANUARY AND THE 12th OF MARCH 1805"' do
    expect_dates('BETWEEN THE 15th OF JANUARY AND THE 12th OF MARCH 1805', '1805-01-15', '1805-03-12')
  end
  
  it 'should extract 1803-11-22 and 1804-03-29 from "BETWEEN 22d NOVEMBER, 1803, AND 29th MARCH, 1804"' do 
    expect_dates("BETWEEN 22d NOVEMBER, 1803, AND 29th MARCH, 1804", "1803-11-22", "1804-03-29")
  end
  
  it 'should extract 1839-08-07 and 1839-08-27 from "THE SEVENTH DAY OF AUGUST, TO THE TWENTY-SEVENTH, 1839"' do 
    expect_dates("THE SEVENTH DAY OF AUGUST, TO THE TWENTY-SEVENTH, 1839", '1839-08-07', '1839-08-27')
  end
  
  it 'should extract from "THE SEVENTH TO THE TWENTY-THIRD DAY OF JULY, 1847"' do 
    expect_dates("THE SEVENTH TO THE TWENTY-THIRD DAY OF JULY, 1847", '1847-07-07', '1847-07-23')
  end
  
  it 'should extract dates from "TUESDAY, SEVENTH DAY O F MAY, 1907, TO WEDNESDAY, TWENTY-NINTH DAY OF MAY, 1907"' do 
    expect_dates("TUESDAY, SEVENTH DAY O F MAY, 1907, TO WEDNESDAY, TWENTY-NINTH DAY OF MAY, 1907", '1907-05-07', '1907-05-29')
  end
  
  it 'should extract dates from "Monday, September 20th, 1909, to Friday, October 8th, 1909"' do 
    expect_dates("Monday, September 20th, 1909, to Friday, October 8th, 1909", '1909-09-20', '1909-10-08')
  end

  it 'should extract dates from "MONDAY, 26TH MARCH, TO FRIDAY, 2OTH APRIL, 1923"' do 
    expect_dates("MONDAY, 26TH MARCH, TO FRIDAY, 2OTH APRIL, 1923", '1923-03-26', '1923-04-20')
  end
  
  it 'should extract dates from "11 FEBRUARY.to 1 MARCH, 1946"' do 
    expect_dates("11 FEBRUARY.to 1 MARCH, 1946", '1946-02-11', '1946-03-01')
  end
  
  it 'should extract dates from "13th JULY to 5th AUGUST 1943"' do 
    expect_dates("13th JULY to 5th AUGUST 1943", '1943-07-13', '1943-08-05')
  end
  
  it 'should extract dates from "10th&#x2014;21st, DECEMBER 1962"' do 
    expect_dates("10th&#x2014;21st, DECEMBER 1962", '1962-12-10', '1962-12-21')
  end
    
  it 'should extract dates from "28th JUNE,1971&#x2013;9th JULY,1971"' do 
    expect_dates("28th JUNE,1971&#x2013;9th JULY,1971", '1971-06-28', '1971-07-09')
  end
  
  it 'should extract dates from "30th JANUARY&#x2014;10th FEBRUARY1978"' do 
    expect_dates("30th JANUARY&#x2014;10th FEBRUARY1978", '1978-01-30', '1978-02-10')
  end
  
  it 'should extract dates from "2 MARCH&#x0214;13 MARCH 1981"' do 
    expect_dates("2 MARCH&#x0214;13 MARCH 1981", '1981-03-02', '1981-03-13')
  end
  
  it 'should extract dates from "TUESDAY, 28TH OCTOBER, 1930, TO THURSDAY,19TH FEBRUARY, 1931"' do 
    expect_dates("TUESDAY, 28TH OCTOBER, 1930, TO THURSDAY,19TH FEBRUARY, 1931", '1930-10-28', '1931-02-19')
  end
  
  it 'should extract dates from "MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936"' do 
    expect_dates("MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936", '1936-07-20', '1936-10-30')
  end
  
  it 'should extract dates from "WEDNESDAY, 29th NOVEMBER, 1944, to THURSDAY, i5th FEBRUARY, 1945"' do 
    expect_dates("WEDNESDAY, 29th NOVEMBER, 1944, to THURSDAY, i5th FEBRUARY, 1945", '1944-11-29', '1945-02-15')
  end

  it 'should extract dates from "Tuesday, 19th October, 1920, to Wednesday, 8th, December, 1920"' do 
    expect_dates("Tuesday, 19th October, 1920, to Wednesday, 8th, December, 1920", '1920-10-19', '1920-12-08')
  end
  
  it 'should extract dates from "17 October 3 November 1994"' do 
    expect_dates("17 October 3 November 1994", '1994-10-17', '1994-11-03')
  end
  
  it 'should extract dates from "Monday, 7th October, 1912, to Friday, 25th October, 1912"' do 
    expect_dates("Monday, 7th October, 1912, to Friday, 25th October, 1912", '1912-10-07', '1912-10-25')
  end
  
  it 'should extract dates from "MONDAY, 9TH OCTOBER TO THURSDAY, 2ND NOVEMBER, 1939"' do 
    expect_dates("MONDAY, 9TH OCTOBER TO THURSDAY, 2ND NOVEMBER, 1939", '1939-10-09', '1939-11-02')
  end
  
  it 'should extract dates from "7DECEMBER&#x2014;18DECEMBER 1987"' do 
    expect_dates("7DECEMBER&#x2014;18DECEMBER 1987", '1987-12-07', '1987-12-18')
  end
  
  it 'should extract dates from "THE SEVENTH DAY OF AUGUST TO THE NINTH DAY OF AUGUST"' do 
    expect_dates("THE SEVENTH DAY OF AUGUST TO THE NINTH DAY OF AUGUST", '1899-08-07', '1899-08-09', 1899)
  end
  
  it 'should extract 07/06/2004 and 24/06/2004 from "7 June&#x2014;24 June 2004"' do
    expect_dates("7 June&#x2014;24 June 2004", '2004-06-07', '2004-06-24')
  end

  it 'should extract 03/11/1982 and 02/12/1982 from "WEDNESDAY, 3rd NOVEMBER,&#x2014;THURSDAY, 2nd DECEMBER 1982"' do
    expect_dates("WEDNESDAY, 3rd NOVEMBER,&#x2014;THURSDAY, 2nd DECEMBER 1982", '1982-11-03', '1982-12-02')
  end

  it 'should extract 15/05/1928 and 03/08/1928 from "TUESDAY, 15TH MAY, TO FRIDAY, 3RD AUGUST, 1928"' do
    expect_dates("TUESDAY, 15TH MAY, TO FRIDAY, 3RD AUGUST, 1928", '1928-05-15', '1928-08-03')
  end
  
  it 'should extract 15/12/1980 and 16/01/1981 from "15 DECEMBER 1980&#x2013;16 JANUARY 1981"' do
    expect_dates("15 DECEMBER 1980&#x2013;16 JANUARY 1981", '1980-12-15', '1981-01-16')
  end

  it 'should extract 12/01/1976 and 23/01/1976 from "12th&#x2014;23rd JANUARY 1976"' do
    expect_dates("12th&#x2014;23rd JANUARY 1976", '1976-01-12', '1976-01-23')
  end

  it 'should extract 25/06/1957 and 05/07/1957 from "25th JUNE&#x2014;5th JULY, 1957"' do
    expect_dates("25th JUNE&#x2014;5th JULY, 1957", '1957-06-25', '1957-07-05')
  end

  it 'should extract 21/08/1889 and 30/08/1889 from "THE TWENTY-FIRST DAY OF AUGUST, 1889, TO THE THIRTIETH DAY OF AUGUST, 1889"' do
    expect_dates("THE TWENTY-FIRST DAY OF AUGUST, 1889, TO THE THIRTIETH DAY OF AUGUST, 1889", '1889-08-21', '1889-08-30')
  end

  it 'should extract 10/11/1908 and 23/11/1908 from "TUESDAY, TENTH DAY OF NOVEMBER, 1908, TO MONDAY, TWENTY-THIRD OF NOVEMBER, 1908"' do
    expect_dates("TUESDAY, TENTH DAY OF NOVEMBER, 1908, TO MONDAY, TWENTY-THIRD OF NOVEMBER, 1908", '1908-11-10', '1908-11-23')
  end

  it 'should extract 15/03/2003 and 01/04/2003 from "MONDAY, 15TH MARCH, TO FRIDAY 1ST APRIL." if the start date of the source file is in 2003' do
    expect_dates("MONDAY, 15TH MARCH, TO FRIDAY 1ST APRIL.", '2003-03-15', '2003-04-01', 2003)
  end

  it 'should extract 11/12/1972 and 22/12/1972 from "1lth&#x2013;22nd DECEMBER, 1972"' do
    expect_dates("1lth&#x2013;22nd DECEMBER, 1972", '1972-12-11', '1972-12-22')
  end

  it 'should extract 1905-03-31 and 1905-04-12 from "THE THIRTY-FIRST DAY OF MARCH TO THE TWELFTH DAY OF APRIL, 1905"' do
    expect_dates("THE THIRTY-FIRST DAY OF MARCH TO THE TWELFTH DAY OF APRIL, 1905", '1905-03-31', '1905-04-12')
  end

  it 'should extract 1942-07-28 and 1942-11-10 from "TUESDAY, 28th JULY, to TUESDAY, 10th NOVEMBER, 1942"' do
    expect_dates("TUESDAY, 28th JULY, to TUESDAY, 10th NOVEMBER, 1942", '1942-07-28', '1942-11-10')
  end

  it 'should extract 1940-03-04 and 1940-03-21 from "4 MARCH, To 21 MARCH, 1940"' do
    expect_dates("4 MARCH, To 21 MARCH, 1940", '1940-03-04', '1940-03-21')
  end

  it 'should extract "1947-01-21" and "1947-02-07" from "21st JANUARY to 7th FEBRUARY, 1947"' do
    expect_dates("21st JANUARY to 7th FEBRUARY, 1947", "1947-01-21", "1947-02-07")
  end

  it 'should extract "1992-07-13" and "1992-11-05" from MONDAY,13th JULY-THURSDAY,5th NOVEMBER 1992"' do
    expect_dates("MONDAY,13th JULY-THURSDAY,5th NOVEMBER 1992", "1992-07-13", "1992-11-05")
  end

  it 'should extract "1988-12-05" and "1988-12-16" from "5 DECEMBER-16 DECEMBER 1988"' do
    expect_dates("5 DECEMBER-16 DECEMBER 1988", "1988-12-05", "1988-12-16")
  end

  it 'should extract "1912-07-15" and "1912-08-07" from "Comprising period from Monday, 15th July, 1912, to Wednesday, 7th August, 1912."' do
    expect_dates("Comprising period from Monday, 15th July, 1912, to Wednesday, 7th August, 1912.", "1912-07-15", "1912-08-07")
  end

  it 'should extract "1913-07-28" and "1913-08-15" from "Comprising period from Monday, 28th July, 1913, to Friday, 15th August, 1913."' do
    expect_dates("Comprising period from Monday, 28th July, 1913, to Friday, 15th August, 1913.", "1913-07-28", "1913-08-15")
  end

  it 'should extract "1938-07-04" and "1938-08-29" from "MONDAY 4TH JULY TO FRIDAY 29TH JULY, 1938"' do
    expect_dates("MONDAY 4TH JULY TO FRIDAY 29TH JULY, 1938", "1938-07-04", "1938-07-29")
  end

  it 'should extract "1898-06-13" and "1898-06-23" from "THE THIRTEENTH DAY OF JUNE TO THE TWENTY-THIRD DAY OF JUNE 1898"' do 
    expect_dates("THE THIRTEENTH DAY OF JUNE TO THE TWENTY-THIRD DAY OF JUNE 1898", "1898-06-13", "1898-06-23" )
  end
  
  it 'should extract dates from "WEDNESDAY 28TH SEPTEMBER AND MONDAY 3RD OCTOBER TO THURSDAY 6TH OCTOBER, 1938"' do 
    expect_dates('WEDNESDAY 28TH SEPTEMBER AND MONDAY 3RD OCTOBER TO THURSDAY 6TH OCTOBER, 1938', '1938-09-28', '1938-10-06')
  end
  
  it 'should extract dates from "MONDAY, 15TH JUNE, TO FRIDAY, 3RD JULY"' do 
    expect_dates("MONDAY, 15TH JUNE, TO FRIDAY, 3RD JULY", '1925-06-15', '1925-07-03', 1925)
  end
  
  it 'should extract dates from "3rd&#x2014;11th November"' do 
    expect_dates("3rd&#x2014;11th November", '1925-11-03', '1925-11-11', 1925)
  end
  
  it 'should extract dates from "MONDAY, 9th MAY&#x2014;THURSDAY, 26th MAY"' do 
    expect_dates("MONDAY, 9th MAY&#x2014;THURSDAY, 26th MAY", '1925-05-09', '1925-05-26', 1925)
  end
  
  it 'should extract dates from "MONDAY, 4th JULY&#x2014;FRIDAY, 15th JULY"' do 
    expect_dates("MONDAY, 4th JULY&#x2014;FRIDAY, 15th JULY", '1925-07-04', '1925-07-15', 1925)
  end
  
  it 'should extract dates from "8 JUNE&#x2014;19 JUNE"' do 
    expect_dates("8 JUNE&#x2014;19 JUNE", '1925-06-08', '1925-06-19', 1925)
  end
  
  it 'should extract dates from "22nd October&#x2014;29th November"' do 
    expect_dates("22nd October&#x2014;29th November", '1925-10-22', '1925-11-29', 1925)
  end
  
  it 'should extract dates from "TUESDAY, 19th APRIL&#x2014;THURSDAY 5th MAY"' do 
    expect_dates("TUESDAY, 19th APRIL&#x2014;THURSDAY 5th MAY", '1925-04-19', '1925-05-05', 1925)
  end
  
  it 'should extract dates from "8 APRIL&#x2014;18 APRIL "' do 
    expect_dates("8 APRIL&#x2014;18 APRIL", '1925-04-08', '1925-04-18', 1925)
  end
  
  it 'should extract dates from "THE FIFTH DAY OF JUNE 1882, THE TWENTY-FIRST DAY OF JUNE 1882"' do 
    expect_dates('THE FIFTH DAY OF JUNE 1882, THE TWENTY-FIRST DAY OF JUNE 1882', '1882-06-05', '1882-06-21')
  end
  
  it 'should extract dates from "THIRTEENTH AND FOURTEENTH DAYS OF AUGUST, 1885"' do 
    expect_dates('THIRTEENTH AND FOURTEENTH DAYS OF AUGUST, 1885', '1885-08-13', '1885-08-14')
  end
  
  it 'should extract dates from "MONDAY, 7TH DECEMBER TO TUESDAY, 22ND DECEMBER"' do 
    expect_dates('MONDAY, 7TH DECEMBER TO TUESDAY, 22ND DECEMBER', '1922-12-07', '1922-12-22', 1922)
  end
  
  it 'should extract dates from "MONDAY, 13TH MARCH TO THURSDAY, 5TH APRIL, 19<ob></ob>"' do 
    expect_dates('MONDAY, 13TH MARCH TO THURSDAY, 5TH APRIL, 19<ob></ob>', '1992-03-13', '1992-04-05', 1992)
  end
 
end

describe Volume, " when asked for percent success statistics" do

  before do
    @volume = Volume.new
    @volume.stub!(:sittings_count).and_return(4)
    @volume.stub!(:sittings_tried_count).and_return(10)
  end

  it 'should return 40 if it has tried 10 sittings and loaded 4 sittings' do
    @volume.percent_success.should == 40
  end
  
  it 'should return 0 if it has tried 0 sittings and loaded 0 sittings' do 
    @volume.stub!(:sittings_count).and_return(0)
    @volume.stub!(:sittings_tried_count).and_return(0)
    @volume.percent_success.should == 0
  end

end

describe Volume, 'when asked for missing column numbers' do 
  
  before do 
    @source_file = mock_model(SourceFile, :missing_columns => [])
    @volume = Volume.new
    @volume.stub!(:source_file).and_return(@source_file)
    @volume.stub!(:missing_first_column?)
  end
  
  it 'should return 1 if it is missing the first column' do 
    @volume.stub!(:missing_first_column?).and_return(true)
    @volume.missing_column_numbers.should == [1]
  end
  
  it "should return it's source files's missing columns" do 
    @source_file.stub!(:missing_columns).and_return([4,5])
    @volume.missing_column_numbers.should == [4,5]
  end
  
end

describe Volume, 'when asked if it has missing sittings' do 
  
  before do
    @volume = Volume.new
  end
  
  it 'should return true if the volume\'s percent loading success is less than 100' do
    @volume.stub!(:percent_success).and_return(98)
    @volume.missing_sittings?.should be_true
  end
  
end

describe Volume, " when asked if it has missing columns" do

  before do
    @sitting = mock_model(Sitting, :start_column => '1',
                                   :missing_columns? => false)
    @source_file = mock_model(SourceFile, :missing_columns => [])
    @volume = Volume.new(:part => 1, 
                         :sittings => [@sitting],
                         :source_file => @source_file)
    @volume.stub!(:percent_success).and_return(100)
  end

  it 'should return true if it is the first or only volume and has sittings and the number part of the first sitting\'s first column is not one' do
    @volume.part = 1
    @sitting.stub!(:start_column).and_return(2)
    @volume.missing_columns?.should be_true
  end
  
  it 'should return false if it is not the first or only volume and the only problem is that the columns in the first sitting do not start at one' do 
    @volume.part = 2
    @sitting.stub!(:start_column).and_return(2)
    @volume.missing_columns?.should be_false
  end
  
  it 'should return true if there are log messages about missing columns' do 
    @source_file.stub!(:missing_columns).and_return(["Missing image? Got: 111, expected 110 (last image 109)\n"])
    @volume.missing_columns?.should be_true
  end

  it 'should return false if the first sittings first column is 1 and no sitting has a missing column and there are no missing column log messages' do
    @volume.missing_columns?.should be_false
  end
  
end

describe Volume, " when asked for sittings by date and column" do

  it 'should sort columns by their date and column sort params' do
    first_sitting = mock_model(Sitting)
    second_sitting = mock_model(Sitting)
    first_sitting.should_receive(:date_and_column_sort_params).and_return([1,1,1])
    second_sitting.should_receive(:date_and_column_sort_params).and_return([2,3,4])
    volume = Volume.new
    volume.stub!(:sittings).and_return([second_sitting, first_sitting])
    volume.sittings_by_date_and_column.should == [first_sitting, second_sitting]
  end

end

describe Volume, 'when asking for session start and end years' do

  before do
    parliament_session = mock_model(ParliamentSession, :start_year => 1984, :end_year => 1985)
    @volume = Volume.new(:start_date=>Date.new(1985,1,12), 
                         :end_date=>Date.new(1986,6,12), 
                         :parliament_session => parliament_session)
  end

  it 'should be able to give its start year' do
    @volume.start_year.should == 1985
  end

  it 'should be able to give its end year' do
    @volume.end_year.should == 1986
  end

  it 'should be able to give its session start year' do
    @volume.session_start_year.should == 1984
  end

  it 'should be able to give its session end year' do
     @volume.session_end_year.should == 1985
  end
  
  it 'should return nil when asked for session start year if it has no parliament session' do 
    @volume.stub!(:parliament_session)
    @volume.session_start_year.should be_nil
  end
  
  it 'should return nil when asked for session end year if it has no parliament session' do 
    @volume.stub!(:parliament_session)
    @volume.session_end_year.should be_nil
  end
end
