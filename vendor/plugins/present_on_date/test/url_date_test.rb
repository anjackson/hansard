require 'test/unit'
require File.dirname(__FILE__) + '/../lib/url_date'

class UrlDateTest < Test::Unit::TestCase
  
  def test_numeric_to_3_letter_conversion
    assert_equal('may', UrlDate::mm_to_mmm('05'))
  end

  def test_conversion_of_date_path_parameters_to_date
    url_date = UrlDate.new :year => '2005', :month => 'may', :day => '23'
    assert_equal(Date.new(2005,5,23), url_date.to_date)
  end  
  
end
