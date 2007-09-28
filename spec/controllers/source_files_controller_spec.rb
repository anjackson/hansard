require File.dirname(__FILE__) + '/../spec_helper'

describe SourceFilesController, "#route_for" do

  it "should map { :controller => 'source_files', :action => 'index'} to /source_files" do
    params = { :controller => 'source_files', :action => 'index' }
    route_for(params).should == '/source_files'
  end

  it "should map { :controller => 'source_files', :action => 'show', :name =>  'S5LV0436P0'} to /source_files/S5LV0436P0" do
    params = { :controller => 'source_files', :action => 'show', :name => 'S5LV0436P0' }
    route_for(params).should == "/source_files/S5LV0436P0"
  end

end

describe SourceFilesController, " when handling GET /source_files" do

  before do
    @source_file = mock_model(SourceFile)
    SourceFile.stub!(:find).and_return([@source_file])
    SourceFile.stub!(:get_error_summary).and_return([],{})
  end

  def do_get
    get :index
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find all the source files" do
    SourceFile.should_receive(:find).with(:all, :order => "name asc").and_return([@source_file])
    do_get
  end

  it "should render with the 'index' template" do
    do_get
    response.should render_template('index')
  end

  it "should assign the source files for the view" do
    do_get
    assigns[:source_files].should == [@source_file]
  end

end

describe SourceFilesController, " when handling GET /source_files/S5LV0436P0" do

  before do
    @source_file = mock_model(SourceFile)
    SourceFile.stub!(:find_by_name).and_return(@source_file)
  end

  def do_get
    get :show, :name => "S5LV0436P0"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the requested source files" do
    SourceFile.should_receive(:find_by_name).with('S5LV0436P0').and_return(@source_file)
    do_get
  end

  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end

  it "should assign the source file for the view" do
    do_get
    assigns[:source_file].should == @source_file
  end

end