require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    file = 'housecommons_paras_without_ids.xml'
    @data_file = DataFile.new :name => file
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), @data_file
  end

  it "should not write errors to the log for paragraphs without ids" do
    @data_file.log.should_not match(/procedural contribution without id: .*?\n MemberContribution without id:/)
  end

end
