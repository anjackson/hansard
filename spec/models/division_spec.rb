require File.dirname(__FILE__) + '/../spec_helper'

def mock_a_division name, section, number, sub_section=nil, date=Date.new(1970,1,1), object_id=nil
  mock_model(Division, :name=>name, 
                       :number => number, 
                       :section => section, 
                       :section_title => section.title, 
                       :alphanumeric_section_title => section.title,
                       :date => date, 
                       :sub_section => sub_section, 
                       :sub_section_title => sub_section ? sub_section.title : nil,
                       :index_letter => section.title[0])

end

describe Division, 'when grouping divisions' do

  before do
    @finance_bill_section = mock_model(Section, :title => 'Finance Bill')
    @finance_bill_clause1 = mock_model(Section, :title => 'clause 1', :parent_section => @finance_bill_section)
    @finance_bill_clause2 = mock_model(Section, :title => 'clause 2', :parent_section => @finance_bill_section)
    @another_finance_bill_section = mock_model(Section, :title => 'Finance Bill')
    @health_bill_section = mock_model(Section, :title => 'Health Bill')
  
    @finance_bill_clause1_division =  mock_a_division 'finance_bill_clause1_division', @finance_bill_section, 57, @finance_bill_clause1
    @finance_bill_clause1_division2 = mock_a_division 'finance_bill_clause1_division2', @finance_bill_section, 58, @finance_bill_clause1
    @finance_bill_clause2_division =  mock_a_division 'finance_bill_clause2_division', @finance_bill_section, 59, @finance_bill_clause2
    @another_finance_bill_division =  mock_a_division 'another_finance_bill_division', @another_finance_bill_section, 60, nil, Date.new(1970,2,1)
    @health_division = mock_a_division 'health_division', @health_bill_section, 61
  
    @divisions = [
      @finance_bill_clause2_division,
      @finance_bill_clause1_division2,
      @finance_bill_clause1_division,
      @another_finance_bill_division,
      @health_division]
  
    @sorted_first_finance_bill = [[@finance_bill_clause1_division, @finance_bill_clause1_division2], [@finance_bill_clause2_division]]
  end

  it 'should return all divisions in groups by section and sub_section, sorted by section title then date, then division number' do
    Division.stub!(:all_including_unparsed).and_return @divisions
    Division.stub!(:sort_by_division_number).with([[@finance_bill_clause2_division], [@finance_bill_clause1_division2, @finance_bill_clause1_division]]).and_return @sorted_first_finance_bill
    Division.stub!(:sort_by_division_number).with([[@another_finance_bill_division]]).and_return [[@another_finance_bill_division]]
    Division.stub!(:sort_by_division_number).with([[@health_division]]).and_return [[@health_division]]
  
    Division.divisions_in_groups_by_section_and_sub_section.should == [
      @sorted_first_finance_bill,
      [[@another_finance_bill_division]],
      [[@health_division]]
    ]
  end

  it 'should return all divisions in groups by section title, section and sub_section, sorted by date, then division number' do
    @sorted_first_finance_bill = [[@finance_bill_clause1_division, @finance_bill_clause1_division2], [@finance_bill_clause2_division]]
  
    Division.stub!(:divisions_in_groups_by_section_and_sub_section).and_return [
      @sorted_first_finance_bill,
      [[@another_finance_bill_division]],
      [[@health_division]]
    ]
  
    Division.divisions_in_groups_by_section_title_and_section_and_sub_section.should == [
      [@sorted_first_finance_bill, [[@another_finance_bill_division]] ],
      [[[@health_division]]]
    ]
  end

end

