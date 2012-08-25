require 'date'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/present_on_date'
require File.dirname(__FILE__) + '/class_extension_for_tests'

class ActiveRecordModelProxy
  include PresentOnDate
end

class PresentOnDateTest < Test::Unit::TestCase

  def configure *code
    code.each { |c| ActiveRecordModelProxy.class_eval(c) }
  end

  def one_date_setup date
    configure 'acts_as_present_on_date :date',
              "def self.exists? params; params[:date].to_s == '#{date.to_s}'; end"
  end

  def two_date_setup start_date, end_date
    configure 'acts_as_present_on_date [:start_date, :end_date]',
              "def self.exists? params; params[:start_date].to_s == '#{start_date.to_s}' || params[:end_date].to_s == '#{end_date.to_s}'; end"
  end

  def test_specified_title_found
    configure "acts_as_present_on_date :date, :title => 'individual.fullname'",
        "def individual; Struct.new('Individual', :fullname); Struct::Individual.new('Winston Smith'); end"
    assert_equal 'Winston Smith', ActiveRecordModelProxy.new.present_on_date_title
  end

  def test_title_found
    configure "acts_as_present_on_date :date",
        "def title; 'Winston Smith'; end"
    assert_equal 'Winston Smith', ActiveRecordModelProxy.new.present_on_date_title
  end

  def test_name_found
    configure "acts_as_present_on_date :date",
        "def name; 'Winston Smith'; end"
    assert_equal 'Winston Smith', ActiveRecordModelProxy.new.present_on_date_title
  end

  def test_name_found_when_title_present
    configure "acts_as_present_on_date :date",
        "def name; 'Winston Smith'; end",
        "def title; 'Black Smith'; end"
    assert_equal 'Winston Smith', ActiveRecordModelProxy.new.present_on_date_title
  end

  def test_does_exist_on_date
    date = Date.new(1975,11,11)
    one_date_setup date
    assert_equal true, ActiveRecordModelProxy.present_on_date?(date)
  end

  def test_doesnt_exist_on_date
    date = Date.new(1975,11,11)
    one_date_setup date
    assert_equal false, ActiveRecordModelProxy.present_on_date?(date - 1)
    assert_equal false, ActiveRecordModelProxy.present_on_date?(date + 1)
  end
  
  def test_does_exist_on_start_and_end_dates
    start_date = Date.new(1975,11,11)
    end_date = Date.new(2050,11,11)
    two_date_setup start_date, end_date
    assert_equal true, ActiveRecordModelProxy.present_on_date?(start_date)
    assert_equal true, ActiveRecordModelProxy.present_on_date?(end_date)
  end

  def test_doesnt_exist_on_wrong_date
    start_date = Date.new(1975,11,11)
    end_date = Date.new(2050,11,11)
    two_date_setup start_date, end_date
    assert_equal false, ActiveRecordModelProxy.present_on_date?(start_date - 1)
    assert_equal false, ActiveRecordModelProxy.present_on_date?(start_date + 1)
    assert_equal false, ActiveRecordModelProxy.present_on_date?(end_date - 1)
    assert_equal false, ActiveRecordModelProxy.present_on_date?(end_date + 1)
  end

  def test_fields_missing_raises_exception
    begin
      eval('class FieldsMissing
              include PresentOnDate
              acts_as_present_on_date
            end')
      fail('expected exception')
    rescue Exception => e
      assert_equal true, e.to_s.include?('wrong number of arguments')
    end
  end

  def test_field_not_symbol_raises_exception
    begin
      eval('class FieldNotSymbol
              include PresentOnDate      
              acts_as_present_on_date "date"
            end')
      fail('expected exception')
    rescue Exception => e
      assert_equal true, e.to_s.include?('field must be a symbol: date')
    end
  end
  
end
