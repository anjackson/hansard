require 'rubygems'
require 'open-uri'
require 'hpricot'

class Hansard::WrittenAnswersParser

  include Hansard::WrittenParserHelper
  attr_reader :sitting
  attr_accessor :anchor_integer

  def initialize file, data_file=nil, source_file=nil, parse_divisions=false
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
        CommonsWrittenAnswersSitting
      when 'lords'
        LordsWrittenAnswersSitting
      else
        WrittenAnswersSitting
    end
  end

  def expected_root_element
    'writtenanswers'
  end

  def get_group_model_class
    WrittenAnswersGroup
  end

  def get_body_model_class
    WrittenAnswersBody
  end

end