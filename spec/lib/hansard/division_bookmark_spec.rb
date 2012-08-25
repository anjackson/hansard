require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::DivisionBookmark, "when converting a bookmark to an unparsed division placeholder" do 
  
  before do 
    contribution = mock_model(Contribution, :xml_id => 'xml')
    @section = mock_model(Section, :contributions => [contribution])
    @placeholder = mock_model(DivisionPlaceholder, :attributes => {}, :section= => true)
  end

  it 'should set the xml id on the placeholder to the xml id of the previous contribution in the section' do 
    @bookmark = Hansard::DivisionBookmark.new(@placeholder, @section)
    UnparsedDivisionPlaceholder.should_receive(:new).and_return @placeholder
    @placeholder.should_receive(:xml_id=).with('xml')
    @bookmark.convert_to_unparsed_division_placeholder 0
  end
  
  it 'should set the xml id on the placeholder to nil if there is no previous contribution' do 
    section = mock_model(Section, :contributions => [])
    @bookmark = Hansard::DivisionBookmark.new(@placeholder, section)
    UnparsedDivisionPlaceholder.should_receive(:new).and_return @placeholder
    @placeholder.should_not_receive(:xml_id=).with('xml')
    @bookmark.convert_to_unparsed_division_placeholder 0
  end
  
end