require 'date'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/present_on_date'
require File.dirname(__FILE__) + '/../lib/present_on_date_timeline_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment')) 

class PresentOnDateTimelineHelperTest < Test::Unit::TestCase
  include PresentOnDateTimelineHelper
  
  def timeline_link(label, interval, options, resolution, html_options)
    "<a href=\"/#{resolution}\">#{label}</a>"
  end
  
  def test_nil_resolution_interval_key_for_june_fifteenth_1885_should_be_C19
    assert_equal('C19', interval_key(Date.new(1885, 6, 15), nil))
  end

  def test_decade_resolution_interval_key_for_june_fifteenth_1885_should_be_1880s
    assert_equal("1880s", interval_key(Date.new(1885, 6, 15), :decade))
  end
  
  def test_year_resolution_interval_key_for_june_fifteenth_1885_should_be_1885
    assert_equal(1885, interval_key(Date.new(1885, 6, 15), :year))
  end
  
  def test_interval_key_for_june_fifteenth_1885_month_resolution_should_be_1885_6
    assert_equal('1885_6', interval_key(Date.new(1885, 6, 15), :month))
  end
  
  def test_interval_key_for_june_fifteenth_1885_day_resolution_should_be_the_date_itself
    assert_equal(Date.new(1885, 6, 15), interval_key(Date.new(1885, 6, 15), :day))
  end
  
  def test_no_link_for_empty_interval 
    assert_equal '1950s', link_for('1950s', :decade, [0,0,0,0,0], {})
  end
  
  def test_link_for_non_empty_interval 
    assert_equal '<a href="/decade">1950s</a>', link_for('1950s', :decade, [0,1,0,0,1], {})
  end
  
  def test_lower_resolution_link_empty_for_nil_page_resolution
    assert_equal '', lower_resolution_link(Date.new(1854,12,10), nil, {})
  end
  
  def test_lower_resolution_link_up_arrow_with_decade_resolution_link_for_page_year_res
    assert_equal "<a href=\"/decade\">1850s</a>", lower_resolution_link(Date.new(1854,12,10), :year, {})
  end
  
  def test_lower_resolution_link_up_arrow_with_year_resolution_link_for_page_month_res
    assert_equal "<a href=\"/year\">1854</a>", lower_resolution_link(Date.new(1854,12,10), :month, {})
  end
  
  def test_next_link_for_decade_res_is_nil
    assert_equal('<a href="/">21st century</a>', next_link(Date.new(1920,12,31), :decade, nil, {}))
  end
  
  def test_prev_link_for_decade_res_is_nil
    assert_equal('<a href="/">19th century</a>', previous_link(Date.new(1920,12,31), :decade, nil, {}))
  end
  
  def test_next_link_for_year_res_is_decade
    assert_equal('<a href="/decade">1930s</a>', next_link(Date.new(1929,12,31), :year, :decade, {}))
  end
  
  def test_prev_link_for_year_res_is_decade
    assert_equal('<a href="/decade">1910s</a>', previous_link(Date.new(1929,12,31), :year, :decade, {}))
  end

  def test_next_link_for_month_res_is_year
    assert_equal('<a href="/year">1921</a>', next_link(Date.new(1920,1,1), :month, :year, {}))
  end
  
  def test_prev_link_for_month_res_is_year
    assert_equal('<a href="/year">1919</a>', previous_link(Date.new(1920,1,1), :month, :year, {}))
  end
  
  def test_next_link_for_day_res_is_month
    assert_equal('<a href="/month">Sep</a>', next_link(Date.new(1920,8,01), :day, :month, {}))
  end
  
  def test_prev_link_for_day_res_is_month
    assert_equal('<a href="/month">Jul</a>', previous_link(Date.new(1920,8,01), :day, :month, {}))
  end
  
  def test_no_next_link_after_upper_nav_limit
    upper_nav_limit = Date.new(2001, 1, 1)
    assert_equal('Feb', next_link(upper_nav_limit, :day, :month, {:upper_nav_limit => upper_nav_limit}))
  end
  
  def test_no_prev_link_before_lower_nav_limit
    lower_nav_limit = Date.new(2001, 1, 1)
    assert_equal('Dec', previous_link(lower_nav_limit, :day, :month, {:lower_nav_limit => lower_nav_limit}))
  end

  def test_date_params_for_C19_at_decade_resolution
    expected = {:century => 'C19'}
    assert_equal(expected, date_params('C19', {}, :century))
  end
    
  def test_date_params_for_1880s_at_decade_resolution
    expected = {:decade => '1880s'}
    assert_equal(expected, date_params('1880s', {}, :decade))
  end
  
  def test_date_params_for_1885_at_year_resolution
    expected = {:year => 1885}
    assert_equal(expected, date_params('1885', {}, :year))
  end
  
  def test_date_params_for_1885_6_at_month_resolution
    expected = {:year => '1885', :month => 'jun', :day => nil}
    assert_equal(expected, date_params("1885_6", {}, :month))
  end
  
  def test_date_params_for_1885_06_02_at_day_resolution
    expected = {:year => '1885', :month => 'jun', :day => 2}
    assert_equal(expected, date_params(Date.new(1885, 6, 2), {}, :day))
  end
  
  def day_intervals
    {
     Date.new(1880, 1, 1) => [0],
     Date.new(1880, 1, 2) => [0],
     Date.new(1880, 1, 3) => [0],
     Date.new(1880, 1, 4) => [0],
     Date.new(1880, 1, 5) => [0],
     Date.new(1880, 1, 6) => [0],
     Date.new(1880, 1, 7) => [0],
     Date.new(1880, 1, 8) => [0],
     Date.new(1880, 1, 9) => [0],
     Date.new(1880, 1, 10) => [0],
     Date.new(1880, 1, 11) => [0],
     Date.new(1880, 1, 12) => [0],
     Date.new(1880, 1, 13) => [0],
     Date.new(1880, 1, 14) => [0],
     Date.new(1880, 1, 15) => [0],
     Date.new(1880, 1, 16) => [0],
     Date.new(1880, 1, 17) => [0],
     Date.new(1880, 1, 18) => [0],
     Date.new(1880, 1, 19) => [0],
     Date.new(1880, 1, 20) => [0],
     Date.new(1880, 1, 21) => [0],
     Date.new(1880, 1, 22) => [0],
     Date.new(1880, 1, 23) => [0],
     Date.new(1880, 1, 24) => [0],
     Date.new(1880, 1, 25) => [0],
     Date.new(1880, 1, 26) => [0],
     Date.new(1880, 1, 27) => [0],
     Date.new(1880, 1, 28) => [0],
     Date.new(1880, 1, 29) => [0],
     Date.new(1880, 1, 30) => [0],
     Date.new(1880, 1, 31) => [0]}
  end
  
  def month_intervals
    {"1880_1" => [0, 0, 0, 0, 0, 0],
     "1880_2" => [0, 0, 0, 0, 0, 0],
     "1880_3" => [0, 0, 0, 0, 0, 0],
     "1880_4" => [0, 0, 0, 0, 0, 0],
     "1880_5" => [0, 0, 0, 0, 0, 0],
     "1880_6" => [0, 0, 0, 0, 0, 0],
     "1880_7" => [0, 0, 0, 0, 0, 0],
     "1880_8" => [0, 0, 0, 0, 0, 0],
     "1880_9" => [0, 0, 0, 0, 0, 0],
     "1880_10" => [0, 0, 0, 0, 0, 0],
     "1880_11" => [0, 0, 0, 0, 0, 0],
     "1880_12" => [0, 0, 0, 0, 0, 0]}
  end
  
  def year_intervals
    {1880 => [0, 0, 0, 0, 0, 0],
     1881 => [0, 0, 0, 0, 0, 0],
     1882 => [0, 0, 0, 0, 0, 0],
     1883 => [0, 0, 0, 0, 0, 0],
     1884 => [0, 0, 0, 0, 0, 0],
     1885 => [0, 0, 0, 0, 0, 0],
     1886 => [0, 0, 0, 0, 0, 0],
     1887 => [0, 0, 0, 0, 0, 0],
     1888 => [0, 0, 0, 0, 0, 0],
     1889 => [0, 0, 0, 0, 0, 0]}
  end
  
  def decade_intervals
    {"1800s" => [0, 0, 0, 0, 0],
     "1810s" => [0, 0, 0, 0, 0],
     "1820s" => [0, 0, 0, 0, 0],
     "1830s" => [0, 0, 0, 0, 0],
     "1840s" => [0, 0, 0, 0, 0],
     "1850s" => [0, 0, 0, 0, 0],
     "1860s" => [0, 0, 0, 0, 0],
     "1870s" => [0, 0, 0, 0, 0],
     "1880s" => [0, 0, 0, 0, 0],
     "1890s" => [0, 0, 0, 0, 0]}
  end
  
  def test_seed_intervals_for_day_resolution
    expected_dates = day_intervals
    assert_equal(expected_dates, seed_intervals(Date.new(1880, 1, 1), :day, {}))
  end
 
  def test_seed_intervals_for_month_resolution
    expected_dates = month_intervals
    assert_equal(expected_dates, seed_intervals(Date.new(1880, 1, 1), :month, {}))
  end
  
  def test_seed_intervals_for_year_resolution
   expected_dates = year_intervals
   assert_equal(expected_dates, seed_intervals(Date.new(1880, 1, 1), :year, {}))
  end

  def test_seed_intervals_for_decade_resolution
   expected_dates = decade_intervals
   assert_equal(expected_dates, seed_intervals(Date.new(1880, 1, 1), :decade, {}))
  end
  
  def expect_intervals resolution, intervals, expected
    interval_keys = intervals.map{|key, value| key }
    assert_equal(expected, sort_intervals(resolution, interval_keys))
  end
  
  def test_sort_intervals_for_day_resolution
    intervals = day_intervals
    expected = []
    Date.new(1880, 1, 1).step(Date.new(1880, 1, 31), 1){ |date| expected << date }
    expect_intervals(:day, intervals, expected)
  end

  def test_sort_intervals_for_month_resolution
    intervals = month_intervals
    expected = ["1880_1", "1880_2", "1880_3", "1880_4", "1880_5", "1880_6", 
                "1880_7", "1880_8", "1880_9", "1880_10", "1880_11", "1880_12"]
    expect_intervals(:month, intervals, expected)
  end  
 
  def test_sort_intervals_for_year_resolution
    intervals = year_intervals
    expected = [1880, 1881, 1882, 1883, 1884, 1885, 1886, 1887, 1888, 1889]
    expect_intervals(:year, intervals, expected)
  end 
  
  def test_sort_intervals_for_decade_resolution
    intervals = decade_intervals
    expected = ["1800s","1810s", "1820s", "1830s", "1840s", "1850s", "1860s","1870s", "1880s", "1890s"]
    expect_intervals(:decade, intervals, expected)
  end

end
