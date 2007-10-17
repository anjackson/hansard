require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    file = 'housecommons_business_of_the_house_in_oralquestions.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1973, 4, 16)
  end

  it "should have Orders of the Day section outside of the OralQuestionsSection" do
    debates = @sitting.debates

    debates.sections[0].title.should == 'ORAL ANSWERS TO QUESTIONS'

    debates.sections[0].sections[0].title.should == 'TRADE AND INDUSTRY'
    debates.sections[0].sections[0].sections[0].title.should == 'North Sea Oil and Gas'

    debates.sections[1].title.should == 'BUSINESS OF THE HOUSE'

    debates.sections[2].title.should == 'ORDERS OF THE DAY'

    debates.sections.size.should == 3
  end

end
