require File.dirname(__FILE__) + '/house_controller_spec_helper'

describe CommonsController, "#route_for" do

  before(:each) do
    @house_type = 'commons'
  end

  it_should_behave_like "controller that has routes correctly configured"

end

describe CommonsController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe CommonsController, " handling GET /commons" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe CommonsController, " handling GET /commons/1999" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe CommonsController, " handling GET /commons/1999/feb" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe CommonsController, " handling GET /commons/1999/feb/08" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end

describe CommonsController, " handling GET /commons/1999/feb/08/edit" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08/edit"

end

describe CommonsController, " handling GET /commons/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08.xml"

end

describe CommonsController, " handling GET /commons/source/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/source/1999/feb/08.xml"

end

describe CommonsController, " handling GET /commons/year/month/day.xml with real data and views" do

  before(:all) do
    @hansard_parser = Hansard::HouseCommonsParser
  end

  it_should_behave_like " handling GET /<house_type>/year/month/day.xml with real data and views"

end
