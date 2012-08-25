require File.dirname(__FILE__) + '/../spec_helper'

describe Date, " when asked for decade" do


  it 'should return 1800 for date in years 1800 to 1809' do
    Date.parse('1800-01-01').decade.should == 1800
    Date.parse('1801-01-01').decade.should == 1800
    Date.parse('1809-12-31').decade.should == 1800
  end

  it 'should return 1890 for date in years 1890 to 1899' do
    Date.parse('1890-01-01').decade.should == 1890
    Date.parse('1891-01-01').decade.should == 1890
    Date.parse('1899-12-31').decade.should == 1890
  end

  it 'should return 1900 for date in years 1900 to 1909' do
    Date.parse('1900-01-01').decade.should == 1900
    Date.parse('1901-01-01').decade.should == 1900
    Date.parse('1909-12-31').decade.should == 1900
  end

  it 'should return 2000 for date in years 2000 to 2099' do
    Date.parse('2000-01-01').decade.should == 2000
    Date.parse('2001-01-01').decade.should == 2000
    Date.parse('2009-12-31').decade.should == 2000
  end

end

describe Date, "when asked for year from century string" do 

  it 'should return 1900 from "C20"' do 
    Date.year_from_century_string("C20").should == 1900
  end
  
  it 'should return 1800 from "C19"' do 
    Date.year_from_century_string("C19").should == 1800
  end
  
  it 'should return 2000 from "C21"' do 
    Date.year_from_century_string("C21").should == 2000
  end
  
end

describe Date, "when asked for first of century" do 

  it 'should return 1900-01-01 for 20' do 
    Date.first_of_century(20).should == Date.new(1900, 1, 1)
  end
  
  
  it 'should return 1800-01-01 for 19' do 
    Date.first_of_century(19).should == Date.new(1800, 1, 1)
  end
  
  it 'should return 2000-01-01 for 21' do 
    Date.first_of_century(21).should == Date.new(2000, 1, 1)
  end
  
end

describe Date, "when converting a century to a year" do 
  
  it 'should return 2000 for 21' do 
    Date.century_to_year(21).should == 2000
  end
  
  it 'should return 1900 for 20' do 
    Date.century_to_year(20).should == 1900
  end
  
  it 'should return 1800 for 19' do 
    Date.century_to_year(19).should == 1800
  end
end
