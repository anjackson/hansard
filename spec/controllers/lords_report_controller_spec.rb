require File.dirname(__FILE__) + '/../spec_helper'

describe LordsReportsController, " in general" do 
  it_should_behave_like "All controllers"
end

describe LordsReportsController, "#route_for" do

  before(:each) do
    @house_type = 'lords'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

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

describe LordsReportsController, " handling GET /lords/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfLordsReport
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08.xml"

end
