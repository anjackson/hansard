require File.dirname(__FILE__) + '/../spec_helper'

describe BillsController do

  it_should_behave_like "All controllers"

  describe "in handling index requests" do

    before do
      @controller_name = 'bills'
      @model = Bill
    end

    it_should_behave_like 'A controller with alphabetical index links'

  end

  describe "when routing requests " do
    
    it "should map { :controller => 'bills', :action => 'index' } to /bills" do
      params = { :controller => 'bills', :action => 'index' }
      route_for(params).should == "/bills"
    end

    it "should map { :controller => 'bills', :action => 'show', :name => 'agricultural-credits-bill'} to /bills/agricultural-credits-bill" do
      params = { :controller => 'bills', :action => 'show', :name => 'agricultural-credits-bill' }
      route_for(params).should == '/bills/agricultural-credits-bill'
    end
    
  end

  describe "when handling /bills/agricultural-credits-bill" do
   
    before do
      @bill = mock_model(Bill, :others_by_name => 'others')
    end

    def do_get
      get 'show', :name => 'agricultural-credits-bill'
    end

    it 'should ask for the bill and pass it to the view' do
      Bill.stub!(:find_by_slug).and_return(@bill)
      do_get
      assigns[:bill].should == @bill
    end

    it 'should respond with an error message when given a name that does not match any bill' do
      name = 'non_bill'
      Bill.stub!(:find_by_slug).and_return(nil)
      get 'show', :name => 'non_bill'
      response.should render_template('bills/no_bill')
    end
    
    
    it 'should ask for any other bills by the same name and pass them to the view' do 
      Bill.stub!(:find_by_slug).and_return(@bill)
      do_get
      assigns[:other_bills].should == 'others'
    end
    
  end
  
end
