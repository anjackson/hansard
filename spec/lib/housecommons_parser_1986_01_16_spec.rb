require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1986_01_16.xml" do
  before(:all) do
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1986,1,16)
    @sitting_date_text = 'Thursday 16 January 1986'
    @sitting_title = 'House of Commons' 
    @sitting_start_column = '1191'
    @sitting_start_image = 'S6CV0089P0I0605'
    @sitting_text = %Q[<p id="S6CV0089P0-04200"><i>The House met at half-past Two o'clock</i></p>]

    @sitting = parse_hansard 's6cv0089p0/housecommons_1986_01_16.xml'
    @sitting.save!
  end

  after(:all) do
    Sitting.delete_all
    Section.delete_all
    Contribution.delete_all
    Division.delete_all
    Vote.delete_all
  end

  it_should_behave_like "All sittings"
  it_should_behave_like "All commons sittings"
end
