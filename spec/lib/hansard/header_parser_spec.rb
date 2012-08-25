require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::HeaderParser do

  describe 'when extracting member lists from the example header' do
    before(:all) do
      file = 'header_with_commons_member_list.xml'
      xml = File.open(data_file_path(file))
      @doc = Hpricot.XML xml
      @header_parser = Hansard::HeaderParser.new(nil, nil,nil)
    end

    it 'should extract 660 members from the example header' do
      @header_parser.extract_members(@doc).size.should == 661
    end

    it 'should return an array of array with no nil elements' do
      @header_parser.extract_members(@doc).select{|element| element.nil? }.should == []
    end

    it 'should return an empty list if there is no member list' do
      file = 'header_example.xml'
      doc = Hpricot.XML File.open(data_file_path(file))
      @header_parser.extract_members(doc).should == []
    end

    it 'should extract from "Stewart, Ian (Eccles)"' do
      attributes = { :lastname => 'Stewart',
                     :firstnames => 'Ian',
                     :constituency => 'Eccles'}
      @header_parser.member_and_constituency('Stewart, Ian (Eccles)').should == [attributes]
    end

    it 'should extract from "Stinchcombe. Paul David (Wellingborough)"' do
      attributes = { :lastname => 'Stinchcombe',
                     :firstnames => 'Paul David',
                     :constituency => 'Wellingborough'}
      @header_parser.member_and_constituency('Stinchcombe. Paul David (Wellingborough)').should == [attributes]
    end

    it 'should extract from "Powell, Sir Raymond (Ogmore) [<i>died, December 2001</i>]"' do
      text = "Powell, Sir Raymond (Ogmore) [<i>died, December 2001</i>]"
      attributes = { :lastname => "Powell",
                     :firstnames => 'Sir Raymond',
                     :constituency => 'Ogmore',
                     :transition_reason => 'died',
                     :transition_date => 'December 2001' }
      @header_parser.member_and_constituency(text).should == [attributes]
    end
    
    it 'should extract from "Gibb, J. ((Middlesex, Harrow)"' do 
      text = 'Gibb, J. ((Middlesex, Harrow)'
      attributes = { :lastname => 'Gibb', 
                     :firstnames => 'J.', 
                     :constituency => 'Middlesex, Harrow'}
      @header_parser.member_and_constituency(text).should == [attributes]                     
    end
    
    it 'should extract from "Long, Col. Charles W. (Worcestershire, Evesham"' do 
      text = 'Long, Col. Charles W. (Worcestershire, Evesham'
      attributes = { :lastname => 'Long', 
                     :firstnames => 'Col. Charles W.', 
                     :constituency => 'Worcestershire, Evesham'}
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "&#x00D6;pik, Lembit (Montgomeryshire)"' do
      text = "&#x00D6;pik, Lembit (Montgomeryshire)"
      attributes = { :lastname => "&#x00D6;pik",
                     :firstnames => 'Lembit',
                     :constituency => 'Montgomeryshire'}
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Anderson. Rt. Hon. Donald (Swansea, East)"' do
      text = "Anderson. Rt. Hon. Donald (Swansea, East)"
      attributes = { :lastname => "Anderson",
                     :firstnames => 'Rt. Hon. Donald',
                     :constituency => 'Swansea, East'}
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Daisley, Paul Andrew (Brent, East) <i>[died, June 2003]</i>"' do
      text = "Daisley, Paul Andrew (Brent, East) <i>[died, June 2003]</i>"
      attributes = { :lastname => "Daisley",
                     :firstnames => "Paul Andrew",
                     :constituency => 'Brent, East',
                     :transition_reason => "died",
                     :transition_date => "June 2003" }
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Canavan, Dennis Andrew (Falkirk, West) [<i>resigned November 2000</i>]"' do
      text = "Canavan, Dennis Andrew (Falkirk, West) [<i>resigned November 2000</i>]"
      attributes = { :lastname => "Canavan",
                     :firstnames => "Dennis Andrew",
                     :constituency => 'Falkirk, West',
                     :transition_reason => "resigned",
                     :transition_date => "November 2000" }
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Chisholm, Malcolm George Richardson (Edinburgh, North\r\nand Leith)"' do
      text = "Chisholm, Malcolm George Richardson (Edinburgh, North\r\nand Leith)"
      attributes = { :constituency=>"Edinburgh, North and Leith",
                     :lastname=>"Chisholm",
                     :firstnames=>"Malcolm George Richardson" }
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Robertson, George Islay MacNeill (Hamilton, South) [<i>life peerage, August 1999</i>]"' do
      text = "Robertson, George Islay MacNeill (Hamilton, South) [<i>life peerage, August 1999</i>]"
      attributes = { :constituency=>"Hamilton, South",
                     :lastname=>"Robertson",
                     :firstnames=>"George Islay MacNeill",
                     :transition_reason => "life peerage",
                     :transition_date => "August 1999" }
      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from "Kellett-Bowman Dame Mary Elaine (Lancaster)"' do
      text = "Kellett-Bowman Dame Mary Elaine (Lancaster)"
      attributes = { :constituency => 'Lancaster',
                     :lastname => 'Kellett-Bowman',
                     :firstnames => 'Dame Mary Elaine'}

      @header_parser.member_and_constituency(text).should == [attributes]
    end

    it 'should extract from ""' do
      text = "Page, Arthur John (Harrow, West) Page, Rt. Hon. Rodney Graham, MBE (Crosby)"
      first_attributes = { :constituency => "Harrow, West",
                           :lastname => "Page",
                           :firstnames => "Arthur John" }
      second_attributes = { :constituency => "Crosby",
                            :lastname => "Page",
                            :firstnames => "Rt. Hon. Rodney Graham, MBE"}
      @header_parser.member_and_constituency(text).should == [first_attributes, second_attributes]
    end
  end

  describe 'when getting clean paras' do
    before do
      @parser = Hansard::HeaderParser.new(nil, nil, nil)
      @expected =  ["COMPRISING THE PERIOD FROM", "THE TWENTIETH DAY OF MARCH, 1885,"]
    end

    it "should strip self-closing linebreak tags from the lines" do
      text = '<p id="S3V0296P0-00008" align="center">COMPRISING THE PERIOD FROM</p>
      <p id="S3V0296P0-00009" align="center">THE <lb/>TWENTIETH DAY OF MARCH, 1885,</p>'
      doc = Hpricot.XML(text)
      @parser.send(:clean_paras, doc).should == @expected
    end

    it "should strip pairs of linebreak tags from the lines" do
      text = '<p id="S3V0296P0-00008" align="center">COMPRISING THE PERIOD FROM</p>
       <p id="S3V0296P0-00009" align="center">THE <lb></lb>TWENTIETH DAY OF MARCH, 1885,</p>'
       doc = Hpricot.XML(text)
       @parser.send(:clean_paras, doc).should == @expected
    end
  end

  describe "when getting the comprising period text" do
    before do
      @parser = Hansard::HeaderParser.new(nil, nil, nil)
    end

    def should_get_comprising_period lines, index, next_text
      @parser.send(:comprising_period_text, lines, index).should == next_text
    end
    
    it "should get a comprising period that spans four lines" do
      lines = ['COMPRISING THE PERIOD FROM',
               'THE NINETEENTH DAY OF JANUARY',
               'TO',
               'THE RIGHTH DAY OF FEBRUARY',
               '1897.',
               'WATERLOW &#x0026; SONS LIMITED,']
      should_get_comprising_period(lines, 0, 'THE NINETEENTH DAY OF JANUARY TO THE RIGHTH DAY OF FEBRUARY 1897.')
    end

    it "should get a comprising period that spans three lines" do
      lines = ['COMPRISING THE PERIOD FROM',
               'THE TWENTIETH DAY OF MARCH, 1885',
               'TO',
               'THE SIXTEENTH DAY OF APRIL, 1885.',
               'FOURTH VOLUME OF SESSION 1884&#x2013;5.']
      should_get_comprising_period(lines, 0, 'THE TWENTIETH DAY OF MARCH, 1885 TO THE SIXTEENTH DAY OF APRIL, 1885.')
    end
    
    it 'should get a comprising period spanning two lines' do 
      lines = ['COMPRISING THE PERIOD FROM',
               'THE FIFTH DAY OF JULY 1881, TO',
               'THE TWENTY-SEVENTH OF JULY 1881.']
      should_get_comprising_period(lines, 0, 'THE FIFTH DAY OF JULY 1881, TO THE TWENTY-SEVENTH OF JULY 1881.')
    end
    
    it 'should get a comprising period spanning three lines without a "TO"' do 
      lines = ["COMPRISING THE PERIOD FROM",
               "THE FIFTH DAY OF JUNE 1882,",
               "THE TWENTY-FIRST DAY OF JUNE 1882."]
      should_get_comprising_period(lines, 0, 'THE FIFTH DAY OF JUNE 1882, THE TWENTY-FIRST DAY OF JUNE 1882.')
    end

    it "should get a comprising period that spans three lines and two periods" do
      lines = ['COMPRISING PERIOD FROM',
               'MONDAY, 9th JULY&#x2014;THURSDAY, 26th JULY and',
               'THURSDAY, 6th SEPTEMBER, 1990',
               'LONDON: HMSO']
      should_get_comprising_period(lines, 0, 'MONDAY, 9th JULY&#x2014;THURSDAY, 26th JULY and THURSDAY, 6th SEPTEMBER, 1990')
    end

    it 'should get a comprising period that spans only one line with a year' do
      lines = ['COMPRISING PERIOD',
               '19 July&#x2014;4 October 2004',
               'PUBLISHED BY AUTHORITY OF THE HOUSE OF COMMONS LONDON&#x2014;THE STATIONERY OFFICE LIMITED']
      should_get_comprising_period(lines, 0, '19 July&#x2014;4 October 2004')
    end

    it 'should get a comprising period that spans one line with no year' do
      lines = ['COMPRISING PERIOD FROM',
               'MONDAY, 4th JULY&#x2014;FRIDAY, 15th JULY',
               'LONDON']
      should_get_comprising_period(lines, 0, 'MONDAY, 4th JULY&#x2014;FRIDAY, 15th JULY')
    end

    
    it 'should get a comprising period mentioning an index' do 
      lines = ['COMPRISING THE PERIOD FROM MONDAY, THE TWENTY-SIXTH DAY',
               'OF AUGUST, 1907, TO WEDNESDAY, THE TWENTY-EIGHTH DAY OF',
               'AUGUST, 1907; ALSO THE GENERAL INDEX FOR THE SESSION']
      should_get_comprising_period(lines, 0, 'OF AUGUST, 1907, TO WEDNESDAY, THE TWENTY-EIGHTH DAY OF AUGUST, 1907; ALSO THE GENERAL INDEX FOR THE SESSION')
    end
    
    it 'should get a comprising period spread over four lines' do
      lines = ['COMPRISING THE PERIOD',
               'FROM',
               'THE FOURTEENTH DAY OF NOVEMBER, 1826,',
               'TO',
               'THE TWENTY-SECOND DAY OF MARCH, 1827.',
               'LONDON:']
      should_get_comprising_period(lines, 0, 'THE FOURTEENTH DAY OF NOVEMBER, 1826, TO THE TWENTY-SECOND DAY OF MARCH, 1827.')
    end

    it 'should get a comprising period with year on the following line' do
      lines = ['COMPRISING THE PERIOD FROM',
               'THE THIRTEENTH DAY OF JUNE TO THE TWENTY-THIRD DAY OF JUNE',
               '1898.']
      should_get_comprising_period(lines, 0, 'THE THIRTEENTH DAY OF JUNE TO THE TWENTY-THIRD DAY OF JUNE 1898.')
    end
    
    it 'should get a comprising period ' do 
      lines = ['COMPRISING THE PERIOD FROM',
               'THE NINTH DAY OF FEBRUARY, 1892, ',
               'To',
               'THE THIRD DAY OF MARCH, 1892.']
      should_get_comprising_period(lines, 0, 'THE NINTH DAY OF FEBRUARY, 1892,  To THE THIRD DAY OF MARCH, 1892.')
    end
    
  end

  describe 'when identifying comprising period from text' do
    before do
      @data_file = mock_model(DataFile)
      @parser = Hansard::HeaderParser.new(nil, @data_file, nil)
    end

    def check_comprising_period first_line, expected_period, second_line='LONDON:'
      comprising_period = @parser.find_comprising_period(first_line, second_line)
      comprising_period.should == expected_period
    end

    it 'should clean_period_line by removing the text "and the ..."' do
      line = 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961 and the General Index for the Session (Volumes CCXXVI&#x2014;CCXXXIV)'
      @parser.clean_period_line(line).should == 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961'
    end

    it 'should clean_period_line by removing the text "AND THE"' do
      line = '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)AND THE'
      @parser.clean_period_line(line).should == '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)'
    end


    it 'should not remove "AND THE" when it is part of the comprising period' do
      line = 'BETWEEN THE 22ND OF FEB. AND THE 10TH OF MAY 1811.'
      @parser.clean_period_line(line).should == 'BETWEEN THE 22ND OF FEB. AND THE 10TH OF MAY 1811.'
    end

    it 'should handle comprising period defined across two paragraphs, when first paragraph is "COMPRISING PERIOD FROM"' do
      second_line = 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'
      expected = second_line
      check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
    end
    
    it 'should handle a comprising period that mentions an index' do 
      first_line = 'COMPRISING THE PERIOD FROM MONDAY, THE TWENTY-SIXTH DAY'
      second_line = 'OF AUGUST, 1907, TO WEDNESDAY, THE TWENTY-EIGHTH DAY OF AUGUST, 1907; ALSO THE GENERAL INDEX FOR THE SESSION'
      expected = 'MONDAY, THE TWENTY-SIXTH DAY OF AUGUST, 1907, TO WEDNESDAY, THE TWENTY-EIGHTH DAY OF AUGUST, 1907'
      check_comprising_period first_line, expected, second_line
    end

    it 'should handle comprising period defined across two paragraphs, when first paragraph is "COMPRISING PERIOD"' do
      second_line = 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'
      expected = second_line
      check_comprising_period 'COMPRISING PERIOD', expected, second_line
    end
    
    it 'should handle comprising period defined across two paragraphs, ending with period' do
      second_line = 'TUESDAY, 2nd JUNE, to WEDNESDAY, 22nd JULY, 1942.'
      expected =    'TUESDAY, 2nd JUNE, to WEDNESDAY, 22nd JULY, 1942'
      check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
    end
    
    it 'should handle a comprising period over two lines where the first line has a year' do 
      first_line = 'Comprising period from Monday, 20th November, 1922, to Friday, 15th December,'
      second_line = '1922.'
      expected = 'Monday, 20th November, 1922, to Friday, 15th December, 1922'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a period with a dash and no year' do 
      first_line = 'COMPRISING PERIOD FROM'
      second_line = 'TUESDAY, 19th APRIL&#x2014;THURSDAY 5th MAY'
      expected = 'TUESDAY, 19th APRIL&#x2014;THURSDAY 5th MAY'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a period with a dash and no year' do 
      first_line = 'COMPRISING PERIOD FROM'
      second_line = '22nd October&#x2014;29th November'
      expected = '22nd October&#x2014;29th November'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a period without a year' do 
      first_line = 'COMPRISING PERIOD'
      second_line = '8 APRIL&#x2014;18 APRIL'
      expected = '8 APRIL&#x2014;18 APRIL'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a comprising period with a line break in the middle' do 
      first_line = 'COMPRISING PERIOD'
      second_line = '13 FEBRUARY&#x2014;24
FEBRUARY 1989'
      expected = '13 FEBRUARY&#x2014;24 FEBRUARY 1989'
      check_comprising_period first_line, expected, second_line
    end

    it 'should handle a different form of two-line comprising period text' do 
      first_line = 'COMPRISING THE PERIOD FROM THE TWENTY-FIRST DAY OF APRIL'
      second_line = 'TO THE SIXTH DAY OF MAY, 1903.'
      expected = 'THE TWENTY-FIRST DAY OF APRIL TO THE SIXTH DAY OF MAY, 1903'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should get a comprising period with three lines and two periods' do 
      first_line = 'COMPRISING PERIODS'
      second_line = 'WEDNESDAY 28TH SEPTEMBER AND MONDAY 3RD OCTOBER TO THURSDAY 6TH OCTOBER, 1938.'
      expected = 'WEDNESDAY 28TH SEPTEMBER AND MONDAY 3RD OCTOBER TO THURSDAY 6TH OCTOBER, 1938'
      check_comprising_period first_line, expected, second_line
    end

    it 'should handle comprising period defined across two paragraphs, that contain escaped dash' do
      second_line = '6th&#x2014;17th FEBRUARY, 1961'
      expected = second_line
      check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
    end

    it 'should handle comprising period defined across two paragraphs, with lower case conjunctions' do
      second_line = 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961'
      expected = second_line
      check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
    end

    it 'should handle comprising period defined in second paragraph that contains "and the General Index"' do
      second_line = 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961 and the General Index for the Session (Volumes CCXXVI&#x2014;CCXXXIV)'
      expected =    'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961'
      check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
    end

    it 'should handle comprising period defined in one paragraph, ending in period' do
      line = 'COMPRISING PERIOD FROM TUESDAY, 8TH MAY, TO THURSDAY, 2ND AUGUST, 1923.'
      check_comprising_period line, 'TUESDAY, 8TH MAY, TO THURSDAY, 2ND AUGUST, 1923'
    end
    
    it 'should handle a comprising period defined in one line with a semi-colon' do 
      line = 'Comprising; period from Monday, 4th April, 1910, to Friday, 22nd April, 1910.'
      check_comprising_period line, 'Monday, 4th April, 1910, to Friday, 22nd April, 1910'
    end
    
    it 'should handle comprising period defined in one title case line' do 
      line = 'Comprising period from Tuesday, 16th February, 1909, to Friday, 5th March, 1909.'
      check_comprising_period line, 'Tuesday, 16th February, 1909, to Friday, 5th March, 1909'
    end
    
    it 'should handle comprising period defined in one line with peeiod typo' do 
      line = 'COMPRISING THE PEEIOD FROM THE TWENTY-NINTH DAY OF APRIL 1880, TO THE FOURTEENTH DAY OF JUNE 1880.'
      check_comprising_period line, 'THE TWENTY-NINTH DAY OF APRIL 1880, TO THE FOURTEENTH DAY OF JUNE 1880'
    end

    it 'should handle comprising period defined in one paragraph, ending in comma' do
      line = 'COMPRISING PERIOD FROM TUESDAY, 13TH NOVEMBER, TO FRIDAY, 16TH NOVEMBER, 1923,'
      check_comprising_period line, 'TUESDAY, 13TH NOVEMBER, TO FRIDAY, 16TH NOVEMBER, 1923'
    end

    it 'should handle comprising period defined in one paragraph, ending in close parenthesis' do
      line = '(COMPRISING PERIOD FROM MONDAY, 19TH JULY, TO WEDNESDAY, 15TH DECEMBER, 1926)'
      check_comprising_period line,  'MONDAY, 19TH JULY, TO WEDNESDAY, 15TH DECEMBER, 1926'
    end

    it 'should handle comprising period defined in one paragraph, ending in close parenthesis followed by period' do
      line = '(COMPRISING PERIOD FROM THURSDAY, 30TH JUNE, TO FRIDAY, 29TH JULY, 1927).'
      check_comprising_period line,  'THURSDAY, 30TH JUNE, TO FRIDAY, 29TH JULY, 1927'
    end

    it 'should handle comprising period defined in one paragraph, ending in period followed by close parenthesis' do
      line = '(COMPRISING PERIOD FROM TUESDAY, 5TH MARCH, TO WEDNESDAY, 27TH MARCH, 1929.)'
      check_comprising_period line,  'TUESDAY, 5TH MARCH, TO WEDNESDAY, 27TH MARCH, 1929'
    end

    it 'should handle comprising period defined in one paragraph' do
      line = '(COMPRISING PERIOD FROM TUESDAY, 19TH JUNE, 1934, TO TUESDAY, 31ST JULY, 1934)'
      check_comprising_period line,  'TUESDAY, 19TH JUNE, 1934, TO TUESDAY, 31ST JULY, 1934'
    end

    it 'should handle comprising period defined in one paragraph that ends with ")AND THE"' do
      line = '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)AND THE'
      check_comprising_period line,  'MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936'
    end

    it 'should handle comprising period defined in one paragraph' do
      line = 'COMPRISING PERIOD FROM MONDAY, 25th OCTOBER&#x2014;FRIDAY, 5th NOVEMBER, 1976'
      check_comprising_period line,      'MONDAY, 25th OCTOBER&#x2014;FRIDAY, 5th NOVEMBER, 1976'
    end

    it 'should handle comprising period defined in one paragraph that starts with "COMPRISING PERIOD"' do
      line = 'COMPRISING PERIOD 17 APRIL&#x2014;28 APRIL 1989'
      check_comprising_period line,'17 APRIL&#x2014;28 APRIL 1989'
    end

    it 'should handle comprising period with a comma between day name and date' do
      line = 'COMPRISING PERIOD FROM MONDAY, 15TH MARCH, TO FRIDAY 1ST APRIL.'
      check_comprising_period line, 'MONDAY, 15TH MARCH, TO FRIDAY 1ST APRIL'
    end

    it 'should handle comprising period defined in one paragraph that starts with "COMPRISING PERIOD"' do
      line =     'COMPRISING PERIOD 18 March&#x2013;28 March 1991'
      check_comprising_period line,'18 March&#x2013;28 March 1991'
    end

    it 'should handle comprising period expressed with "BETWEEN"' do
      second_line = 'BETWEEN THE 22ND OF FEB. AND THE 10TH OF MAY 1811'
      expected = second_line
      check_comprising_period 'COMPRISING THE PERIOD', expected, second_line
    end

    it 'should handle a period with two years and months in words' do
      second_line = "THE FOURTEENTH DAY OF NOVEMBER, 1826, TO THE TWENTY-SECOND DAY OF MARCH, 1827."
      check_comprising_period 'COMPRISING THE PERIOD', 'THE FOURTEENTH DAY OF NOVEMBER, 1826, TO THE TWENTY-SECOND DAY OF MARCH, 1827', second_line
    end
    
    it 'should handle a misspelt period' do 
      first_line = 'COMPRISING THE PERIOD PROM'
      second_line = 'THE TWENTY-THIRD DAY OF JULY 1878, TO THE SIXTEENTH DAY OF AUGUST 1878.'
      expected = 'THE TWENTY-THIRD DAY OF JULY 1878, TO THE SIXTEENTH DAY OF AUGUST 1878'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a line with a fullstop after "COMPRISING THE PERIOD"' do 
      first_line = "COMPRISING THE PERIOD."
      second_line = 'BETWEEN THE 15th OF MAY AND THE 12th OF JULY 1805.'
      expected = 'BETWEEN THE 15th OF MAY AND THE 12th OF JULY 1805'
      check_comprising_period first_line, expected, second_line
    end
 
    it 'should handle "COMPRISING TIIE PERIOD FROM"' do 
      first_line = "COMPRISING TIIE PERIOD FROM"
      second_line = "THE NINTH DAY OF MAY TO THE TWELFTH DAY OF JUNE, 1854."
      expected = "THE NINTH DAY OF MAY TO THE TWELFTH DAY OF JUNE, 1854"
      check_comprising_period first_line, expected, second_line
    end
 
    it 'should handle a comprising period in one line with a "prising" typo' do 
      first_line = 'PRISING THE PERIOD FROM THE TWENTY-SECOND DAY OF MARCH TO THE NINTH DAY OF APRIL.'
      second_line = 'AND THE'
      expected = 'THE TWENTY-SECOND DAY OF MARCH TO THE NINTH DAY OF APRIL'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a misspelt comprising period' do
      first_line = 'COMPARISING PERIOD FROM MONDAY, 7TH DECEMBER TO TUESDAY, 22ND DECEMBER.'
      second_line = 'LONDON'
      expected = 'MONDAY, 7TH DECEMBER TO TUESDAY, 22ND DECEMBER'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a comprising period starting "IMPRISING"' do 
      first_line = 'IMPRISING THE PERIOD FROM THURSDAY, THIRTIETH DAY OF MAY, 1907, TO THURSDAY, THIRTEENTH DAY OF JUNE, 1907.'
      second_line = 'SEVENTH VOLUME OF SESSION.'
      expected = 'THURSDAY, THIRTIETH DAY OF MAY, 1907, TO THURSDAY, THIRTEENTH DAY OF JUNE, 1907'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a comprising period with volume' do 
      first_line = "COMPRISING THE PERIOD FROM"
      second_line = "THE FIFTH DAY OF DECEMBER TO THE EIGHTEENTH DAY OF DECEMBER, 1902. SIXTEENTH VOLUME OF SESSION. 1902"
      expected = "THE FIFTH DAY OF DECEMBER TO THE EIGHTEENTH DAY OF DECEMBER, 1902"
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a comprising period with "London" in it' do 
      first_line = 'COMPRISING PERIOD FROM'
      second_line = '17 DECEMBER 1990&#x2014;18 JANUARY 1991 LONDON&#x003A; HMSO &#x00A3;75 net &#x00A9; Parliamentary Copyright House of Commons 1991'
      expected = "17 DECEMBER 1990&#x2014;18 JANUARY 1991"
      check_comprising_period first_line, expected, second_line
    end
  
    it 'should handle a comprising period where commas have been misread as periods' do 
      first_line = 'COMPRISING PERIOD FROM'
      second_line = 'THE TWENTY-THIRD DAY OF NOVEMBER, 1819. TO THE TWENTY-EIGHTH DAY OF FEBRUARY, 1820'
      expected = "THE TWENTY-THIRD DAY OF NOVEMBER, 1819. TO THE TWENTY-EIGHTH DAY OF FEBRUARY, 1820"
      check_comprising_period first_line, expected, second_line
    end
 
    it 'should handle a period followed by an index' do 
      first_line =  'COMPRISING PERIOD FROM'
      second_line = 'Tuesday, 18th October, 1921, to Thursday, 10th November, 1921, AND THE GENERAL INDEX FOR THE FIRST SESSION OF 1921'
      expected = 'Tuesday, 18th October, 1921, to Thursday, 10th November, 1921'
      check_comprising_period first_line, expected, second_line
    end
    
    it 'should handle a period followed by an index in alternative form' do
      first_line =  'COMPRISING PERIOD FROM'
      second_line = 'THE THIRD DAY OF AUGUST TO THE ELEVENTH DAY OF AUGUST, 1905; ALSO THE GENERAL INDEX FOR THE SESSION OF 1905 (VOLUMES CXLI. TO CLI. INCLUSIVE), WITH THE SESSIONAL RETURNS AND OTHER APPENDICES. ELEVENTH VOLUME OF SESSION. 1905'
      expected = 'THE THIRD DAY OF AUGUST TO THE ELEVENTH DAY OF AUGUST, 1905'
      check_comprising_period first_line, expected, second_line
    end
  
    it 'should log an error to the data file noting the first line text, when getting a comprising period from two provided lines, when no match is found for COMPRISING_PERIOD_ONE_LINE_PATTERN or COMPRISING_PERIOD_ONE_LINE_NO_YEAR_PATTERN' do
      first_line = 'COMPRISING PERIOD,'
      second_line = ''
      @data_file.should_receive(:add_log).with('no comprising period identified from line: COMPRISING PERIOD, ')
      @parser.find_comprising_period(first_line, second_line)
    end
  
    it 'should get a period from "COMPRISING THE THIRTEENTH AND FOURTEENTH DAYS OF AUGUST, 1885." ' do 
      first_line = 'COMPRISING THE'
      second_line = 'THIRTEENTH AND FOURTEENTH DAYS OF AUGUST, 1885.'
      expected = 'THIRTEENTH AND FOURTEENTH DAYS OF AUGUST, 1885'
      check_comprising_period first_line, expected, second_line
    end
    
  end

  describe 'when identifying volume' do
    def check_volume text, volume_expected
      parser = Hansard::HeaderParser.new(nil, nil, nil)
      volume = parser.find_volume(text)
      volume.should == volume_expected
    end

    it 'should handle "FIFTH SERIES&#x2014;VOLUME CXXI"' do
      check_volume 'FIFTH SERIES&#x2014;VOLUME CXXI',  'CXXI'
    end

    it 'should identify series and volume and part from "SIXTH SERIES&#x2014;VOLUME 424 (Part 1)"' do
      check_volume 'SIXTH SERIES&#x2014;VOLUME 424 (Part 1)',  '424'
    end

    it 'should return nil series and volume from "RANDOM TEXT"' do
      check_volume 'RANDOM TEXT', nil
    end

    it 'should handle "FIFTH SERIES &#x2014; VOLUME X."' do
      check_volume 'FIFTH SERIES &#x2014; VOLUME X.', 'X'
    end

    it 'should handle "FIFTH SERIES—VOLUME LXXIII."' do
      check_volume 'FIFTH SERIES—VOLUME LXXIII.', 'LXXIII'
    end

    it 'should handle "FIFTH SERIES-VOLUME CCLXXI"' do
      check_volume 'FIFTH SERIES-VOLUME CCLXXI', 'CCLXXI'
    end

    it 'should handle "FIFTH SERIES&#2014;VOLUME CCLXXIII"' do
      check_volume 'FIFTH SERIES&#2014;VOLUME CCLXXIII', 'CCLXXIII'
    end

    it 'should handle "FOUTRTH SERIES"' do
      check_volume 'FOUTRTH SERIES',  nil
    end

    it 'should handle "THIRD SERIES:"' do
      check_volume 'THIRD SERIES', nil
    end

    it 'should handle "FIFTH SERIES &#x2014; VOLUME DXV"' do
      check_volume 'FIFTH SERIES &#x2014; VOLUME DXV', 'DXV'
    end

    it 'should handle "FIFTH SERIES&#x2014; VOLUME DXVII"' do
      check_volume 'FIFTH SERIES&#x2014; VOLUME DXVII', 'DXVII'
    end

    it 'should handle "FIFTH SERIES-VOLUME DLXXIII"' do
      check_volume 'FIFTH SERIES-VOLUME DLXXIII', 'DLXXIII'
    end
  end

  describe 'when identifying session and parliament' do
    def check_session_parliament text, session_expected, parliament_expected
      parser = Hansard::HeaderParser.new(nil, nil, nil)
      session, parliament = parser.find_session_and_parliament(text)
      session.should == session_expected
      parliament.should == parliament_expected
    end

    it 'should handle "SEVENTH SESSION OF THE THIRTY-SEVENTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"' do
      text = "SEVENTH SESSION OF THE THIRTY-SEVENTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"
      check_session_parliament text, 'SEVENTH', 'THIRTY-SEVENTH'
    end

    it 'should handle "SECOND SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 29 and 30 ELIZABETH II"' do
      text = "SECOND SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 29 and 30 ELIZABETH II"
      check_session_parliament text, 'SECOND', 'FORTY-NINTH'
    end

    it 'should handle "FOURTH SESSION OF THE TWENTY-EIGHTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN &amp; IRELAND"' do
      text = "FOURTH SESSION OF THE TWENTY-EIGHTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN &amp; IRELAND"
      check_session_parliament text, 'FOURTH', 'TWENTY-EIGHTH'
    end

    it 'should handle "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"' do
      text = "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"
      check_session_parliament text, 'FOURTH', 'FORTY-NINTH'
    end

    it 'should handle "FIRST SESSION OF THE FIFTY&#x2014;SECOND PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"' do
      text = "FIRST SESSION OF THE FIFTY&#x2014;SECOND PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"
      check_session_parliament text, 'FIRST', 'FIFTY&#x2014;SECOND'
    end

    it 'should return nil session and parliament for "FIRST SESSION OF THE FIFTY-SECOND PARLIAMENT"' do
      text = "FIRST SESSION OF THE FIFTY-SECOND PARLIAMENT"
      check_session_parliament text, nil, nil
    end
  end

  describe 'when identifying year(s) of reign and monarch' do
    def check_reign_monarch text, regnal_years_expected, monarch_expected
      parser = Hansard::HeaderParser.new(nil, nil, nil)
      reign, monarch = parser.find_reign_and_monarch(text)
      reign.should == regnal_years_expected
      monarch.should == monarch_expected
    end

    it 'should return nil for "1 H. C" ' do
      check_reign_monarch '1 H. C', nil, nil
    end

    it 'should handle "6 Edward, VII" ' do
      check_reign_monarch '6 Edward, VII', '6', 'Edward VII'
    end

    it 'should handle "5 &amp; 6 GEORGE VI"' do
      check_reign_monarch '5 &amp; 6 GEORGE VI', '5 &amp; 6', 'GEORGE VI'
    end

    it 'should handle "10 AND 11 GEORGE VI"' do
      check_reign_monarch '10 AND 11 GEORGE VI', '10 AND 11', 'GEORGE VI'
    end

    it 'should handle "11 &amp; 12 GEORGE V."' do
      check_reign_monarch '11 &amp; 12 GEORGE V.', '11 &amp; 12', 'GEORGE V'
    end

    it 'should handle "13 &#x0026; 14 GEORGE V."' do
      check_reign_monarch '13 &#x0026; 14 GEORGE V.', '13 &#x0026; 14', 'GEORGE V'
    end

    it 'should handle "52 &amp; 53 VICTORI&#x00C6;, 1889."' do
      check_reign_monarch '52 &amp; 53 VICTORI&#x00C6;, 1889.', '52 &amp; 53', 'VICTORI&#x00C6;'
    end

    it 'should handle "48&#x00B0; VICTORI&#x00C6;, 1884&#x2013;5."' do
      check_reign_monarch '48&#x00B0; VICTORI&#x00C6;, 1884&#x2013;5.', '48&#x00B0;', 'VICTORI&#x00C6;'
    end

    it 'should handle "61 ET 62 VICTORI&#x00C6;."' do
      check_reign_monarch '61 ET 62 VICTORI&#x00C6;.', '61 ET 62', 'VICTORI&#x00C6;'
    end

    it 'should handle "12 GEORGE V."' do
      check_reign_monarch '12 GEORGE V.', '12', 'GEORGE V'
    end

    it 'should handle "12 GEORGE VI"' do
      check_reign_monarch '12 GEORGE VI', '12', 'GEORGE VI'
    end

    it 'should handle "26 GEORGE V and 1 EDWARD VIII"' do
      check_reign_monarch '26 GEORGE V and 1 EDWARD VIII', '26, 1', 'GEORGE V, EDWARD VIII'
    end

    it 'should handle "25 GEORGE V &amp; 1 and 2 EDWARD VIII"' do
      check_reign_monarch '25 GEORGE V &amp; 1 and 2 EDWARD VIII', '25, 1 and 2', 'GEORGE V, EDWARD VIII'
    end

    it 'should handle "6&amp;7 GEORGE VI"' do
      check_reign_monarch '6&amp;7 GEORGE VI', '6 &amp; 7', 'GEORGE VI'
    end

    it 'should handle "15 and 16 GEORGE VI &amp; 1 ELIZABETH II"' do
      check_reign_monarch '15 and 16 GEORGE VI &amp; 1 ELIZABETH II', '15 and 16, 1',  'GEORGE VI, ELIZABETH II'
    end

    it 'should handle "TWENTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'TWENTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'TWENTY-THIRD', 'ELIZABETH II'
    end

    it 'should handle "FORTY-EIGHTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'FORTY-EIGHTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'FORTY-EIGHTH', 'ELIZABETH II'
    end

    it 'should handle "THIRTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'THIRTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'THIRTY-THIRD', 'ELIZABETH II'
    end
    
    it 'should handle "TWENTY-FIFTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH"' do 
      text = "TWENTY-FIFTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH"
      check_reign_monarch text, 'TWENTY-FIFTH', 'ELIZABETH'
    end

    it 'should handle "THIRD SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND THIRTY-FIFTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'THIRD SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND THIRTY-FIFTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'THIRTY-FIFTH', 'ELIZABETH II'
    end

    it 'should handle "THIRD SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 34 and 35 ELIZABETH II"' do
      text = 'THIRD SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 34 and 35 ELIZABETH II'
      check_reign_monarch text, '34 and 35', 'ELIZABETH II'
    end

    it 'should handle "THIRD SESSION OF THE FIFTY-FIRST PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND FORTY FOURTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'THIRD SESSION OF THE FIFTY-FIRST PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND FORTY FOURTH YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'FORTY-FOURTH', 'ELIZABETH II'
    end

    it 'should handle "FIRST SESSION OF THE FORTY&#x2014;SIXTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 23 ELIZABETH II"' do
      text = 'FIRST SESSION OF THE FORTY&#x2014;SIXTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 23 ELIZABETH II'
      check_reign_monarch text, '23', 'ELIZABETH II'
    end

    it 'should handle "THIRD SESSION OF THE FIFTY&#x2014;THIRD PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND FIFTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II"' do
      text = 'THIRD SESSION OF THE FIFTY&#x2014;THIRD PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND FIFTY-THIRD YEAR OF THE REIGN OF HER MAJESTY QUEEN ELIZABETH II'
      check_reign_monarch text, 'FIFTY-THIRD', 'ELIZABETH II'
    end

    it 'should handle "During the First Session of the Sixth Parliament of the United Kingdom of Great Britain and Ireland, appointed to meet at Westminster, the Fourteenth Day of January 1819, in the Fifty-ninth Year of the Reign of His Majesty King GEORGE the Third. [<i>Sess.</i> <session>1819.</session>"' do
      text = "During the First Session of the Sixth Parliament of the United Kingdom of Great Britain and Ireland, appointed to meet at Westminster, the Fourteenth Day of January 1819, in the Fifty-ninth Year of the Reign of His Majesty King GEORGE the Third. [<i>Sess.</i> <session>1819.</session>"
      check_reign_monarch text, 'Fifty-ninth', "GEORGE III"
    end
    
    it 'should handle "Appointed to meet at Westminster, the Fourth Day of September, One Thousand Eight Hundred and Four; and from thence continued, by Prorogation, to the Fifteenth Day of January, in the Forty-Fifth Year of the Reign of King GEORGE the THIRD,"' do 
      text = "Appointed to meet at Westminster, the Fourth Day of September, One Thousand Eight Hundred and Four; and from thence continued, by Prorogation, to the Fifteenth Day of January, in the Forty-Fifth Year of the Reign of King GEORGE the THIRD,"
      check_reign_monarch text, 'Forty-Fifth', "GEORGE III"
    end
    
    it 'should handle "Appointed to meet at Westminster, the Nineteenth Day of January, in the Forty-ninth Year of the Reign of His, Majesty King GEORGE the Third, Annoque Domini One Thousand Eight Hundred and Nine."' do 
      text = 'Appointed to meet at Westminster, the Nineteenth Day of January, in the Forty-ninth Year of the Reign of His, Majesty King GEORGE the Third, Annoque Domini One Thousand Eight Hundred and Nine.'
      check_reign_monarch text, 'Forty-ninth', 'GEORGE III'
    end
    
    it 'should handle "<i>During the</i>SECOND SESSION <i>of the</i> EIGHTH PARLIAMENT <i>of the United Kingdom of </i>GREAT BRITAIN <i>and</i> IRELAND, <i>appointed to meet at Westminster the 29th of January,</i> 1828, <i>in the Ninth Year of the Reign of His Majesty</i> <i>King</i> GEORGE THE FOURTH. <session>1828.</session>"' do
      text = '<i>During the</i>SECOND SESSION <i>of the</i> EIGHTH PARLIAMENT <i>of the United Kingdom of </i>GREAT BRITAIN <i>and</i> IRELAND, <i>appointed to meet at Westminster the 29th of January,</i> 1828, <i>in the Ninth Year of the Reign of His Majesty</i> <i>King</i> GEORGE THE FOURTH. <session>1828.</session>'
      check_reign_monarch text, "Ninth", 'GEORGE IV'
    end
    
  end

  describe 'when parsing old_header_example.xml' do
    before(:all) do
      file = 'old_header_example.xml'
      @source_file = mock_model(SourceFile, :id => 123,
                                            :series_house => 'both',
                                            :series_number =>3,
                                            :volume_number =>121,
                                            :part_number => 0,
                                            :start_date => Date.new(2004, 12, 1))
      @volume = Hansard::HeaderParser.new(data_file_path(file), nil, @source_file).parse
      @volume.valid?
    end

    it "should create a Volume model " do
      @volume.should_not be_nil
      @volume.should be_an_instance_of(Volume)
    end

    it 'should set the volume to "CCXCVI"' do
      @volume.number_string.should == "CCXCVI"
    end

    it 'should not populate part' do
      @volume.part.should == 0
    end

    it "should not populate session of parliament" do
      @volume.session_of_parliament.should be_nil
    end

    it "should not populate parliament" do
      @volume.parliament.should be_nil
    end

    it 'should populate regnal_years with "48&#x00B0;"' do
      @volume.regnal_years.should == '48&#x00B0;'
    end

    it 'should populate monarch with "VICTORIA"' do
      @volume.monarch.should == 'VICTORIA'
    end

    it 'should populate period with "THE TWENTIETH DAY OF MARCH, 1885, TO THE SIXTEENTH DAY OF APRIL, 1885."' do
      @volume.period.should == 'THE TWENTIETH DAY OF MARCH, 1885, TO THE SIXTEENTH DAY OF APRIL, 1885'
    end
  end

  describe 'when parsing' do
    it 'should raise an error if the hansard element is not found in the source XML' do
      doc = Hpricot.XML ''
      header_parser = Hansard::HeaderParser.new(nil, nil, nil)
      lambda{ header_parser.parse_doc(doc) }.should raise_error
    end

    it 'should look for volume attributes in paragraphs under the hansard element if regnal years have not been found in the titlepage' do
      xml = '<hansard><titlepage></titlepage><p>text</p></hansard>'
      doc = Hpricot.XML xml
      volume = mock_model(Volume, :null_object => true, :regnal_years => nil)
      Volume.stub!(:new).and_return(volume)
      header_parser = Hansard::HeaderParser.new(nil, nil, mock_model(SourceFile, :null_object => true))
      header_parser.should_receive(:find_volume_attributes).with('text', volume)
      header_parser.parse_doc(doc)
    end
  end

  describe 'when parsing header_example.xml' do
    before(:all) do
      file = 'header_example.xml'
      @source_file = mock_model(SourceFile, :id => 123,
                                            :series_house => 'lords',
                                            :series_number =>5,
                                            :volume_number =>121,
                                            :part_number => 1)
      @series = mock_model(Series)
      @series.stub!(:number).and_return 5
      Series.stub!(:find_by_source_file).and_return @series
      @volume = Hansard::HeaderParser.new(data_file_path(file), nil, @source_file).parse
    end

    it 'should have session with source_file_id populated' do
      @volume.source_file_id.should == 123
    end

    it "should create a Volume model with house 'lords'" do
      @volume.should_not be_nil
      @volume.should be_an_instance_of(Volume)
    end

    it "should associate the volume with the fifth series" do
      @volume.series.should_not be_nil
      @volume.series.should == @series
    end

    it "should set the volume number string to 'CXXI'" do
      @volume.number_string.should == 'CXXI'
    end

    it "should set the volume number to 121" do
      @volume.number.should == 121
    end

    it 'should set the part to 1' do
      @volume.part.should == 1
    end

    it "should set the session of parliament to 'SEVENTH'" do
      @volume.session_of_parliament.should == 'SEVENTH'
    end

    it "should set the parliament to 'THIRTY-SEVENTH" do
      @volume.parliament.should ==  'THIRTY-SEVENTH'
    end

    it "should populate regnal_years to '5 &amp; 6'" do
      @volume.regnal_years.should == '5 &amp; 6'
    end

    it "should set the monarch to 'GEORGE VI'" do
      @volume.monarch.should == 'GEORGE VI'
    end

    it "should set the period to 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'" do
      @volume.period.should == 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'
    end
  end
end