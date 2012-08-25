require File.dirname(__FILE__) + '/../spec_helper'

describe Bill do 
  
  describe "when asked for name and number" do

    it 'should return "IMMIGRATION APPEALS BILL" for Bill with title "IMMIGRATION APPEALS BILL" and nil number' do
      bill = Bill.new(:name => "IMMIGRATION APPEALS BILL")
      bill.name_and_number.should == "IMMIGRATION APPEALS BILL"
    end

    it 'should return "GAS PROVISIONAL ORDERS BILL NO. 1" for Bill with title "GAS PROVISIONAL ORDERS BILL" and number "1"' do
      bill = Bill.new(:name => "GAS PROVISIONAL ORDERS BILL", :number => "1")
      bill.name_and_number.should == "GAS PROVISIONAL ORDERS BILL No. 1"
    end

  end

  describe 'in general' do
  
    it 'should have id_hash mapping name to slug' do
      bill = Bill.new(:name => "IMMIGRATION APPEALS BILL")
      bill.stub!(:slug).and_return "immigration_appeals_bill"
      bill.id_hash.should == {:name => "immigration_appeals_bill"}
    end
  
  end

  describe "finding all Bills and returning a specified sorted list" do 

    it 'should ask for all Bills sorted by name, then number' do 
      Bill.should_receive(:find).with(:all, :order => "name asc, number asc")
      Bill.find_all_sorted
    end
  
  end

  describe "finding or creating from resolved attributes" do 

    it 'should change the case of an existing match to titlecase if it is uppercase' do
      bill = mock_model(Bill, :name => 'TITLE')
      Bill.stub!(:find_by_name_and_number).and_return(bill)
      bill.should_receive(:name=).with("Title")
      bill.should_receive(:save)
      Bill.find_or_create_from_resolved_attributes(:name => "Title", :year => 1974).should == bill
    end
  
  end
  describe 'when finding by given name and number' do
    it 'should ignore case' do
      Bill.should_receive(:find).with(:first, :conditions => ["LOWER(name) = ? and number = ?", 'title', '2'])
      Bill.find_by_name_and_number("TITLE", "2")
    end
  end

  describe "when finding by given name and number with db" do

    it 'should find bill when number is nil, and there is a single matching bill in db' do
      title = 'Finance Bill'
      bill = Bill.create(:name => title)
      Bill.find_by_name_and_number(title, nil).should == bill
    end

    it 'should not find bill when number is nil, and there is a single bill in db with a number' do
      title = 'Finance Bill'
      bill = Bill.create(:name => title, :number => 3)
      Bill.find_by_name_and_number(title, nil).should == nil
    end

    it 'should find bill when number is nil, and there are many bills with that name in db' do
      title = 'Finance Bill'
      bill = Bill.create(:name => title)
      Bill.create(:name => title, :number => 3)
      Bill.create(:name => title, :number => 5)
      Bill.find_by_name_and_number(title, nil).should == bill
    end
  end

  describe " when populating mentions" do

    before do
      @mentionable_class = Bill
      @contribution = Contribution.new(:text => "test text")
      @section = mock_model(Section, :parent_sections => [],
                                     :linkable? => true,
                                     :sitting => mock_model(Sitting, :date => Date.new(1923, 5, 4)))
      @contribution.stub!(:section).and_return(@section)
      @mock_resolver = mock("resolver", :mention_attributes => [])
      @mock_resolver_class = mock("resolver_class", :new => @mock_resolver)
      Bill.stub!(:resolver).and_return(@mock_resolver_class)
      @mention_class = BillMention
    end

    it_should_behave_like "a mentionable model when populating mentions"

  end

  describe 'when trying to find bill based on a section title' do

    it 'should find it when title is bill without number' do
      text = 'Finance Bill'
      bill = mock_model(Bill)

      BillResolver.should_receive(:determine_name_and_number).with(text).and_return [text, nil]
      Bill.should_receive(:find_by_name_and_number).with(text, nil).and_return bill
      Bill.find_from_text(text).should == bill
    end

    it 'should find it when title is bill followed by "." without number' do
      text = 'Finance Bill'
      bill = mock_model(Bill)

      BillResolver.should_receive(:determine_name_and_number).with(text).and_return [text, nil]
      Bill.should_receive(:find_by_name_and_number).with(text, nil).and_return bill
      Bill.find_from_text(text+'.').should == bill
    end

    it 'should find it when title is bill with number' do
      number = '3'
      name = %Q|Finance Bill|
      text = "#{name} No. #{number}"
      bill = mock_model(Bill)

      BillResolver.should_receive(:determine_name_and_number).with(text).and_return [name, number]
      Bill.should_receive(:find_by_name_and_number).with(name, number).and_return bill
      Bill.find_from_text(text).should == bill
    end

    it 'should not find it when title is not bill' do
      text = "NEW PENSION SCHEME"

      BillResolver.should_receive(:determine_name_and_number).with(text).and_return [nil, nil]
      Bill.should_not_receive(:find_by_name_and_number)
      Bill.find_from_text(text).should == nil
    end

  end

  describe 'when normalizing bill name' do

    def self.it_should_correct_HL bad_hl
      eval %Q|it 'should convert #{bad_hl} to [H.L.]' do
      Bill.normalize_name('FORESTRY BILL #{bad_hl}').should == 'FORESTRY BILL [H.L.]'
    end|
    end

    it_should_correct_HL '(H.L.)'
    it_should_correct_HL '(H.L.]'
    it_should_correct_HL '[.H.L.]'
    it_should_correct_HL '[H L.]'
    it_should_correct_HL '[H. L.]'
    it_should_correct_HL '[H..L]'
    it_should_correct_HL '[HL]'
    it_should_correct_HL '[H.L.'
    it_should_correct_HL '[H.L.)'
    it_should_correct_HL '[H.L.).'
    it_should_correct_HL '[H.L.,]'
    it_should_correct_HL '[H.L.1'
    it_should_correct_HL '[H.L]'
    it_should_correct_HL '[H.L].'
    it_should_correct_HL '[HL.]'
    it_should_correct_HL '[HLL.]'
    it_should_correct_HL '[.H.L.]'
    it_should_correct_HL '[B.L.]'
    it_should_correct_HL '[LL.]'

    it 'should correct "BILL.[H.L.]" to "BILL [H.L.]"' do
      Bill.normalize_name('FORESTRY BILL.[H.L.]').should == 'FORESTRY BILL [H.L.]'
    end

  end

  describe 'when finding others with the same name' do 
  
    it 'should ask for acts with the same name but a different id' do 
      bill = Bill.new(:name => 'test name')
      Bill.should_receive(:find_all_by_name).with('test name', :conditions => ['id != ?', bill.id])
      bill.others_by_name
    end
  
  end

end