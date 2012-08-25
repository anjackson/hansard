require File.dirname(__FILE__) + '/../spec_helper'

describe VolumesController, " in general" do 
  it_should_behave_like "All controllers"
end


describe VolumesController, " when mapping routes" do

  it "should map { :controller => 'volumes', :action => 'index' } to /volumes " do
    params = { :controller => 'volumes', :action => 'index' }
    route_for(params).should == '/volumes'
  end

  it 'should map { :controller => "volumes", :action => "series_index", :series => "6C" } to /volumes/6C' do 
    params = { :controller => 'volumes', :action => "series_index", :series => "6C"  }
    route_for(params).should == '/volumes/6C'
  end
  
  it 'should map { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654" } to /volumes/6C/654' do 
    params = { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654" }
    route_for(params).should == '/volumes/6C/654'
  end
  
  it 'should not map { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "C54"}' do
    params = { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "C54"}
    lambda{ route_for(params) }.should raise_error(ActionController::RoutingError)
  end
  
  it 'should map { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654", :part => 1 } to /volumes/6C/654/1' do 
    params = { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654", :part => 1 }
    route_for(params).should == '/volumes/6C/654/1'
  end
  
  it 'should not map { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654", :part => "D"}' do 
    params = { :controller => "volumes", :action => "show", :series => "6C", :volume_number => "654", :part => "D" } 
    lambda{ route_for(params) }.should raise_error(ActionController::RoutingError)
  end

  it 'should map { :controller => "volumes", :action => "monarch_index", :monarch_name => "elizabeth-ii"} to /volumes/elizabeth-ii' do 
    params = { :controller => "volumes", :action => "monarch_index", :monarch_name => "elizabeth-ii"}
    route_for(params).should == '/volumes/elizabeth-ii'
  end
  
  it 'should not map /volumes/elizabeth-i' do 
    params = { :controller => "volumes", :action => "monarch_index", :monarch_name => "elizabeth-i"}
    lambda{ route_for(params) }.should raise_error(ActionController::RoutingError)
  end
  
  it 'should not map /volumes/C4' do 
    params = { :controller => "volumes", :action => 'series_index', :series => 'C4'}
    lambda{ route_for(params) }.should raise_error(ActionController::RoutingError)
  end
  
end


describe VolumesController, " when handling a GET request to /volumes" do 

  before do
    Monarch.stub!(:list).and_return('list')
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should ask for all the series' do 
    Series.should_receive(:find_all)
    do_get
  end
  
  it 'should assign series to the view' do
    do_get
    assigns[:series].should_not be_nil
  end
  
  it 'should ask for a list of monarchs' do 
    Monarch.should_receive(:list)
    do_get
  end
  
  it 'should assign the list of monarchs to the view' do 
    do_get
    assigns[:monarchs].should_not be_nil
  end

end

describe VolumesController, " when handling a GET request to /volumes/6C" do 
  
  before do 
    Series.stub!(:find_all_by_series).and_return(['series'])
  end
  
  def do_get
    get :series_index, :series => '6C'
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should ask for any series matching "6C"' do 
    Series.should_receive(:find_all_by_series).with('6C').and_return(['series'])
    do_get
  end
  
  it 'should assign the list of series returned to the view' do
    do_get
    assigns[:series_list].should == ['series']
  end
  
end

describe VolumesController, " when handling a GET request to /volumes/6C/654" do
  
  before do 
    Series.stub!(:find_by_series) 
    Volume.stub!(:find_all_by_identifiers).and_return([])
  end
  
  def do_get
    get :show, :series => '6C', :volume_number => '654'
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should ask for the series "6C"' do 
    Series.should_receive(:find_by_series).with('6C').and_return('series')
    do_get
  end
  
  it 'should assign series to the view' do
    Series.stub!(:find_by_series).and_return('series')
    do_get
    assigns[:series].should == 'series'
  end
  
  it 'should ask for a volume by series, volume number and part' do
    Volume.should_receive(:find_all_by_identifiers).with('6C', '654', nil).and_return(['volume'])
    do_get
  end
  
  it 'should assign the volume to the view' do 
    Volume.stub!(:find_all_by_identifiers).and_return(['volume'])
    do_get
    assigns[:volumes].should == ['volume']
  end
  
  it 'should respond with an error message when given identifiers that don\'t match any volume' do
    Volume.should_receive(:find_all_by_identifiers).with('6C', '654', nil).and_return([])
    do_get
    response.should render_template('volumes/no_volume') 
  end
  
end

describe VolumesController, " when handling a GET request to /volumes/elizabeth-ii" do 
  
  before do 
    Monarch.stub!(:slug_to_name).and_return('name')
  end
  
  def do_get
    get :monarch_index, :monarch_name => 'elizabeth-ii'
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it 'should ask for the monarch name' do 
    Monarch.should_receive(:slug_to_name).with('elizabeth-ii').and_return('name')
    do_get
  end
  
  it 'should assign the name to the view' do 
    do_get
    assigns[:monarch].should == 'name'
  end
  
  it 'should ask for the volumes in the reign of the monarch sorted by first regnal year and then volume number and part' do 
    Volume.should_receive(:find_all_by_monarch).with("name", :order => "first_regnal_year asc, number asc, part asc").and_return('volumes')
    do_get
  end
  
  it 'should assign the volumes to the view' do 
    Volume.stub!(:find_all_by_monarch).and_return("volumes")
    do_get
    assigns[:volumes].should == 'volumes'
  end
  
end
