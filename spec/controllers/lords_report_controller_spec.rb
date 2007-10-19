require File.dirname(__FILE__) + '/house_controller_spec_helper'

describe LordsReportsController, "#route_for" do

  before(:each) do
    @house_type = 'lords'
  end

  it_should_behave_like "controller that has routes correctly configured"

end

describe LordsReportsController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe LordsReportsController, " handling GET /lords" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe LordsReportsController, " handling GET /lords/1999" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe LordsReportsController, " handling GET /lords/1999/feb" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe LordsReportsController, " handling GET /lords/1999/feb/08" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end

describe LordsReportsController, " handling GET /lords/1999/feb/08/edit" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08/edit"

end

describe LordsReportsController, " handling GET /lords/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08.xml"

end

describe LordsReportsController, " handling GET /lords/source/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/source/1999/feb/08.xml"

end

describe LordsReportsController, " handling GET /lords/year/month/day.xml with real data and views" do

  before(:all) do
    @hansard_parser = Hansard::HouseLordsParser
  end

  it_should_behave_like " handling GET /<house_type>/year/month/day.xml with real data and views"

end
