require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1985_12_20.xml" do
  before(:all) do
    @sitting = parse_hansard 's6cv0089p0/housecommons_1985_12_20.xml'
    @sitting.save!
    @quote = @sitting.debates.sections[1].sections[11].contributions[1]
  end

  it 'should parse a quote element' do
    @quote.should_not be_nil
  end

  it 'should create quote contribution for a quote element' do
    @quote.should be_an_instance_of(QuoteContribution)
  end

  it 'should set the text for a quote correctly' do
    @quote.text.should == "That Sir Antony Buck and Mr. Robert Key be discharged from the Select Committee on the Armed Forces Bill and that Mr. Tony Baldry and Mr. Nicholas Soames be added to the Committee.&#x2014;<i>(Mr. Maude.]</i>" 
  end

  it 'should set the column range for a quote correctly' do
    @quote.column_range.should == '744'
  end

  it 'should set the image src range for a quote correctly' do
    @quote.image_src_range.should == 'S6CV0089P0I0381'
  end

  after(:all) do
    Sitting.delete_all
    Section.delete_all
    Contribution.delete_all
    Division.delete_all
    Vote.delete_all
  end
end

