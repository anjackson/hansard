require File.dirname(__FILE__) + '/../spec_helper'

describe CommonsController, " in general" do 
  it_should_behave_like "All controllers"
end

describe CommonsController, "#route_for" do

  before(:each) do
    @house_type = 'commons'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

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

describe CommonsController, " handling GET /commons/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = HouseOfCommonsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08.xml"

end

