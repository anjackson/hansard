require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::HeaderParser do

  before(:all) do
    file = 'header_example.xml'
    @session = Hansard::HeaderParser.new(File.dirname(__FILE__) + "/../data/#{file}").parse
    @session.save!
  end

  it "should create a session model" do
    @session.should_not be_nil
    @session.should be_an_instance_of(Session)
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