require 'rubygems'
require 'open-uri'
require 'hpricot'

class Hansard::WrittenStatementsParser

  include Hansard::WrittenParserHelper
  attr_reader :sitting
  attr_accessor :anchor_integer
  
  def initialize file, data_file=nil, source_file=nil, parse_divisions=true
    @anchor_integer = 1
    @data_file = data_file
    @unexpected = false
    @source_file = source_file
    @file = file
    @filename = File.basename(file)
  end

  def sitting_type
    case house(@filename)
      when 'commons'
        CommonsWrittenStatementsSitting
      when 'lords'
        LordsWrittenStatementsSitting
      else
        WrittenStatementsSitting
    end
  end

  def expected_root_element
    'writtenstatements'
  end

  def get_group_model_class
    WrittenStatementsGroup
  end

  def get_body_model_class
    WrittenStatementsBody
  end
end