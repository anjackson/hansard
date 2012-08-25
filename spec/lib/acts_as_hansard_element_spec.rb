require File.dirname(__FILE__) + '/../spec_helper'

describe "a class that acts_as_hansard_element" do

  attr_accessor :text, :start_column, :end_column, :start_image, :end_image
    
  before do
    self.class.send(:include, Acts::HansardElement)
    self.class.acts_as_hansard_element
  end

  it "should be extended with Acts::HansardElement::SingletonMethods" do
    self.class.should_receive(:extend).with(Acts::HansardElement::SingletonMethods)
    self.class.acts_as_hansard_element
  end

  describe "with an instance" do

    it "should render it's column as a 'col' tag in xml containing the column number" do
      stub!(:markers).and_yield "column", "column number"
      mock_builder = mock("xml builder")
      mock_builder.should_receive(:col).with("column number")
      marker_xml(:builder => mock_builder)
    end
  
    it "should render it's image as an 'image' tag in xml with the src attribute containing the image source" do
      stub!(:markers).and_yield "image", "image source"
      mock_builder = mock("xml builder")
      mock_builder.should_receive(:image).with(:src => "image source")
      marker_xml(:builder => mock_builder) 
    end

  end

  describe "a hansard_element" do

    before do
      @text = "some text some more"
      @start_column = '56'
      @end_column = '58'
      @start_image = 'S6CV0089P0I0152'
      @end_image = 'S6CV0089P0I0154'
      @options = {}
    end

    it "should yield 'image' and the start image if the start image is different from the current image source passed to it" do
      image_marker(@options) do |marker_type, marker_value|
        marker_type.should == "image"
        marker_value.should == "S6CV0089P0I0152"
      end
    end
    
    it "should set the current image on the options hash passed to it to the last image covered by the contribution if the first image is different from the last image" do
      image_marker(@options){}
      @options[:current_image].should == "S6CV0089P0I0154"
    end
  
    it "should set the current image on the options hash passed to it to the first image covered by the contribution if the first image is the same as the last and different from the current image" do
      @end_image = 'S6CV0089P0I0152'
      image_marker(@options){}
      @options[:current_image].should == "S6CV0089P0I0152"
    end
  
    it "should yield 'column' and the column value if the column is different from the current column passed to it" do
      column_marker(@options) do |marker_type, marker_value|
        marker_type.should == "column"
        marker_value.should == '56'
      end
    end

    it "should set the current column on the options hash passed to it to its end column if the column is different from the current column passed to it" do
      column_marker(@options){}
      @options[:current_column].should == '58'
    end

    it "should call image_markers and column_marker from the markers method and yield the results" do
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

end