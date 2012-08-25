require File.dirname(__FILE__) + '/../spec_helper'
include DivisionsHelper

describe DivisionsHelper do

  def mock_division sub_section=nil
    mock('division', :sub_section=> sub_section)
  end

  it "should return true if given an array containing one array containing a division" do
    one_division_section?([ [mock_division] ]).should be_true
  end
  
  it 'should return false if given an array containing an array of two divisions, one with a section' do   
    one_division_section?([ [mock_division(mock(Section)), mock_division] ]).should be_false
  end
  
  it 'should return true if given an array containing an array of two divisions' do 
    one_division_section?([ [mock_division, mock_division] ]).should be_true
  end
  
  it 'should return false if given an array containing two arrays, each containing a division' do 
    one_division_section?([ [mock_division], [mock_division] ]).should be_false
  end
  
  it 'should return false if given an array containing an empty array' do 
    one_division_section?([ [] ]).should be_false
  end

  it 'should format division title when division has name' do
    name = 'Division No. 156]'
    section = 'ADMISSIBILITY OF HEARSAY EVIDENCE'
    division = mock('division', :name=>name, :section_title=>section)
    division_title(division).should == "#{section}—#{name}"
  end

  it 'should format division title when division does not have name' do
    name = nil
    section = 'ADMISSIBILITY OF HEARSAY EVIDENCE'
    division = mock('division', :name=>name, :section_title=>section)
    division_title(division).should == "#{section}—Division"
  end

end

describe DivisionsHelper, 'when linking to' do
  
  before do 
    @section = mock_model(Section)
    @anchor_id = 'id123'
    @section_url = "http://localhost:3000/commons/1957/jul/03/new-clause-reduction-of-purchase-tax"
    stub!(:section_url).with(@section).and_return(@section_url)
  end

  it 'should link to division page, if there is a division number' do
    division_number = 'division_160'
    division = mock_model(Division, :number => 160, 
                                    :division_id => division_number, 
                                    :section => @section, 
                                    :sub_section => nil, 
                                    :anchor_id => @anchor_id) 
    link = link_to_division(division)
    link.should have_tag("a[href=#{@section_url}/#{division_number}]", :text => '160')
  end

  it 'should link to division in its section by anchor, if there is no division number' do
    division = mock_model(DivisionPlaceholder, :number => '?', 
                                               :division_id => 'division_1', 
                                               :section => @section, 
                                               :sub_section => nil, 
                                               :anchor_id => @anchor_id)
    link = link_to_division(division)
    link.should have_tag("a[href=#{@section_url}##{@anchor_id}]", :text => '?')
  end

  it 'should link to division in its sub-section, if there is no division number' do
    division = mock_model(DivisionPlaceholder, :number => '?', 
                                               :division_id => 'division_1', 
                                               :section => mock_model(Section), 
                                               :sub_section => @section, 
                                               :anchor_id => @anchor_id)
    link = link_to_division(division)
    link.should have_tag("a[href=#{@section_url}##{@anchor_id}]", :text => '?')
  end
  

  it 'should return comma separated links to divisions' do
    division1 = mock_model(Division)
    division2 = mock_model(Division)

    stub!(:link_to_division).with(division1).and_return 'link1'
    stub!(:link_to_division).with(division2).and_return 'link2'

    link_to_divisions([division1, division2]).should == 'link1, link2'
  end

  it 'should link to the bill page if a division is associated with a bill' do
    section_title = 'FACTORIES BILL'
    bill = mock(Bill, :slug=>'slug')
    division = mock(Division, :section_title=>section_title, :bill => bill)
    bill_url = 'http://localhost:3000/bills/factories-bill'
    stub!(:bill_url).with(bill).and_return bill_url
    title = format_division_section_title(division)
    title.should have_tag("a[href=#{bill_url}]", :text => section_title)
  end
  
  it 'should not link to the bill page if given a division placeholder' do 
    section_title = 'FACTORIES BILL'
    division_placeholder = mock_model(UnparsedDivisionPlaceholder, :section_title => section_title)
    title = format_division_section_title(division_placeholder)
    title.should == section_title
  end

  it 'should return "" if division section has no title' do
    division = mock(Division, :section_title=>nil)
    format_division_section_title(division).should == ''
  end

end
