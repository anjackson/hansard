require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::WrittenParserHelper do 

  before do 
    self.class.send(:include, Hansard::WrittenParserHelper)
  end

  describe 'when creating a written contribution' do 
    
    before do 
      @image = 'test image'
      stub!(:get_contribution_type_for_question).and_return(Contribution)
      @element = mock('element', :attributes => {})
      stub!(:anchor_id).and_return('the anchor id')
    end
    
    it 'should ask for an anchor id and set it on the contribution' do 
      contribution = create_written_contribution(@element)
      contribution.anchor_id.should == 'the anchor id'
    end
    
    it 'should set the start and end image on the contribution as the current image' do 
      contribution = create_written_contribution(@element)
      contribution.start_image.should == 'test image'
      contribution.end_image.should == 'test image'
    end
    
  end

end
