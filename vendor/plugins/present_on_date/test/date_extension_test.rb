require 'date'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/date_extension'


class DateExtensionTest < Test::Unit::TestCase

  def test_first_and_last_of_month
    date = Date.new(2007, 11, 5)
    assert_equal(date.first_and_last_of_month, [Date.new(2007, 11, 1), Date.new(2007, 11, 30)]) 
  end

  def test_first_of_month_should_return_june_first_1885_for_june_fifteenth_1885  
    assert_equal(Date.new(1885, 6, 1), Date.new(1885, 6, 15).first_and_last_of_month.first)
  end
  
  def test_last_of_month_should_return_dec_thirty_first_1885_for_dec_twenty_eight_1885
    assert_equal(Date.new(1885, 12, 31), Date.new(1885, 12, 28).first_and_last_of_month.last)
  end
  
  def test_last_of_month_should_return_nov_thirtieth_1885_for_nov_twelfth_1885
    assert_equal(Date.new(1885, 11, 30), Date.new(1885, 11, 12).first_and_last_of_month.last)
  end
  
  def test_first_and_last_of_year
    date = Date.new(2007, 11, 5)
    assert_equal([Date.new(2007, 1, 1), Date.new(2007, 12, 31)], date.first_and_last_of_year)
  end
  
  def test_first_and_last_of_decade
    date = Date.new(2007, 11, 5)
    assert_equal([Date.new(2000, 1, 1), Date.new(2009, 12, 31)], date.first_and_last_of_decade)
  end
  
  def test_first_and_last_of_century
    date = Date.new(2007, 11, 5)
    assert_equal([Date.new(2000, 1, 1), Date.new(2099, 12, 31)], date.first_and_last_of_century)
  end
  
  def test_decade_string
    assert_equal("2000s", Date.new(2004, 11, 3).decade_string)
    assert_equal("1880s", Date.new(1885, 1, 1).decade_string)
    assert_equal("1970s", Date.new(1974, 2, 25).decade_string)
    assert_equal("1900s", Date.new(1900, 11, 3).decade_string)
  end

  def test_century_string
    assert_equal("C21", Date.new(2004, 11, 3).century_string)
    assert_equal("C19", Date.new(1885, 1, 1).century_string)
    assert_equal("C20", Date.new(1974, 2, 25).century_string)
  end
  
  def test_century_ordinal
    assert_equal("21st", Date.new(2004, 11, 3).century_ordinal)
    assert_equal("19th", Date.new(1885, 1, 1).century_ordinal)
    assert_equal("20th", Date.new(1974, 2, 25).century_ordinal)
  end
  
  def test_higher_resolution_nil_is_decade
    assert_equal :decade, Date.higher_resolution(nil)
  end
  
  def test_higher_resolution_decade_is_year
    assert_equal :year, Date.higher_resolution(:decade)
  end  
  
  def test_higher_resolution_year_is_month
    assert_equal :month, Date.higher_resolution(:year)
  end
  
  def test_higher_resolution_month_is_day
    assert_equal :day, Date.higher_resolution(:month)
  end

  def test_lower_resolution_decade_is_nil
    assert_equal nil, Date.lower_resolution(:decade)
  end

  def test_lower_resolution_year_is_decade
    assert_equal :decade, Date.lower_resolution(:year)
  end  
  
  def test_lower_resolution_month_is_year
    assert_equal :year, Date.lower_resolution(:month)
  end
  
  def test_lower_resolution_day_is_month
    assert_equal :month, Date.lower_resolution(:day)
  end
  
  def test_lower_resolution_nil_is_day
    assert_equal :day, Date.lower_resolution(nil)
  end
  
  def test_get_interval_delimiters_2004_12_31_decade_resolution_should_be_2000_1_1_and_2099_12_31
    date = Date.new(2004,12,31)
    assert_equal([Date.new(2000,1,1), Date.new(2099,12,31)], date.get_interval_delimiters(:decade, {}))
  end
  
  def test_get_interval_delimiters_2004_12_31_year_resolution_should_be_2000_1_1_and_2009_12_31
    date = Date.new(2004,12,31)
    assert_equal([Date.new(2000,1,1), Date.new(2009,12,31)], date.get_interval_delimiters(:year, {}))
  end
  
  def test_get_interval_delimiters_2004_1_1_month_resolution_should_be_2004_1_1_and_2004_12_31
    date = Date.new(2004,1,1)
    assert_equal([Date.new(2004,1,1), Date.new(2004,12,31)], date.get_interval_delimiters(:month, {}))
  end
  
  def test_get_interval_delimiters_for_2004_11_1_day_resolution_should_be_2004_11_1_and_2004_11_30
    date = Date.new(2004,11,1)
    assert_equal([Date.new(2004,11,1), Date.new(2004,11,30)], date.get_interval_delimiters(:day, {}))
  end
  

end