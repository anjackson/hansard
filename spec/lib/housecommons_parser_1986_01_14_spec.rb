require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1986_01_14.xml" do
  before(:all) do
    @sitting = parse_hansard 's6cv0089p0/housecommons_1986_01_14.xml'
    @sitting.save!

    @section = @sitting.debates.sections[7].sections[4]
  end

  it 'should set the image src property on the first element following an image tag within the orders of the day' do
    @section.start_image_src.should == 'S6CV0089P0I0523'
  end

  it 'should set the column property on the first element following an column tag within the orders of the day' do
    @section.start_column.should == '1027'
  end

  
end
