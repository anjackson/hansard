require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  it 'should not create section if title is empty and section contains no other text' do
    source_file = SourceFile.new(:volume => mock_model(Volume))
    file = 'housecommons_empty_section_title.xml'
    sitting = parse_hansard_file(Hansard::CommonsParser, data_file_path(file), nil, source_file)
    sitting.debates.sections.size.should == 0
  end

  it 'should create section with title "Summary of Day" if title is empty and section contains other text' do
    source_file = SourceFile.new(:volume => mock_model(Volume))
    file = 'housecommons_empty_section_title_but_section_not_empty.xml'
    sitting = parse_hansard_file(Hansard::CommonsParser, data_file_path(file), nil, source_file) 
    sitting.debates.sections.first.title.should == 'Summary of Day'
  end

end
