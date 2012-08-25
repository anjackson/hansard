require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../../lib/hansard/division_handler'

describe Hansard::DivisionHandler do

  before :all do
    @handler = Hansard::DivisionHandler.new
  end

  it 'should recognize division number in house divided text' do
    @handler.division_list_number_from_divided_text('Main Question, as amended, put:&#x2014;The House divided; Ayes, 83; Noes, 117. (Division List No. 185.)').should == 'Division List No. 185.'
  end

  it 'should not recognize a division number in house divided text if there is not one present' do
    @handler.division_list_number_from_divided_text('Main Question, as amended, put:&#x2014;The House divided; Ayes, 83; Noes, 117.').should be_nil
  end
  
  it 'should not recognize a division number if passed nil' do 
    @handler.division_list_number_from_divided_text(nil).should be_nil
  end

  it 'should set list no on division when clearing the last house divided text' do
    division_number = 'Division List No. 185.'

    placeholder = mock('placeholder')
    placeholder.should_receive(:division_name=).with(division_number)
    divided_text = mock('divided_text')
    @handler.should_receive(:first_house_divided_text).and_return divided_text
    @handler.should_receive(:division_list_number_from_divided_text).with(divided_text).and_return division_number
    @handler.should_receive(:delete_first_house_divided_text)
    @handler.reset_house_divided_text placeholder
  end
  
  it 'should set the xml id of a division attached to a placeholder to the xml id of the contribution before the placeholder if there is one' do 
    division = mock_model(Division)
    placeholder = mock_model(DivisionPlaceholder, :division => division)
    contribution = mock_model(Contribution, :xml_id => 'xml')
    section = mock_model(Section, :contributions => [contribution], :add_contribution => true)
    division.should_receive(:xml_id=).with('xml')
    @handler.set_placeholder_following_divided_text placeholder, section
  end
  
  it 'should not set the xml id of a division attached to a placeholder if the section it belongs to has no previous contribution' do 
    division = mock_model(Division)
    placeholder = mock_model(DivisionPlaceholder, :division => division)
    section = mock_model(Section, :contributions => [], :add_contribution => true)
    division.should_not_receive(:xml_id=).with('xml')
    @handler.set_placeholder_following_divided_text placeholder, section
  end
  

end
