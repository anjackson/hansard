require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser, 'when housecommons xml file only contains a title "Written Ministerial Statements"' do

  it 'should not create a sitting' do   
    DataFile.stub!(:log_to_stdout)
    file = 'housecommons_when_written_statement_title.xml'
    sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, nil
    sitting.should be_nil
  end

end
