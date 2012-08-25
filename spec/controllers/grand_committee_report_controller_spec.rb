require File.dirname(__FILE__) + '/../spec_helper'

describe GrandCommitteeReportController, " in general" do
  it_should_behave_like "All controllers"
end

describe GrandCommitteeReportController, "#route_for" do

  before(:each) do
    @house_type = 'grand_committee_report'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

end

describe GrandCommitteeReportController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe GrandCommitteeReportController, " handling GET /grand_committee_report" do

  before(:all) do
    @sitting_model = GrandCommitteeReportSitting
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe GrandCommitteeReportController, " handling GET /grand_committee_report/1999" do

  before(:all) do
    @sitting_model = GrandCommitteeReportSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe GrandCommitteeReportController, " handling GET /grand_committee_report/1999/feb" do

  before(:all) do
    @sitting_model = GrandCommitteeReportSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe GrandCommitteeReportController, "handling GET /grand_committee_report/1999/feb/08" do

  before(:all) do
    @sitting_model = GrandCommitteeReportSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end
