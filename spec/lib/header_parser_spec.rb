require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::HeaderParser do

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

  it 'should identify series and volume from "FIFTH SERIES&#x2014;VOLUME CXXI"' do
    check_series_volume_part 'FIFTH SERIES&#x2014;VOLUME CXXI', 'FIFTH', 'CXXI'
  end

  it 'should identify series and volume and part from "SIXTH SERIES&#x2014;VOLUME 424 (Part 1)"' do
    check_series_volume_part 'SIXTH SERIES&#x2014;VOLUME 424 (Part 1)', 'SIXTH', '424', '1'
  end

  it 'should return nil series and volume from "RANDOM TEXT"' do
    check_series_volume_part 'RANDOM TEXT', nil, nil
  end

  it 'should identify series and volume from "FIFTH SERIES &#x2014; VOLUME X."' do
    check_series_volume_part 'FIFTH SERIES &#x2014; VOLUME X.', 'FIFTH', 'X'
  end

  it 'should identify series and volume from "FIFTH SERIES—VOLUME LXXIII."' do
    check_series_volume_part 'FIFTH SERIES—VOLUME LXXIII.', 'FIFTH', 'LXXIII'
  end

  it 'should identify series and volume from "FIFTH SERIES-VOLUME CCLXXI"' do
    check_series_volume_part 'FIFTH SERIES-VOLUME CCLXXI', 'FIFTH', 'CCLXXI'
  end

  it 'should identify series and volume from "FIFTH SERIES&#2014;VOLUME CCLXXIII"' do
    check_series_volume_part 'FIFTH SERIES&#2014;VOLUME CCLXXIII', 'FIFTH', 'CCLXXIII'
  end

  it 'should identify series and volume from "FOUTRTH SERIES"' do
    check_series_volume_part 'FOUTRTH SERIES',  nil, nil
  end

  it 'should identify series and volume from "FIFTH SERIES &#x2014; VOLUME DXV"' do
    check_series_volume_part 'FIFTH SERIES &#x2014; VOLUME DXV', 'FIFTH', 'DXV'
  end

  it 'should identify series and volume from "FIFTH SERIES&#x2014; VOLUME DXVII"' do
    check_series_volume_part 'FIFTH SERIES&#x2014; VOLUME DXVII', 'FIFTH', 'DXVII'
  end

  it 'should identify series and volume from "FIFTH SERIES-VOLUME DLXXIII"' do
    check_series_volume_part 'FIFTH SERIES-VOLUME DLXXIII', 'FIFTH', 'DLXXIII'
  end

  def check_session_parliament text, session_expected, parliament_expected
    session, parliament = Hansard::HeaderParser.find_session_and_parliament(text)
    session.should == session_expected
    parliament.should == parliament_expected
  end

  it 'should identify session and parliament from "SEVENTH SESSION OF THE THIRTY-SEVENTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"' do
    text = "SEVENTH SESSION OF THE THIRTY-SEVENTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"
    check_session_parliament text, 'SEVENTH', 'THIRTY-SEVENTH'
  end

  it 'should identify session and parliament from "SECOND SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 29 and 30 ELIZABETH II"' do
    text = "SECOND SESSION OF THE FORTY-NINTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND 29 and 30 ELIZABETH II"
    check_session_parliament text, 'SECOND', 'FORTY-NINTH'
  end

  it 'should identify session and parliament from "FOURTH SESSION OF THE TWENTY-EIGHTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN &amp; IRELAND"' do
    text = "FOURTH SESSION OF THE TWENTY-EIGHTH PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN &amp; IRELAND"
    check_session_parliament text, 'FOURTH', 'TWENTY-EIGHTH'
  end

  it 'should identify session and parliament from "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT<lb/> OF THE UNITED KINGDOM OF GREAT BRITAIN<lb/> AND NORTHERN IRELAND"' do
    text = "FOURTH SESSION OF THE FORTY-NINTH PARLIAMENT<lb/> OF THE UNITED KINGDOM OF GREAT BRITAIN<lb/> AND NORTHERN IRELAND"
    check_session_parliament text, 'FOURTH', 'FORTY-NINTH'
  end

  it 'should identify session and parliament from "FIRST SESSION OF THE FIFTY&#x2014;SECOND PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"' do
    text = "FIRST SESSION OF THE FIFTY&#x2014;SECOND PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND"
    check_session_parliament text, 'FIRST', 'FIFTY&#x2014;SECOND'
  end

  it 'should identify session and parliament from "FIRST SESSION OF THE FIFTY-SECOND PARLIAMENT"' do
    text = "FIRST SESSION OF THE FIFTY-SECOND PARLIAMENT"
    check_session_parliament text, nil, nil
  end

  # it 'should identify session and parliament from ""' do
    # text = ""
    # check_session_parliament text, '', ''
  # end

end

describe Hansard::HeaderParser, 'when parsing' do

  before(:all) do
    file = 'header_example.xml'
    @session = Hansard::HeaderParser.new(File.dirname(__FILE__) + "/../data/#{file}").parse
    @session.save!
  end

  it "should create a session model" do
    @session.should_not be_nil
    @session.should be_an_instance_of(Session)
  end

  it "should populate series_number with text preceding 'SERIES' inside any paragraph element" do
    @session.series_number.should == 'FIFTH'
  end

  it "should populate volume_in_series with text following 'VOLUME' inside any paragraph element that also contains the text 'SERIES'" do
    @session.volume_in_series.should == 'CXXI'
  end

  it "should enable volume_in_series_to_i to return integer representation of 'VOLUME' number string" do
    @session.volume_in_series_to_i.should == 121
  end

  it "should populate session_of_parliament with text preceding 'SESSION OF THE' inside any paragraph element that also contains the text 'PARLIAMENT OF THE UNITED KINGDOM'" do
    @session.session_of_parliament.should == 'SEVENTH'
  end

  it "should populate number_of_parliament with text following 'SESSION OF THE' inside any paragraph element that also contains the text 'PARLIAMENT OF THE UNITED KINGDOM'" do
    @session.number_of_parliament.should ==  'THIRTY-SEVENTH'
  end

  it "should populate titlepage_text with contents of titlepage element" do
    @session.titlepage_text.should eql(%Q[<image src="S5LV0121P0I0001"></image>\n] +
%Q[<p id="S5LV0121P0-00001" align="center">THE<lb></lb> PARLIAMENTARY<lb></lb> DEBATES</p>\n] +
%Q[<p id="S5LV0121P0-00002" align="center">FIFTH SERIES&#x2014;VOLUME CXXI</p>\n] +
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
    Session.delete_all
  end
end