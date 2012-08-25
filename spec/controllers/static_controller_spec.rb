require File.dirname(__FILE__) + '/../spec_helper'

describe StaticController do
  
  describe "when handling routing" do 

    it "should map /no/route/for/this { :controller => 'static', :action => 'send_404' }" do
      params = { :controller => 'static', 
                 :action => 'send_404',
                 :path => ['no', 'route', 'for', 'this'] }
      params_from(:get, '/no/route/for/this').should == params
    end
  
    def should_map(path)
      params = { :controller => "static", :action => path }
      route_for(params).should == "/#{path}"
      params_from(:get, "/#{path}").should == params
    end
  
    it 'should map /api to { :controller => "static", :action => "api" } ' do 
      should_map('api')
    end
  
    it 'should map /credits to { :controller => "static", :action => "credits" } ' do 
      should_map('credits')
    end
  
    it 'should map /typos to { :controller => "static", :action => "typos" } ' do 
      should_map('typos')
    end

  end

  describe "when handling a 404" do 

    def do_get
      get :send_404
    end
  
    it 'should return a 404 response' do 
      @controller.should_receive(:respond_with_404)
      do_get
    end
  
  end

  describe "when routing to /api" do 

    def do_get
      get :api
    end
  
    it 'should set the title to "API"' do 
      do_get
      assigns[:title].should == 'API'
    end

  end

  describe "when routing to /credits" do 

    def do_get
      get :credits
    end
  
    it 'should set the title to "Credits"' do 
      do_get
      assigns[:title].should == 'Credits'
    end

  end

  describe "when routing to /typos" do 

    def do_get
      get :typos
    end
  
    it 'should set the title to "Typos"' do 
      do_get
      assigns[:title].should == 'Typos'
    end

  end
end