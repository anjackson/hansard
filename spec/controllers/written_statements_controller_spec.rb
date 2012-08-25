require File.dirname(__FILE__) + '/../spec_helper'

describe WrittenStatementsController, " in general" do
  it_should_behave_like "All controllers"
end

describe WrittenStatementsController, "#route_for" do

  before(:each) do
    @house_type = 'written_statements'
  end

  it_should_behave_like "controller that has routes correctly configured"
  it_should_behave_like "controller that isn't mapping the root url"

end

describe WrittenStatementsController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe WrittenStatementsController, " handling GET /writtenstatements" do

  before(:all) do
    @sitting_model = WrittenStatementsSitting
  end

  it_should_behave_like " handling GET /<house_type>"

end

describe WrittenStatementsController, " handling GET /writtenstatements/1999" do

  before(:all) do
    @sitting_model = WrittenStatementsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999"

end

describe WrittenStatementsController, " handling GET /writtenstatements/1999/feb" do

  before(:all) do
    @sitting_model = WrittenStatementsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe WrittenStatementsController, "handling GET /writtenstatements/1999/feb/08" do

  before(:all) do
    @sitting_model = WrittenStatementsSitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"

end
