require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::ParserHelper do

  before do
    self.class.send(:include, Hansard::ParserHelper)
  end

  describe 'when getting root element' do

    it 'should find root name' do
      doc = Hpricot.XML "\n<root/>"
      get_root_name(doc).should == 'root'
    end

  end

  describe 'when asked to find member name' do

    it 'should log warning if unexpected element occurs in member name' do
      doc = Hpricot.XML "<member><section/></member>"
      should_receive(:log)
      handle_member_name(doc.at('member'), mock('contribution'))
    end
    
    describe 'when handling a column element in a member name' do 
      
      before do 
        @text = "<p id=\"S5CV0835P0-02848\"><member>The Secretary of State for Foreign and Commonwealth Affairs (Sir Alec
        <col>1028</col>
        Douglas-Home)</member><membercontribution>: It is our wish.</membercontribution></p>"
        @member_element = Hpricot.XML(@text).at('member')
        @contribution = mock_model(Contribution, :member_name => '', :member_name= => true)
      end
      
      it 'should handle the column element' do 
        column_element = @member_element.at('col')
        should_receive(:handle_image_or_column).with(column_element)
        handle_member_name @member_element, @contribution
      end

      it 'should set the name correctly' do 
        contribution = Contribution.new(:member_name => '')
        handle_member_name @member_element, contribution
        contribution.member_name.should == 'The Secretary of State for Foreign and Commonwealth Affairs (Sir Alec Douglas-Home)'
      end
      
    end
  end
  
  describe 'when handling a column or image generally' do 

    it 'should set the current column for a column' do
      element = Hpricot.XML('<col>56</col>').at('col')
      handle_image_or_column(element)
      @column.should == '56'
    end
    
    it 'should set the current image for an image' do
      element = Hpricot.XML('<image src="S5CV0052P0I0006"/>').at('image')
      handle_image_or_column(element)
      @image.should == 'S5CV0052P0I0006'
    end
  
  end
  
  describe 'when handling an image in a contribution' do
  
    before do 
      @contribution = mock_model(Contribution, :end_image= => true)
      @image_tag = Hpricot('<image src="S5CV0052P0I0006"/>')
      stub!(:handle_image_or_column)
      @image = 'S5CV0052P0I0006'
    end
  
    it 'should handle the image in the general way of handling any image or column' do 
      should_receive(:handle_image_or_column).with(@image_tag)
      handle_contribution_image(@image_tag, @contribution)
    end
  
    it 'should set the contributions end image to the image' do 
      @contribution.should_receive(:end_image=).with('S5CV0052P0I0006')
      handle_contribution_image(@image_tag, @contribution)
    end
  
  end
  
  describe 'when setting columns and images on a contribution' do
    
    before do 
      @contribution = mock_model(Contribution)
      @element = Hpricot.XML('<col>34</col><image src="S5CV0052P0I0006"/>')
      stub!(:handle_contribution_col)
      stub!(:handle_contribution_image)
    end
    
    it 'should handle each column within the contribution' do 
      should_receive(:handle_contribution_col).with(@element.at('col'), @contribution)
      set_columns_and_images_on_contribution(@element, @contribution)
    end
    
    it 'should handle each image within the contribution' do 
      should_receive(:handle_contribution_image).with(@element.at('image'), @contribution)
      set_columns_and_images_on_contribution(@element, @contribution)
    end
    
  end
  
  describe 'when making contributions' do 
    
    before do 
      @node = mock('node', :inner_html => '', :to_s => '', :attributes => {})
      @section = mock_model(Section, :contributions => [])
      stub!(:anchor_id).and_return('the anchor id')
      @image = 'test image'
    end
    
    describe 'when handling a table element' do 
    
      before do 
        handle_table_element @node, @section
      end
    
      it 'should set the anchor_id on the contribution' do 
        @section.contributions.last[:anchor_id].should == 'the anchor id'
      end
    
      it 'should set the start and end image on the table' do 
        handle_table_element @node, @section
        @section.contributions.last[:start_image].should == 'test image'
        @section.contributions.last[:end_image].should == 'test image'      
      end
 
    end
  
    describe 'when handling a quote contribution' do 
    
      before do 
        handle_quote_contribution @node, @section
      end
  
      it 'should ask for an anchor_id and set the anchor_id on the contribution' do 
        @section.contributions.last[:anchor_id].should == 'the anchor id'
      end
    
      it 'should set the start and end image on the quote' do 
        @section.contributions.last[:start_image].should == 'test image'
        @section.contributions.last[:end_image].should == 'test image'
      end
    
    end

  end
  
end
