require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    file = 'housecommons_orders_of_the_day_inside_oralquestions.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1985, 12, 16)
  end

  it "should have Orders of the Day section outside of the OralQuestionsSection" do
    debates = @sitting.debates

    debates.sections[0].title.should == 'PRAYERS'
    debates.sections[1].sections.first.title.should == 'SCOTLAND'

    debates.sections[2].title.should == 'ORDERS OF THE DAY'
    debates.sections[3].title.should == 'Clause 2'
    debates.sections[3].sections.first.title.should == 'CONDUCT OF REFERENDUM'

    debates.sections[1].sections.size.should == 1
    debates.sections[3].sections.size.should == 1
    debates.sections.size.should == 4
  end

end