describe Division, 'when asked for divisions in groups by section and subsection' do


  it 'should return ask for divisions that have section title matching supplied letter' do
    Division.should_receive(:all_including_unparsed).with('B').and_return []
    Division.divisions_in_groups_by_section_and_sub_section('B')
  end

  it 'should return empty array if no divisions have section title matching supplied letter' do
    Division.stub!(:all_including_unparsed).and_return []
    Division.divisions_in_groups_by_section_and_sub_section('B').should == []
  end

  it 'should return all divisions in groups by section, sorted by section title then date' do
    finance_bill_section = mock_model(Section, :title => 'Finance Bill')
    another_finance_bill_section = mock_model(Section, :title => 'Finance Bill')
    health_bill_section = mock_model(Section, :title => 'Health Bill')

    finance_bill_division = mock_a_division 'finance_bill_division', finance_bill_section, 1, nil, Date.new(1970,1,1), 2
    finance_bill_division2 = mock_a_division 'finance_bill_division2', finance_bill_section, 2, nil, Date.new(1970,1,1), 1
    another_finance_bill_division = mock_a_division 'another_finance_bill_division', another_finance_bill_section, 66, nil, Date.new(1970,2,1), 3
    health_division = mock_a_division 'health_division', health_bill_section, 59, nil, Date.new(1970,1,1), 4

    divisions = [
      finance_bill_division,
      another_finance_bill_division,
      finance_bill_division2,
      health_division]

    Division.stub!(:all_including_unparsed).and_return divisions
    Division.stub!(:sort_by_division_number).with([ [finance_bill_division2, finance_bill_division] ]).and_return [[finance_bill_division, finance_bill_division2]]
    Division.stub!(:sort_by_division_number).with([ [another_finance_bill_division] ]).and_return [[another_finance_bill_division]]
    Division.stub!(:sort_by_division_number).with([ [health_division] ]).and_return [[health_division]]

    Division.divisions_in_groups_by_section_and_sub_section.should == [
      [[finance_bill_division, finance_bill_division2]], [[another_finance_bill_division]], [[health_division]]
    ]
  end

  it 'should sort groups by division number' do
    division57 = Division.new; division57.stub!(:number).and_return 57
    division58 = Division.new; division58.stub!(:number).and_return 58
    division59 = Division.new; division59.stub!(:number).and_return 59

    Division.sort_by_division_number([[division59], [division58, division57]]).should == ([[division57, division58], [division59]])
  end

  it 'should return its section' do
    section = mock('section')
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :section_for_division => section)
    division.section.should == section
  end

  it 'should return its sub-section' do
    section = mock('section')
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :sub_section => section)
    division.sub_section.should == section
  end

  it 'should return its divided text' do
    divided_text = 'divided_text'
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :divided_text => divided_text)
    division.divided_text.should == divided_text
  end

  it 'should return its result text' do
    result_text = 'result_text'
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :result_text => result_text)
    division.result_text.should == result_text
  end

  it 'should return its sub-section title' do
    title = 'title'
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :sub_section_title => title)
    division.sub_section_title.should == title
  end

  it 'should return its date' do
    date = Date.new(1970,1,1)
    division = Division.new
    division.stub!(:division_placeholder).and_return mock_model(DivisionPlaceholder, :date => date)
    division.date.should == date
  end

  it 'should create a division_id from its number' do
    division = Division.new
    division.stub!(:number).and_return 57
    division.division_id.should == 'division_57'

    division = Division.new
    division.stub!(:number).and_return nil
    division.division_id.should == 'division_'
  end

  it 'should return the sitting it occured in' do
    sitting = mock(Sitting)
    section = mock(Section, :sitting => sitting )
    division = Division.new
    division.stub!(:section).and_return section
    division.sitting.should == sitting
  end

  it 'should return the house it occured in' do
    sitting = mock(Sitting, :house => 'Commons')
    division = Division.new
    division.stub!(:sitting).and_return sitting
    division.house.should == 'Commons'
  end

end

