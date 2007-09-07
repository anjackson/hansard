require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/show.haml", " in general" do
  
  before do 
    @source_file = mock_model(SourceFile)
    @source_file.stub!(:name).and_return("source name")
    @source_file.stub!(:data_files).and_return([])
    @source_file.stub!(:log).and_return("")
    @source_file.stub!(:schema).and_return("")
    assigns[:source_file] = @source_file
  end
  
  def do_render
    render 'source_files/show.haml'
  end
  
  it "should have an 'h1' tag containing the name of the source file'" do 
    do_render
    response.should have_tag("h1", :text => "source name")
  end
  
  it "should have a 'div' tag containing the source file's schema" do 
    @source_file.should_receive(:schema).and_return("schema_v8.xsd")
    do_render
    response.should have_tag('div', :text => "schema_v8.xsd")
  end
  
  it "should render the data file partial passing the source file's data files" do
    @controller.template.should_receive(:render).with(:partial => "data_file", :collection => @source_file.data_files)  
    do_render
  end

  it "should have a div showing the source file log" do
    @source_file.should_receive(:log).and_return("a big error")
    do_render
    response.should have_tag("div", :text => "a big error")
  end
  
  it "should have a div showing the source file schema" do 
    @source_file.should_receive(:schema).and_return("schema_v3.xsd")
    do_render
    response.should have_tag("div", :text => "schema_v3.xsd")
  end

end