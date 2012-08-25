require File.dirname(__FILE__) + '/../spec_helper'

describe DataFilesController do

  it_should_behave_like "All controllers"

  describe "when creating route from parameters" do
    def check_route action, route
      route_for({ :controller => 'data_files', :action => action }).should == route
    end

    it "should create index route" do
      check_route 'index', '/data_files'
    end

    it "should create show_warnings route" do
      check_route 'show_warnings', "/data_files/warnings"
    end

    it "should create reload_written_answers_for_date route" do
      check_route 'reload_written_answers_for_date',  "/data_files/reload_written_answers_for_date"
    end
    
    it "should create reload_written_statements_for_date route" do
      check_route 'reload_written_statements_for_date',  "/data_files/reload_written_statements_for_date"
    end

    it "should create reload_lords_for_date route" do
      check_route 'reload_lords_for_date', "/data_files/reload_lords_for_date"
    end

    it "should create reload_commons_for_date route" do
      check_route 'reload_commons_for_date', "/data_files/reload_commons_for_date"
    end
  end

  describe "when asked to find files" do
    it "should assign a list of DataFiles to @data_files when :action => 'index'" do
      data_files = [mock(DataFile)]
      DataFile.should_receive(:find).with(:all).and_return(data_files)
      get :index
      assigns[:data_files].should == data_files
    end

    it "should assign a list of DataFiles which respond to .log?, sorted by name and grouped by saved, to @data_files when :action => 'warnings'" do
      data_file = mock(DataFile)
      data_files = [data_file]
      DataFile.should_receive(:find).with(:all).and_return(data_files)
      data_file.should_receive(:log?).and_return(true)
      data_file.should_receive(:name).and_return(true)
      data_file.should_receive(:saved).and_return(true)
      get :show_warnings
      assigns[:data_files].should == [[true, data_files]]
    end
  end

  describe "when asked to reload files" do
    before do
      @date = Date.new(1885, 3, 27)
      @data_file = mock_model(DataFile)
    end

    def check_reload action, route_name
      @controller.should_receive(action).with(@date).and_return(@data_file)
      DataFile.should_receive(:find).with(@data_file.id)
      post route_name, {:date => '1885-03-27'}
    end

    it "should reload written answers for a date when given that date" do
      check_reload :reload_written_answers_on_date, :reload_written_answers_for_date
    end

    it "should reload lords for a date when given that date" do
      check_reload :reload_lords_on_date, :reload_lords_for_date
    end

    it "should reload commons for a date when given that date" do
      check_reload :reload_commons_on_date, :reload_commons_for_date
    end

    it "should render '' if reloading the data file is not possible" do
      DataFile.stub!(:reload_possible?).and_return(false)
      @controller.expect_render({:text => ''})
      post :reload_commons_for_date, {:date => '1885-03-27'}
    end

    it "should not reload a lords file, but render :text as '' when the request is not 'post'" do
      @controller.should_not_receive(:reload_lords_on_date).with(@date).and_return(@data_file)
      get :reload_lords_for_date, {:date => '1885-03-27'}
    end
  end
end