describe Division, 'when calculating its number' do

  def mock_a_division name
    Division.new :name => name
  end

  def mock_divisions number
    names = ["Division #{number}.]",
              "Division #{number}.",
              "Division NO. #{number}.]",
              "Division No #{number}.]",
              "Division No #{number}.",
              "Division No. #{number}.]",
              "Division No. #{number}]",
              "Division No. #{number}",
              "Division No. #{number}.",
              "Division No. #{number}].",
              "Division No. #{number}.1",
              "Division No. #{number}.],",
              "Division No. #{number}.)",
              "Division No. #{number}.1]",
              "Division No.#{number}.]",
              "Divison No.#{number}"]
    names.collect {|n| mock_a_division n}
  end

  it 'should return index_in_section + 1 when name is nil' do
    division = mock_a_division(nil)
    division.should_receive(:index_in_section).and_return 0
    division.calculate_number.should == 1
  end

  it 'should return index_in_section + 1 when name is empty string' do
    division = mock_a_division('')
    division.should_receive(:index_in_section).and_return 1
    division.calculate_number.should == 2
  end

  it 'should return its nil when name is without number' do
    mock_divisions('').each { |d| d.calculate_number.should == nil unless d.name == 'Division No. .1' }
  end

  it 'should return its number when number in name is 1' do
    number = 1
    mock_divisions(number).each { |d| d.calculate_number.should == number }
  end

  it 'should return its number when number in name is 32' do
    number = 32
    mock_divisions(number).each { |d| d.calculate_number.should == number }
  end

  it 'should return its number when number in name is 932' do
    number = 932
    mock_divisions(number).each { |d| d.calculate_number.should == number }
  end

end

describe Division, 'when finding all including unparsed divisions' do
  
  before do 
    @includes = [{:division_placeholder => {:section => [:sitting, :parent_section]}}, :bill]
  end
  
  it 'should only ask for divisions with the index letter passed' do 
    Division.should_receive(:find).with(:all, {:include => @includes, 
                                               :conditions => ['index_letter = ?', 'A']})
    Division.all_including_unparsed 'A'
  end
  
  it 'should ask for all divisions if no index letter is passed' do 
    Division.should_receive(:find).with(:all, {:include => @includes})
    Division.all_including_unparsed 
  end
  
  it 'should only return placeholders that start with the letter passed' do 
    a_placeholder = mock_model(UnparsedDivisionPlaceholder, :index_letter => 'A')
    b_placeholder = mock_model(UnparsedDivisionPlaceholder, :index_letter => 'B')
    Division.stub!(:find).and_return([])
    UnparsedDivisionPlaceholder.stub!(:find).and_return([a_placeholder, b_placeholder])
    Division.all_including_unparsed('A').should == [a_placeholder]
  end
  
end

describe Division, 'when recognizing division result text' do
=begin
  Not sure whether these are "division results":
