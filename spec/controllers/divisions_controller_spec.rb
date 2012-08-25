require File.dirname(__FILE__) + '/../spec_helper'

describe DivisionsController do
  it_should_behave_like "All controllers"

  describe 'when showing index' do

    it "should map { :controller => @controller, :action => 'index', :letter => 'b' } to /@controller/b" do
      params = { :controller => 'divisions', :action => 'index', :letter => 'b'}
      route_for(params).should == "/divisions/b"
    end

    it "should map /divisions to index action" do
      params_from(:get, "/divisions").should == { :controller => 'divisions', :action => 'index' }
    end

    it 'should find all divisions and assign them to view' do
      divisions = [[[mock(Division)]]]
      Division.should_receive(:divisions_in_groups_by_section_title_and_section_and_sub_section).and_return divisions
      get :index
      assigns[:divisions_in_groups_by_section_title_and_section_and_sub_section].should == divisions
    end

    it 'should assign a list of divisions starting with "A" to the view if not passed a letter param' do
      division = mock(Division)
      Division.should_receive(:divisions_in_groups_by_section_title_and_section_and_sub_section).with('a').and_return [ [[division]] ]
      get :index
      assigns[:divisions_in_groups_by_section_title_and_section_and_sub_section].should == [[[division]]]
    end

    it 'should assign a list of divisions starting with a letter to the view if passed a letter param' do
      division = mock(Division)
      Division.should_receive(:divisions_in_groups_by_section_title_and_section_and_sub_section).with('b').and_return [ [[division]] ]
      get :index, :letter => 'b'

      assigns[:divisions_in_groups_by_section_title_and_section_and_sub_section].should == [[[division]]]
    end

  end

  describe 'when showing division' do

    before do
      @params = {
        :controller => 'divisions', :type => 'commons', :action => 'show_division_formatted',
        :year => '2003', :month => 'mar', :day => '05',
        :id => 'abolition-of-capping-powers', :division_number => 'division_103' }
    end

    it 'should respond with a 404 if asked for a division with an invalid format' do
      params = @params.merge({ :format => 'aspx' })
      get :show_division_formatted, params
      response.response_code.should == 404
    end

    it 'should map /commons/2003/mar/05/abolition-of-capping-powers/division_103 to show division action' do
      params = @params.merge({ :format => 'csv' })
      params_from(:get, '/commons/2003/mar/05/abolition-of-capping-powers/division_103.csv').should == params
    end

    it "should map /lords/1922/may/24/allotments-bill-hl/division_2 to show_division action" do
      params = {
        :controller => 'divisions', :type=>"lords", :action => 'show_division',
        :year=>'1922', :month=>'may', :day=>'24',
        :id=>'allotments-bill-hl',  :division_number => 'division_2'}
      params_from(:get, "/lords/1922/may/24/allotments-bill-hl/division_2").should == params
    end

    it 'should create route from ' do
      params = {
        :controller => 'divisions', :type=>"lords", :action => 'show_division',
        :year=>'1922', :month=>'may', :day=>'24',
        :id=>'allotments-bill-hl',  :division_number => 'division_2'}
      csv_params = @controller.params_for_csv_url(params)
      route_for(csv_params).should == '/lords/1922/may/24/allotments-bill-hl/division_2.csv'
    end

    it 'should retrieve division from section' do
      section = mock('section')
      @controller.should_receive(:with_sitting_and_section).and_yield(mock('sitting'), section)

      division_number = 'division_103'
      division_as_text = 'ayes, noes, tellers'
      division = mock('division', :to_csv => division_as_text )
      section.should_receive(:find_division).with(division_number).and_return division

      get :show_division_formatted, :type => 'commons', :action => 'show_division_formatted',
        :year => '2003', :month => 'mar', :day => '05',
        :id => 'abolition-of-capping-powers', :division_number => division_number,
        :format => 'csv'
      assigns[:division].should == division
      response.should have_text(division_as_text)
    end

    it 'should return 404 if division not found in section' do
      section = mock('section')
      @controller.should_receive(:with_sitting_and_section).and_yield(mock('sitting'), section)

      division_number = 'division_103'
      section.should_receive(:find_division).with(division_number).and_return nil

      get :show_division_formatted, :type => 'commons', :action => 'show_division_formatted',
        :year => '2003', :month => 'mar', :day => '05',
        :id => 'abolition-of-capping-powers', :division_number => division_number,
        :format => 'csv'
      response.response_code.should == 404
    end
  end

end
