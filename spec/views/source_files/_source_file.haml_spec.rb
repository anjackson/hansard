require File.dirname(__FILE__) + '/../../spec_helper'

describe "source_files/_source_file.haml", " in general" do
  
  before do 
    @source_file = mock_model(SourceFile)
    @source_file.stub!(:name).and_return("source name")
    @source_file.stub!(:log)
    @controller.template.stub!(:source_file).and_return(@source_file)
  end
  
  def do_render
    render 'source_files/_source_file.haml'
  end
  
  it "should have a link containing the source file name" do  
    do_render
    response.should have_tag("a", :text => "source name")
  end
  
  it "should show the text 'problem' if the source file has content in it's log" do 
    @source_file.should_receive(:log).and_return("oops")
    do_render
    response.should have_tag('div', :text => "source name\n  (problems)")
  end

end