<i>It being after Eleven of the Clock, Mr. SPEAKER proceeded, pursuant to Standing Order No. 15, to put forthwith the Question necessary to dispose of the Vote.</i></p>
<i>It being after Eleven of the Clock, the Chairman proceeded, pursuant to Standing Order No. 15, to put forthwith time Question necessary to dispose of the Vote.</i></p>
<i>Main Question put forthwith, pursuant to Standing Order No. 62 (Amendment on Second or Third Reading):</i>&#x2014;</p>
<i>Question,</i> That the proposed words be there added, <i>put forthwith, pursuant to Standing Order No.31 (Questions on amendments):&#x2014;</i></p>
<i>Resolved</i>,</p>
<i>The remaining Orders were read, and postponed.</i></p>
Supply considered in Committee.</p>
The House divided: Ayes, 45; Noes, 416.</p>
The committee divided: Ayes, 106; Noes, 180.</p>
Motion made, and Question put,
Motion made, and a Question put, "That the Bill be committed to a Select Committee."&#x2014;[<i>Captain Bourne.</i>]</p>
Original Question again proposed.</p>
Question again proposed, "That the Clause be postponed."</p>
Question proposed, "That those words be there added."</p>
Question put accordingly, "That the Chairman do report Progress, and ask leave to sit again."</p>
Question put accordingly, "That the Chairman do report Progress, leave to sit again."</p>
Question put accordingly, "That the Clause he postponed."</p>
Question put accordingly, "That the Clause stand part of the Bill."</p>
Question put accordingly, "That those words be there inserted."</p>
Question put accordingly, That the word 'twenty-six' stand part of the Clause."</p>
Question put accordingly, That those words be there inserted."</p>
Question put, "That the Question be put."</p>
Question put, "That the Question, 'That the Clause stand part of the Bill,' be now put."</p>
=end

  def should_be_result text, expected=true
    Division.is_a_division_result?(text).should == expected
  end

  it 'should recognize "Main Question put forthwith, pursuant to Standing Order No. 62 (Amendment on Second or Third Reading), and agreed to"' do
    should_be_result 'Main Question put forthwith, pursuant to Standing Order No. 62 (Amendment on Second or Third Reading), and agreed to'
  end

  it 'should recognize "Lords amendments Nos. 2 and 3 agreed to."' do
    should_be_result 'Lords amendments Nos. 2 and 3 agreed to.'
  end

  it 'should recognize "Lords amendment agreed to"' do
    should_be_result 'Lords amendment agreed to'
  end

  it 'should recognize "Bill committed to a Standing Committee"' do
    should_be_result 'Bill committed to a Standing Committee'
  end

  it 'should recognize "Bill read a Second time, and committed a Committee of the Whole House"' do
    should_be_result 'Bill read a Second time, and committed a Committee of the Whole House'
  end

  it 'should recognize "MADAM DEPUTY SPEAKER forthwith declared the main Question, as amended, to be agreed to."' do
    should_be_result 'MADAM DEPUTY SPEAKER forthwith declared the main Question, as amended, to be agreed to.'
  end

  it 'should recognize "Main Question, as amended, put, and agreed to."' do
    should_be_result 'Main Question, as amended, put, and agreed to.'
  end

  it 'should recognize "On Question, Resolution agreed to."' do
    should_be_result 'On Question, Resolution agreed to.'
  end

  it 'should recognize "Original Question put, and agreed to."' do
    should_be_result 'Original Question put, and agreed to.'
  end

  it 'should recognize "Question, "That the words proposed to be left out, to the word twenty-six, \' in page 1, line 13, stand part of the Clause, "put accordingly, and agreed to."' do
    should_be_result 'Question, "That the words proposed to be left out, to the word twenty-six, \' in page 1, line 13, stand part of the Clause, "put accordingly, and agreed to.'
  end

  it 'should recognize "Question, "That this House doth agree with the Committee in the said Resolution," put, and agreed to."' do
    should_be_result 'Question, "That this House doth agree with the Committee in the said Resolution," put, and agreed to.'
  end
  it 'should recognize "Question accordingly agreed to"' do
    should_be_result 'Question accordingly agreed to'
  end

  it 'should recognize "Question accordingly negatived"' do
    should_be_result 'Question accordingly negatived'
  end

  it 'should recognize "Bill read a Second time"' do
    should_be_result 'Bill read a Second time'
  end

  it 'should recognize "Bill read the Third time and passed"' do
    should_be_result 'Bill read the Third time and passed'
  end

  it 'should recognize "Second Resolution read a Second time"' do
    should_be_result 'Second Resolution read a Second time'
  end

  it 'should recognize "Resolved in the negative, and Motion disagreed to accordingly"' do
    should_be_result 'Resolved in the negative, and Motion disagreed to accordingly'
  end

  it 'should recognize "Resolved in the negative, and Amendment disagreed to accordingly"' do
    should_be_result 'Resolved in the negative, and Amendment disagreed to accordingly'
  end

  it 'should recognize "Resolution agreed to"' do
    should_be_result 'Resolution agreed to'
  end

  it 'should not recognize "Motion made, and Question put,"' do
    should_be_result 'Motion made, and Question put,', false
  end
end



describe Division, "when calculating an index in the parent section" do 
  
  it 'should set the index to the index of the division in the section' do 
    section = mock_model(Section, :index_of_division => 4)
    placeholder = mock_model(DivisionPlaceholder, :section => section)
    division = Division.new(:division_placeholder => placeholder)
    division.calculate_index_in_section.should == 4
  end
  
end 

describe Division, 'when calculating a section title' do 
  
  it 'should set the section title to be the section title of the division placeholder' do
    placeholder = mock_model(DivisionPlaceholder, :section_title => 'placeholder title')
    division = Division.new
    division.stub!(:division_placeholder).and_return(placeholder)
    division.calculate_section_title.should == 'placeholder title'
  end
  
end

