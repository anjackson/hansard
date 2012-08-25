require File.dirname(__FILE__) + '/../spec_helper'

describe ErrorsController do 
  
  describe  " in general" do 
    it_should_behave_like "All controllers"
  end

  describe "when mapping routes" do

    it "should map { :controller => 'errors', :action => 'show', :name =>  'date-not-in-session-years'} to /errors/date-not-in-session-years" do
      params = { :controller => 'errors', :action => 'show', :name => 'date-not-in-session-years' }
      route_for(params).should == "/errors/date-not-in-session-years"
    end

  end
  
  describe 'when handling "show"' do 
  
    def do_get
      get :show, :name => 'test-error'
    end
    
    it 'should ask for the source file error summary' do 
      SourceFile.should_receive(:error_summary).any_number_of_times.and_return({})
      do_get
    end
    
    it 'should ask for the error from the error slug' do 
      SourceFile.should_receive(:error_from_slug).with('test-error').and_return('Test Error')
      do_get
    end
    
    it 'should set the title if the error is found' do 
      SourceFile.stub!(:error_from_slug).with('test-error').and_return('Test Error')
      do_get
      assigns[:title].should == 'Test Error'
    end
  
    it 'should respond with a 404 if no error is found for the slug' do 
      SourceFile.stub!(:error_from_slug).with('test-error').and_return(nil)
      do_get
      response.response_code.should == 404
    end
  
  end
  
end