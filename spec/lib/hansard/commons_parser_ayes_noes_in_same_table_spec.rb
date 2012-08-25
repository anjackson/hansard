require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1933, 5, 18)
    @sitting_date_text = 'Thursday, 18th May, 1933.'
    @sitting_title = 'HOUSE OF COMMONS.'
    @sitting_start_column = '495'
    @sitting_end_column = '495'
    file = 'housecommons_ayes_noes_in_same_table.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, mock_model(SourceFile, :volume => mock_model(Volume))
    @sitting_chairman = 'Mr. SPEAKER'
    @sitting.save!

    @first_section = @sitting.debates.sections.first.sections.first
  end

  it_should_behave_like "All sittings"

  it 'should have first divided text in right place' do
    first_divided = @first_section.contributions[1]
    first_divided.text.should == 'The House divided: Ayes, 2; Noes, 7.'
    first_divided.should be_an_instance_of(ProceduralContribution)
  end

  it 'should have first division placeholder following divided text' do
    first_division = @first_section.contributions[2]
    first_division.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should have second divided text in right place' do
    first_divided = @first_section.contributions[5]
    first_divided.text.should == 'The House divided: Ayes, 4; Noes, 4.'
    first_divided.should be_an_instance_of(ProceduralContribution)
  end

  it 'should have second division placeholder following divided text' do
    first_division = @first_section.contributions[6]
    first_division.should be_an_instance_of(DivisionPlaceholder)
  end
end

