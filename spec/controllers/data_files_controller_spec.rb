require File.dirname(__FILE__) + '/../spec_helper'

describe DataFilesController, "#route_for" do
  
  it "should map { :controller => 'data_files', :action => 'index'} to /data_files" do
    params = { :controller => 'data_files', :action => 'index' }
    route_for(params).should == '/data_files'
  end

  it "should map { :controller => 'data_files', :action => 'show_warnings'} to /data_files/warnings" do
    params = { :controller => 'data_files', :action => 'show_warnings' }
    route_for(params).should == "/data_files/warnings"
  end

end
