require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::HeaderParser, 'when identifying comprising period text' do

  def check_comprising_period first_line, expected_period, second_line='LONDON:'
    comprising_period = Hansard::HeaderParser.find_comprising_period(first_line, second_line)
    comprising_period.should == expected_period
  end

  it 'should clean_period_line by removing the text "and the ..."' do
    line = 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961 and the General Index for the Session (Volumes CCXXVI&#x2014;CCXXXIV)'
    Hansard::HeaderParser.clean_period_line(line).should == 'MONDAY, 31st JULY, 1961, to TUESDAY, 24th OCTOBER, 1961'
  end

  it 'should clean_period_line by removing the text "AND THE"' do
    line = '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)AND THE'
    Hansard::HeaderParser.clean_period_line(line).should == '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)'
  end

  it 'should handle comprising period defined across two paragraphs, when first paragraph is "COMPRISING PERIOD FROM"' do
    second_line = 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'
    expected = second_line
    check_comprising_period 'COMPRISING PERIOD FROM', expected, second_line
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

  it 'should handle comprising period defined in one paragraph that contains lb element' do
    line = '(COMPRISING PERIOD FROM TUESDAY, 19TH JUNE, 1934, TO TUESDAY,<lb/> 31ST JULY, 1934)'
    check_comprising_period line,  'TUESDAY, 19TH JUNE, 1934, TO TUESDAY, 31ST JULY, 1934'
  end

  it 'should handle comprising period defined in one paragraph that ends with ")AND THE"' do
    line = '(COMPRISING PERIOD FROM MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936)AND THE'
    check_comprising_period line,  'MONDAY, JULY 20TH, TO FRIDAY, OCTOBER 30TH, 1936'
  end

  it 'should handle comprising period defined in one paragraph that has lb element before period text' do
    line = 'COMPRISING PERIOD FROM<lb/> MONDAY, 25th OCTOBER&#x2014;FRIDAY, 5th NOVEMBER, 1976'
    check_comprising_period line,      'MONDAY, 25th OCTOBER&#x2014;FRIDAY, 5th NOVEMBER, 1976'
  end

  it 'should handle comprising period defined in one paragraph that starts with "COMPRISING PERIOD" followed by lb element' do
    line = 'COMPRISING PERIOD<lb/>17 APRIL&#x2014;28 APRIL 1989'
    check_comprising_period line,'17 APRIL&#x2014;28 APRIL 1989'
  end

  it 'should handle comprising period defined in one paragraph that starts with "COMPRISING PERIOD"' do
    line =     'COMPRISING PERIOD 18 March&#x2013;28 March 1991'
    check_comprising_period line,'18 March&#x2013;28 March 1991'
  end
end

describe Hansard::HeaderParser, 'when identifying series and volume' do

  def check_series_volume_part text, series_expected, volume_expected, part_expected=nil
    series, volume, part = Hansard::HeaderParser.find_series_and_volume_and_part(text)
    series.should == series_expected
    volume.should == volume_expected
    if part_expected
      part.should == part_expected
    else
      part.should be_nil
    end
  end

  it 'should handle "FIFTH SERIES&#x2014;VOLUME CXXI"' do
    check_series_volume_part 'FIFTH SERIES&#x2014;VOLUME CXXI', 'FIFTH', 'CXXI'
  end

  it 'should identify series and volume and part from "SIXTH SERIES&#x2014;VOLUME 424 (Part 1)"' do
    check_series_volume_part 'SIXTH SERIES&#x2014;VOLUME 424 (Part 1)', 'SIXTH', '424', '1'
  end

  it 'should return nil series and volume from "RANDOM TEXT"' do
    check_series_volume_part 'RANDOM TEXT', nil, nil
  end

  it 'should handle "FIFTH SERIES &#x2014; VOLUME X."' do
    check_series_volume_part 'FIFTH SERIES &#x2014; VOLUME X.', 'FIFTH', 'X'
  end

  it 'should handle "FIFTH SERIES—VOLUME LXXIII."' do
    check_series_volume_part 'FIFTH SERIES—VOLUME LXXIII.', 'FIFTH', 'LXXIII'
  end

  it 'should handle "FIFTH SERIES-VOLUME CCLXXI"' do
    check_series_volume_part 'FIFTH SERIES-VOLUME CCLXXI', 'FIFTH', 'CCLXXI'
  end

  it 'should handle "FIFTH SERIES&#2014;VOLUME CCLXXIII"' do
    check_series_volume_part 'FIFTH SERIES&#2014;VOLUME CCLXXIII', 'FIFTH', 'CCLXXIII'
  end

  it 'should handle "FOUTRTH SERIES"' do
    check_series_volume_part 'FOUTRTH SERIES',  nil, nil
  end

  it 'should handle "FIFTH SERIES &#x2014; VOLUME DXV"' do
    check_series_volume_part 'FIFTH SERIES &#x2014; VOLUME DXV', 'FIFTH', 'DXV'
  end

  it 'should handle "FIFTH SERIES&#x2014; VOLUME DXVII"' do
    check_series_volume_part 'FIFTH SERIES&#x2014; VOLUME DXVII', 'FIFTH', 'DXVII'
  end

  it 'should handle "FIFTH SERIES-VOLUME DLXXIII"' do
    check_series_volume_part 'FIFTH SERIES-VOLUME DLXXIII', 'FIFTH', 'DLXXIII'
  end

end

describe Hansard::HeaderParser, 'when identifying session and parliament' do

  def check_session_parliament text, session_expected, parliament_expected
    session, parliament = Hansard::HeaderParser.find_session_and_parliament(text)
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

  it 'should handle "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT<lb/> OF THE UNITED KINGDOM OF GREAT BRITAIN<lb/> AND NORTHERN IRELAND"' do
    text = "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT<lb/> OF THE UNITED KINGDOM OF GREAT BRITAIN<lb/> AND NORTHERN IRELAND"
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

  # it 'should identify session and parliament from ""' do
    # text = ""
    # check_session_parliament text, '', ''
  # end

end

describe Hansard::HeaderParser, 'when identifying year(s) of reign and monarch' do

  def check_reign_monarch text, regnal_years_expected, monarch_expected
    reign, monarch = Hansard::HeaderParser.find_reign_and_monarch(text)
    reign.should == regnal_years_expected
    monarch.should == monarch_expected
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

  it 'should handle "12 GEORGE V."' do
    check_reign_monarch '12 GEORGE V.', '12', 'GEORGE V'
  end

  it 'should handle "12 GEORGE VI"' do
    check_reign_monarch '12 GEORGE VI', '12', 'GEORGE VI'
  end

  it 'should handle "26 GEORGE V and 1 EDWARD VIII"' do
    check_reign_monarch '26 GEORGE V and 1 EDWARD VIII', '26, 1', 'GEORGE V, EDWARD VIII'
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

  it 'should handle "THIRTY-THIRD YEAR OF THE REIGN OF<lb/> HER MAJESTY QUEEN ELIZABETH II"' do
    text = 'THIRTY-THIRD YEAR OF THE REIGN OF<lb/> HER MAJESTY QUEEN ELIZABETH II'
    check_reign_monarch text, 'THIRTY-THIRD', 'ELIZABETH II'
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
end

describe Hansard::HeaderParser, 'when parsing' do

  before(:all) do
    file = 'header_example.xml'
    source_file = SourceFile.new
    @source_file_id = 123
    source_file.stub!(:id).and_return(@source_file_id)
    source_file.stub!(:house).and_return('lords')
    @session = Hansard::HeaderParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil, source_file).parse
    @session.save!
  end

  it 'should have session with source_file_id populated' do
    @session.source_file_id.should == @source_file_id
  end

  it "should create a HouseOfLordsSession model if titlepage paragraph contains HOUSE OF LORDS" do
    @session.should_not be_nil
    @session.should be_an_instance_of(HouseOfLordsSession)
  end

  it "should populate series_number with text preceding 'SERIES' inside any paragraph element" do
    @session.series_number.should == 'FIFTH'
  end

  it "should populate volume_in_series with text following 'VOLUME' inside any paragraph element that also contains the text 'SERIES'" do
    @session.volume_in_series.should == 'CXXI'
  end

  it "should enable volume_in_series_number to return integer representation of 'VOLUME' number string" do
    @session.volume_in_series_number.should == 121
  end

  it 'should populate volume_in_series_number with the integer following the text "(Part " inside a paragraph that also contains the text "SERIES" and "VOLUME"' do
    @session.volume_in_series_part_number.should == 1
  end

  it "should populate session_of_parliament with text preceding 'SESSION OF THE' inside any paragraph element that also contains the text 'PARLIAMENT OF THE UNITED KINGDOM'" do
    @session.session_of_parliament.should == 'SEVENTH'
  end

  it "should populate number_of_parliament with text following 'SESSION OF THE' inside any paragraph element that also contains the text 'PARLIAMENT OF THE UNITED KINGDOM'" do
    @session.number_of_parliament.should ==  'THIRTY-SEVENTH'
  end

  it "should populate regnal_years with text preceding the monarch's name in a paragraph element" do
    @session.regnal_years.should == '5 &amp; 6'
  end

  it "should populate monarch_name with text of the monarch's name when it's in a paragraph element with the year of reign" do
    @session.monarch_name.should == 'GEORGE VI'
  end

  it "should populate comprising_period with the dates following 'COMPRISING PERIOD'" do
    @session.comprising_period.should == 'WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942'
  end

  it "should populate titlepage_text with contents of titlepage element" do
    @session.titlepage_text.should eql(%Q[<image src="S5LV0121P0I0001"></image>\n] +
%Q[<p id="S5LV0121P0-00001" align="center">THE<lb></lb> PARLIAMENTARY<lb></lb> DEBATES</p>\n] +
%Q[<p id="S5LV0121P0-00002" align="center">FIFTH SERIES&#x2014;VOLUME CXXI (Part 1)</p>\n] +
%Q[<p id="S5LV0121P0-00003" align="center">HOUSE OF LORDS</p>\n] +
%Q[<p id="S5LV0121P0-00004" align="center">OFFICIAL REPORT</p>\n] +
%Q[<p id="S5LV0121P0-00005" align="center">SEVENTH SESSION OF THE THIRTY-SEVENTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND</p>\n] +
%Q[<p id="S5LV0121P0-00006" align="center">5 &amp; 6 GEORGE VI</p>\n] +
%Q[<p id="S5LV0121P0-00007" align="center">FIRST VOLUME OF SESSION 1941&#x2013;42</p>\n] +
%Q[<p id="S5LV0121P0-00008" align="center">COMPRISING PERIOD FROM</p>\n] +
%Q[<p id="S5LV0121P0-00009" align="center">WEDNESDAY, 12th NOVEMBER, 1941, to THURSDAY, 19th FEBRUARY, 1942</p>\n] +
%Q[<p id="S5LV0121P0-00010" align="center">LONDON</p>\n] +
%Q[<p id="S5LV0121P0-00011" align="center">PRINTED AND PUBLISHED BY HIS MAJESTY'S STATIONERY OFFICE</p>\n] +
%Q[<p id="S5LV0121P0-00012" align="center">To be purchased directly from H.M. STATIONERY OFFICE at the following addresses:</p>\n] +
%Q[<p id="S5LV0121P0-00013" align="center">York House, Kingsway, London, W.C.2: 120 George Street, Edinburgh 2;</p>\n] +
%Q[<p id="S5LV0121P0-00014" align="center">39&#x2013;41 King Street, Manchester 2; 1 St. Andrew's Crescent, Cardiff;</p>\n] +
%Q[<p id="S5LV0121P0-00015" align="center">80 Chichester Street, Belfast;</p>\n] +
%Q[<p id="S5LV0121P0-00016" align="center">or through any bookseller</p>\n] +
%Q[<p id="S5LV0121P0-00017" align="center">1942</p>\n] +
%Q[<p id="S5LV0121P0-00018" align="center">Price 9s. od. net</p>\n] +
%Q[<image src="S5LV0121P0I0002"></image>\n] +
%Q[<p id="S5LV0121P0-00019" align="center">This volume may be cited as&#x2014;</p>\n] +
%Q[<p id="S5LV0121P0-00020" align="center">"121 H.L. Deb., 5s."</p>])
  end

  after(:all) do
    ParliamentSession.delete_all
  end
end