require File.dirname(__FILE__) + '/../spec_helper'

def setup_controller
  ActionController::Routing::Routes.draw do |map|
    map.resources :foo
    map.connect '*path', :controller => 'foo', :action => 'send_404'
  end
end

def teardown_controller
  eval IO.read(RAILS_ROOT + "/config/routes.rb")
end

def expect_url_date_params params
  params.update({ "action"=>"index", "controller"=>"foo" })
  UrlDate.should_receive(:new).with(params).and_return(mock_model(UrlDate, :null_object => true))
  get :index, @params
end

describe ApplicationController do

  it_should_behave_like "All controllers"

  class FooController < ApplicationController
    before_filter :check_valid_date, :only => :index
    def index; render :text => "foos"; end
    def send_404; respond_with_404; end
  end
  
  describe "when stripping images" do 
    
    controller_name :foo

    before(:all) do
      setup_controller
    end

    after(:all) do
      teardown_controller
    end
    
    it 'should remove image tags from a rendered body' do 
      get :index
      original = '<li>C23 Sherpa</li><image src="S6CV0265P0I0488"></image><col>161</col><li>C9B</li>'
      expected = '<li>C23 Sherpa</li><col>161</col><li>C9B</li>'
      @controller.response.body = original
      @controller.send(:strip_images).should match(/#{expected}/)
    end
  end

  describe "when checking for valid dates" do
    it 'should return true if the params do not include "year", "decade" or "century"' do
      @controller.stub!(:params).and_return({})
      @controller.check_valid_date.should be_true
    end

    describe "when passed a day parameter" do

      controller_name :foo

      before(:all) do
        setup_controller
        @params = { :day => "03", :month => "may", :year => "1876" }
      end

      after(:all) do
        teardown_controller
      end

      it 'should set the resolution to :day' do
        get :index, @params
        assigns[:resolution].should == :day
      end

      it 'should ask for a UrlDate, passing the url params' do
        expected_params =  {"day"=>"03", "month"=>"may", "year"=>"1876"}
        expect_url_date_params(expected_params)
      end

    end

    describe "when passed a month parameter" do

      controller_name :foo

      before(:all) do
        setup_controller
        @params = { :month => "may", :year => "1876" }
      end

      after(:all) do
        teardown_controller
      end

      it 'should set the resolution to :month' do
        get :index, @params
        assigns[:resolution].should == :month
      end

      it 'should ask for a UrlDate, passing the url params with the day set to "01"' do
        expected_params =  {"day"=>"01", "month"=>"may", "year"=>"1876"}
        expect_url_date_params(expected_params)
      end

    end

    describe "when passed a year parameter with no month or day params" do

      controller_name :foo

      before(:all) do
        setup_controller
        @params = { :year => "1876" }
      end

      after(:all) do
        teardown_controller
      end

      it 'should set the resolution to :year' do
        get :index, @params
        assigns[:resolution].should == :year
      end

      it 'should ask for a UrlDate, passing the url params with day set to "01" and month set to "jan"' do
        expected_params =  {"day"=>"01", "month"=>"jan", "year"=>"1876"}
        expect_url_date_params(expected_params)
      end

    end

    describe "when passed a decade parameter" do

      controller_name :foo

      before(:all) do
        setup_controller
        @params = { :decade => "1870s" }
      end

      after(:all) do
        teardown_controller
      end

      it 'should set the resolution to :decade' do
        get :index, @params
        assigns[:resolution].should == :decade
      end

      it 'should ask for a UrlDate, passing the url params with the day set to "01", month to "jan" and year to first of the decade' do
        expected_params =  {"day"=>"01", "month"=>"jan", "year"=>"1870", "decade"=>"1870s"}
        expect_url_date_params(expected_params)
      end

    end

    describe "when passed a century parameter" do

      controller_name :foo

      before(:all) do
        setup_controller
        @params = { :century => "C19" }
      end

      after(:all) do
        teardown_controller
      end

      it 'should set the resolution to nil' do
        get :index, @params
        assigns[:resolution].should == nil
      end

      it 'should ask for a UrlDate, passing the url params with the day set to "01", month to "jan" and year to first of the century' do
        expected_params =  {"day"=>"01", "month"=>"jan", "year"=>"1800", "century"=>"C19"}
        expect_url_date_params(expected_params)
      end

    end
  end

  describe "when handling a 404 response" do 
    
    controller_name :foo

    before(:all) do
      setup_controller
    end

    after(:all) do
      teardown_controller
    end
    
    it 'should have a status code of 404' do 
      get :send_404
      response.code.should == "404"
    end
    
    it 'should not render anything for types other than html' do 
      get :send_404, :format => 'moo'
      response.body.should == " "
    end
    
    it 'should render the template /static/404 for html requests' do 
      get :send_404
      response.should render_template('static/404')
    end
    
  end

end

describe ApplicationController, 'when asked for section show params' do 
  
  it 'should return a hash setting the format to nil' do 
    @controller.section_show_params.has_key?(:format).should be_true  
    @controller.section_show_params[:format].should be_nil
  end

end