require File.dirname(__FILE__) + '/../spec_helper'

describe "a class that acts_as_hansard_element" do
  
  before do
    self.class.send(:include, Acts::HansardElement) if self.class.respond_to? "include"
  end
  
  it "should include Acts::HansardElement::InstanceMethods" do
    self.class.should_receive(:include).with(Acts::HansardElement::InstanceMethods)
    self.class.acts_as_hansard_element
  end
  
  it "should be extended with Acts::HansardElement::SingletonMethods" do
    self.class.should_receive(:extend).with(Acts::HansardElement::SingletonMethods)
    self.class.acts_as_hansard_element
  end

end

describe "a hansard_element" do
  
  attr_accessor :text
  
  before do 
    self.class.send(:include, Acts::HansardElement)
    self.class.acts_as_hansard_element
  end
  
  it "should be able to return a list of the image sources for the image tags in it's text" do
    @text = "some text <image src=\"S6CV0089P0I0153\"> some more text <image src=\"S6CV0089P0I0154\">"
    find_images_in_text.should == ["S6CV0089P0I0153", "S6CV0089P0I0154"]
  end
  
  it "should return an empty list of image sources if it doesn't have text" do
    @text = nil
    find_images_in_text.should == []
  end
  
  it "should be able to return a list of columns for the column tags in it's text" do
    @text = "some text <col>45</col> other text <col>46</col> more text"
    find_columns_in_text.should == [45, 46]
  end
  
  it "should return an empty list of columns if it doesn't have text" do
    @text = nil
    find_columns_in_text.should == []
  end
 
  it "should render it's image as an 'image' tag in xml with the src attribute containing the image source" do
    stub!(:markers).and_yield "image", "image source"
    mock_builder = mock("xml builder")
    mock_builder.should_receive(:image).with(:src => "image source")
    marker_xml(:builder => mock_builder) 
  end
  
  it "should render it's column as a 'col' tag in xml containing the column number" do
    stub!(:markers).and_yield "column", "column number"
    mock_builder = mock("xml builder")
    mock_builder.should_receive(:col).with("column number")
    marker_xml(:builder => mock_builder)
  end

end

describe "a hansard_element with image and column tags in it's text" do

  attr_accessor :text
  
  before do 
    self.class.send(:include, Acts::HansardElement)
    self.class.acts_as_hansard_element
    @text = "some text <col>55</col> <image src=\"S6CV0089P0I0153\"> some more<col>56</col> text <image src=\"S6CV0089P0I0154\">"
    @options = {}
  end

  it "should set the current image source on the options hash passed to it to the source of the last image in it's text when deciding whether to display an image marker" do
    image_marker(@options)
    @options[:current_image_src].should == "S6CV0089P0I0154"
  end
  
  it "should set the current column on the options hash passed to it to the last column in it's text when deciding whether to display a column marker" do
    column_marker(@options)
    @options[:current_column].should == 56
  end

end

describe "a hansard_element with a column attribute and an image attribute and no markers in it's text" do

  attr_accessor :text
  attr_accessor :first_image_source
  attr_accessor :first_col
  
  before do 
    self.class.send(:include, Acts::HansardElement)
    self.class.acts_as_hansard_element
    @text = "some text some more"
    @first_image_source = "S6CV0089P0I0154"
    @first_col = 56
    @options = {}
    
  end

  it "should yield 'image' and the image source if the image source is different from the current image source passed to it" do
    image_marker(@options) do |marker_type, marker_value|
      marker_type.should == "image"
      marker_value.should == "S6CV0089P0I0154"
    end
  end
  
  it "should set the current image source on the options hash passed to it if the image source is different from the current image source passed to it" do
    image_marker(@options){}
    @options[:current_image_src].should == "S6CV0089P0I0154"
  end
  
  it "should yield 'column' and the column value if the column is different from the current column passed to it" do
    column_marker(@options) do |marker_type, marker_value|
      marker_type.should == "column"
      marker_value.should == 56
    end
  end
  
  it "should set the current column on the options hash passed to it if the column is different from the current column passed to it" do
    column_marker(@options){}
    @options[:current_column].should == 56
  end
  
  it "should call image_markers and column_markers from the markers method and yield the results" do
    should_receive(:image_marker).with(@options).and_yield("image", "image source")
    should_receive(:column_marker).with(@options).and_yield("column", "column value")
    yielded_markers = {}
    markers(@options) do |marker_type, marker_value|
      yielded_markers[marker_type] = marker_value
    end
    yielded_markers.should == {"image"  => "image source", 
                                "column" => "column value"}
  end

end

