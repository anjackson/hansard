require File.dirname(__FILE__) + '/../spec_helper'

describe IndicesController, "#route_for" do
  
  it "should map { :controller => 'indices', 
                   :action => 'show', 
                   :start_year => '1985', 
                   :start_month => 'dec', 
                   :start_day => '16', 
                   :end_year => '1986',
                   :end_month => 'jan',
                   :end_day => '17'} to /indices/1985/dec/16/1986/jan/17" do
    
    params = { :controller => 'indices', 
               :action => 'show', 
               :start_year => "1985", 
               :start_month => "dec", 
               :start_day => "16", 
               :end_year => "1986",
               :end_month => "jan",
               :end_day => "17" }
    route_for(params).should == "/indices/1985/dec/16/1986/jan/17"
  
  end
  
  it "should map { :controller => 'indices', :action => 'index' } to /indices " do
    params = { :controller => 'indices', :action => 'index'}
    route_for(params).should == '/indices'
  end
  
end

describe IndicesController, "handling GET /indices" do
  
  before do
    @index = mock_model(Index)
    Index.stub!(:find).and_return([@index])
  end

  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find all the indices" do
    Index.should_receive(:find).with(:all).and_return([@index])
    do_get
  end
  
  it "should render with the 'index' template" do
    do_get
    response.should render_template('index')
  end

  it "should assign the indices for the view" do
    do_get
    assigns[:indices].should == [@index]
  end
  
end

describe IndicesController, "handling GET /indices/1985/dec/16/1986/jan/17" do

  before do
    @index = mock_model(Index)
    Index.stub!(:find_by_date_span).and_return(@index)
  end
  
  def do_get
    get :show, :start_year  => '1985', 
               :start_month => 'dec', 
               :start_day   => '16', 
               :end_year    => '1986',
               :end_month   => 'jan', 
               :end_day     => '17'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    Index.should_receive(:find_by_date_span).with("1985-12-16", "1986-01-17").and_return(@sitting)
    do_get
  end
  
  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end

  it "should assign the index for the view" do
    do_get
    assigns[:index].should equal(@index)
  end

end


  
