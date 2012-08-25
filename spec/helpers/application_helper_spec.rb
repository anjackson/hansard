require File.dirname(__FILE__) + '/../spec_helper'
include ApplicationHelper

describe ApplicationHelper do
  
  describe 'when rendering default time feeds' do 
    
    it 'should render feeds for 10, 100 and 200 years ago' do
      result = capture_haml{ default_time_feeds }
      [10, 100, 200].each do |years|
        result.should have_tag("link[href=http://test.host/years-ago/#{years}.xml][rel=alternate][title=#{years} years ago][type=application/atom+xml]")
      end
      expected_feeds = ['<link href="http://test.host/years-ago/10.xml" rel="alternate" title="10 years ago" type="application/atom+xml" />',
                        '<link href="http://test.host/years-ago/100.xml" rel="alternate" title="100 years ago" type="application/atom+xml" />',
                        '<link href="http://test.host/years-ago/200.xml" rel="alternate" title="200 years ago" type="application/atom+xml" />']
      result.should == expected_feeds.join("\n") + "\n"
    end
  
  end

  describe "when formatting page title" do
    it 'should return a string "HANSARD 1803&ndash;2005" when the :home_page param is present' do
      stub!(:params).and_return(:home_page => true)
      format_page_title("test title").should == "HANSARD 1803&ndash;2005"
    end

    it 'should remove line break elements' do
      format_page_title('THE<lb></lb>REGIONS').include?('<lb>').should be_false
      format_page_title('THE<lb></lb>REGIONS').include?('</lb>').should be_false
    end

    it 'should not contain double commas' do
      format_page_title('double commas,, in this title').include?(',,').should be_false
    end

    it 'should replace double commas with a single comma' do
      format_page_title('double commas,, in this title') == 'double commas, in this title'
    end

    it 'should return a string "Section Title (Hansard, 7 November 1902)" for a section with that date' do
      @section = mock_model(Section, :date => Date.new(1902, 11, 7))
      format_page_title("Section Title").should == "Section Title (Hansard, 7 November 1902)"
    end
  end

  describe "when returning office holder details" do
    before do
      @person = mock_model(Person, :name => 'the person')
      @office = mock_model(Office)
      stub!(:office_link).and_return("<a href='http://www.test.host'>the office</a>")
      stub!(:person_url).and_return('http://www.test.host')

      @holder = OfficeHolder.new(:office => @office,
                                 :person => @person,
                                 :start_date => Date.new(1899, 1, 1),
                                 :end_date => Date.new(1901, 2, 21),
                                 :confirmed => true)

    end

    it 'should return text in the form "<a href=\'http://www.test.host\'>the office</a> January  1, 1899 - February 21, 1901" for a confirmed period in office if asked for links to offices' do
      details = office_holder_details(@holder, :link_to => :office)
      details.should == "<a href='http://www.test.host'>the office</a> January  1, 1899 - February 21, 1901"
    end

    it 'should return text in the form "<a href=\'http://www.test.host\'>the office</a> January  1, 1899 - February 21, 1901<sup>*</sup>" for a derived period in office if asked for links to offices' do
      @holder.confirmed = false
      details = office_holder_details(@holder, :link_to => :office)
      details.should == "<a href='http://www.test.host'>the office</a> January  1, 1899 - February 21, 1901<sup>*</sup>"
    end

    it 'should return text in the form "<a href=\'http://www.test.host\'>the person</a> January  1, 1899 - February 21, 1901" for a confirmed period in office if asked for links to people' do
      @holder.confirmed = true
      details = office_holder_details(@holder, :link_to => :person)
      details.should == "<a href=\"http://www.test.host\">the person</a> January  1, 1899 - February 21, 1901"
    end

  end
  
  describe 'when giving title details' do 
  
    it 'should return the name if there is one' do 
      membership = mock_model(LordsMembership, :name => 'Lord Baker of Westminster', 
                                               :start_date => nil, 
                                               :end_date => nil)
      title_details(membership).should == "Lord Baker of Westminster"
    end 
    
    it 'should return the degree and title if there is no name' do 
      membership = mock_model(LordsMembership, :degree => 'Lord', 
                                               :name => '',
                                               :title => 'Baker of Westminster', 
                                               :start_date => nil, 
                                               :end_date => nil)
      title_details(membership).should == 'Lord Baker of Westminster'
    end
    
    it 'should include the start year if the membership has one and asked for dates and the start date is estimated' do 
      membership = mock_model(LordsMembership, :name => 'Lord Baker of Westminster', 
                                               :start_date => Date.new(1994, 1, 1),
                                               :estimated_start_date => true, 
                                               :end_date => nil)
      title_details(membership, {:include_dates => true}).should == 'Lord Baker of Westminster 1994 - '
    end
    
    it 'should include the start date if the membership has one and asked for dates and the start date is not estimated' do 
      membership = mock_model(LordsMembership, :name => 'Lord Baker of Westminster', 
                                               :start_date => Date.new(1994, 1, 1),
                                               :estimated_start_date => false, 
                                               :end_date => nil)
      title_details(membership, {:include_dates => true}).should == 'Lord Baker of Westminster January  1, 1994 - '
    end
    
    it 'should not include the start year if the membership has one and not asked for dates' do 
      membership = mock_model(LordsMembership, :name => 'Lord Baker of Westminster', 
                                               :start_date => Date.new(1994, 1, 1),
                                               :end_date => nil)
      title_details(membership).should == 'Lord Baker of Westminster'
    end
    
  end

  describe 'when creating hcard names for people' do 
  
    it 'should correctly mark up a person called "Mr. Frank Allaun"' do 
      person = Person.new(:firstname => 'Frank', :lastname => 'Allaun', :honorific => 'Mr')
      hcard_person(person).should have_tag('.fn') do
        with_tag('.honorific-prefix', :text => 'Mr')
        with_tag('.given-name', :text => 'Frank')
        with_tag('.family-name', :text => 'Allaun')
      end
    end
    
    it 'should correctly mark up a person called "Marquess of Stafford"' do 
      person = Person.new(:firstname => "", :lastname => "Stafford", :honorific => 'Marquess of')
      hcard_person(person).should have_tag('.fn') do
        with_tag('.title', :text => 'Marquess of')
        with_tag('.given-name', :count => 0)
        with_tag('.family-name', :text => 'Stafford')
      end  
    end
  
  end

  describe  " when displaying a featured speech" do

    it 'should return "September  3, 1998 <a href="http://www.example.com#anchor">Criminal Justice (Terrorism and Conspiracy) Bill Lords</a> Lords" for a speech from the Lords' do 
      stub!(:section_url).and_return("http://www.example.com")
      sitting = HouseOfLordsSitting.new(:date => Date.new(1998, 9, 3))
      section = Section.new(:sitting => sitting, :title => "Criminal Justice (Terrorism and Conspiracy) Bill Lords")
      contribution = Contribution.new(:section => section, :anchor_id => 'anchor')
      featured_speech(contribution).should == 'September  3, 1998 <a href="http://www.example.com#anchor">Criminal Justice (Terrorism and Conspiracy) Bill Lords</a> Lords'
    end

  end

  describe "when returning a display date for a sitting" do
    it "should return a date in the format 'Sunday, December 16, 1895'" do
      sitting = Sitting.new(:date => Date.new(1895, 12, 16))
      sitting_display_date(sitting).should == 'Sunday, December 16, 1895'
    end
  end

  describe "when creating navigation links" do
    before do
      @sitting = mock_model(Sitting)
      @date = Date.new(1886,3,3)
      @sitting.stub!(:date).and_return(@date)
    end

    it "should include an 'a' tag containing the text 'Previous sitting day' if there is a previous sitting day" do
      Sitting.stub!(:find_next)
      Sitting.should_receive(:find_next).with(@date, '<').and_return(@sitting)
      result = capture_haml{ day_navigation(Sitting, @date) }
      result.should have_tag('a[href=/sittings/1886/mar/03]', :text => 'March  3, 1886')
    end

    it "should not include an 'a' tag containing the text 'Previous sitting day' if there is not a previous sitting day" do
      Sitting.stub!(:find_next)
      Sitting.should_receive(:find_next).with(@date, '>').and_return(nil)
      result = capture_haml{ day_navigation(Sitting, @date) }
      result.should_not have_tag('a[href=/sittings/1886/mar/03]', :text => 'March  3, 1886')
    end

    it "should include an 'a' tag containing the text 'Next sitting day' if there is a next sitting day" do
      Sitting.stub!(:find_next)
      Sitting.should_receive(:find_next).with(@date, '>').and_return(@sitting)
      result = capture_haml{ day_navigation(Sitting, @date) }
      result.should have_tag('a[href=/sittings/1886/mar/03]', :text => 'March  3, 1886')
    end

    it "should not include an 'a' tag containing the text 'Next sitting day' if there is not a next sitting day" do
      Sitting.stub!(:find_next)
      Sitting.should_receive(:find_next).with(@date, '>').and_return(nil)
      result = capture_haml{ day_navigation(Sitting, @date) }
      result.should_not have_tag('a[href=/sittings/1886/mar/03]', :text => 'March  3, 1886')
    end
  end

  describe "when formatting plain text as an html list" do
    it "should replace a newline-delimited piece of text with an html unordered list" do
      html_list("line\nother line").should == "<ul><li>line</li><li>other line</li></ul>"
    end
  end

  describe "when creating a url for a date" do
    it 'should return "sittings" for {:century => nil}' do
      date_params = {:century => nil}
      on_date_url(date_params).should == "/sittings"
    end

    it 'should return "sittings" for {:decade => nil}' do
      date_params = {:decade => nil}
      on_date_url(date_params).should == "/sittings"
    end

    it 'should return "sittings" for {:year => nil}' do
      date_params = {:year => nil}
      on_date_url(date_params).should == "/sittings"
    end

    it 'should return "sittings" for no date_params' do
      date_params = {}
      on_date_url(date_params).should == "/sittings"
    end

    it 'should return "sittings/1807/dec/11" for {:year => 1807, :month => "dec", :day => 11}' do
      date_params = {:year => 1807, :month => "dec", :day => 11}
      on_date_url(date_params).should == "/sittings/1807/dec/11"
    end

    it 'should return "sittings/1807/dec" for {:year => 1807, :month => "dec"}' do
      date_params = {:year => 1807, :month => "dec"}
      on_date_url(date_params).should == "/sittings/1807/dec"
    end

    it 'should return "sittings/1807" for {:year => 1807}' do
      date_params = {:year => 1807}
      on_date_url(date_params).should == "/sittings/1807"
    end

    it 'should return "commons/1807" for {:sitting_type => HouseOfCommonsSitting, :year => 1807}' do
      date_params = {:year => 1807, :sitting_type => HouseOfCommonsSitting}
      on_date_url(date_params).should == "/commons/1807"
    end

    it 'should return sittings/1800s for {:decade => "1800s"}' do
      date_params = {:decade => '1800s'}
      on_date_url(date_params).should == "/sittings/1800s"
    end

    it 'should return sittings/C19 for {:century => "C19"}' do
      date_params = {:century => 'C19'}
      on_date_url(date_params).should == "/sittings/C19"
    end

    it 'should create a url "/sittings/1807/dec/11" when asked to create a url for the date 11 Dec 1807' do
      url_for_date(Date.new(1807,12,11)).should == "/sittings/1807/dec/11"
    end
  end

  describe "when creating resource breadcrumbs navigation" do

    def call_resource_breadcrumbs resource_name_method = nil
      capture_haml{ resource_breadcrumbs(@resource, resource_name_method) }
    end

    it "should have a link to the resource's root index url" do
      @resource = mock_model(Bill, :name => 'Finance Bill')
      assigns[:bill] = @resource
      call_resource_breadcrumbs.should have_tag("a.bills[href=http://test.host/bills/f]", :text => 'Bills (F)')
    end
    
    it 'should have a link to the resource root index url generated using a custom name method if one is passed to it' do
      @resource = mock_model(Person, :lastname => 'Jeter')
      call_resource_breadcrumbs(:lastname).should have_tag("a.people[href=http://test.host/people/j]", :text => 'People (J)')
    end
    
    it 'should not raise an error when passed an office with name ".JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE FOR THE HOME DEPARTMENT"' do 
      @resource = mock_model(Office, :name => ".JOINT PARLIAMENTARY UNDER-SECRETARY OF STATE FOR THE HOME DEPARTMENT")
      lambda{ call_resource_breadcrumbs }.should_not raise_error
    end
     
  end

  describe 'when creating an index link' do 
    
    before do 
      @bill = mock_model(Bill, :name => 'Finance Bill')
    end
    
    def call_index_link model, name_method, text, anchor=nil
      capture_haml{ index_link(model, name_method, text, anchor) }
    end
    
    it 'should return a link with the text given to it if text is given' do 
      call_index_link(@bill, nil, "My text").should have_tag('a', :text => 'My text')
    end
    
    it 'should return a link to a named anchor if an anchor name is given' do 
    call_index_link(@bill, nil, "My text", "My anchor").should have_tag('a[href=http://test.host/bills/f#My anchor]')
    end
    
  end

  describe "when creating sitting breadcrumbs navigation" do
    before do
      @sitting = mock_model(Sitting)
      @sitting.stub!(:title).and_return("sitting title")
      @date = Date.new(1928, 2, 11)
      assigns[:sitting] = @sitting
    end

    def call_sitting_breadcrumbs
      capture_haml{ sitting_breadcrumbs(Sitting, @date) }
    end

    it "should have a link to the sitting's decade" do
      call_sitting_breadcrumbs.should have_tag("a.sitting-decade[href=/sittings/1920s]", :text => '1920s')
    end

    it "should have a link to the sitting's year" do
      call_sitting_breadcrumbs.should have_tag("a.sitting-year[href=/sittings/1928]", :text => '1928')
    end

    it "should have a link to the sitting's month" do
      call_sitting_breadcrumbs.should have_tag("a.sitting-month[href=/sittings/1928/feb]", :text => 'February 1928')
    end

    it "should have a link to the sitting's day" do
      call_sitting_breadcrumbs.should have_tag("a.sitting-day[href=/sittings/1928/feb/11]", :text => '11 February 1928')
    end
  end

  describe "when getting date information about a sitting" do
    it 'should return [nil, nil] for a sitting without a volume' do
      sitting = mock_model(Sitting, :month => 6,
                                    :year => 1992,
                                    :day => 1,
                                    :volume => nil)
      get_years_and_yymmdd(sitting).should == [nil, nil]
    end

    it 'should return [nil, nil] for a sitting in a volume with no session_start_year and session_end_year' do
      volume = mock_model(Volume, :session_start_year => nil, :session_end_year => nil)
      sitting = mock_model(Sitting, :month => 6,
                                    :year => 1992,
                                    :day => 1,
                                    :volume => volume)
      get_years_and_yymmdd(sitting).should == [nil, nil]
    end


    it 'should return ["199192", "920601"] for a sitting from a volume with session_start_year 1991, session_end_year 1992 and sitting date 1992-06-01' do
      volume = mock_model(Volume, :session_start_year => 1991,
                                  :session_end_year => 1992)
      sitting = mock_model(Sitting, :month => 6,
                                    :year => 1992,
                                    :day => 1,
                                    :volume => volume)
      get_years_and_yymmdd(sitting).should == ["199192", "920601"]
    end

    it 'should return ["199293", "921101"] for a sitting from a volume with session_start_year 1992, session_end_year 1993 and sitting date 1992-11-01' do
      volume = mock_model(Volume, :session_start_year => 1992,
                                  :session_end_year => 1993)
      sitting = mock_model(Sitting, :month => 11,
                                    :year => 1992,
                                    :day => 1,
                                    :volume => volume)
      get_years_and_yymmdd(sitting).should == ["199293", "921101"]
    end
  end

  describe "when linking to a Lords sitting at parliament.uk" do
    it 'should return a http://www.publications.parliament.uk URL if passed a sitting on the date 1995-11-15' do
      volume = mock_model(Volume, :session_start_year => 1995, :session_end_year => 1996)
      sitting = mock_model(Sitting, :date => Date.new(1995, 11, 15),
                                    :volume => volume,
                                    :year => 1995,
                                    :month => 11,
                                    :day => 15)
      expected = "http://www.publications.parliament.uk/pa/ld199596/ldhansrd/vo951115/index/51115-x.htm#test_anchor"
      link_to_lords_at_parliament_uk(sitting, "#test_anchor").should == expected
    end

    it 'should return nil if passed the date 1985-11-15' do
      volume = mock_model(Volume, :session_start_year => 1985, :session_end_year => 1986)
      sitting = mock_model(Sitting, :date => Date.new(1985, 11, 15),
                                    :volume => volume,
                                    :year => 1985,
                                    :month => 11,
                                    :day => 15)
      link_to_lords_at_parliament_uk(sitting, "#test_anchor").should be_nil
    end

    it 'should return nil if the session start year and end year for the sitting volume are nil' do
      volume = mock_model(Volume, :session_start_year => nil, :session_end_year => nil)
      sitting = mock_model(Sitting, :date => Date.new(1995, 11, 15),
                                     :volume => volume,
                                     :year => 1995,
                                     :month => 11,
                                     :day => 15)
      link_to_lords_at_parliament_uk(sitting, "#test_anchor").should be_nil
    end
  end

  describe "when linking to a Commons sitting at parliament.uk" do
    describe 'with a sitting dated after 1995-11-08' do
      it 'should return a http://www.publications.parliament.uk URL' do
        volume = mock_model(Volume, :session_start_year => 1995, :session_end_year => 1996)
        sitting = mock_model(Sitting, :date => Date.new(1995, 11, 10),
                                      :volume => volume,
                                      :year => 1995,
                                      :month => 11,
                                      :day => 10)
        expected = "http://www.publications.parliament.uk/pa/cm199596/cmhansrd/vo951110/debindx/51110-x.htm"
        link_to_commons_at_parliament_uk(sitting,'debindx', nil).should == expected
      end
    end

    describe 'with a sitting dated between 1995-11-08 and 1988-11-22' do
      it 'should return a earlier version http://www.publications.parliament.uk URL' do
        volume = mock_model(Volume, :session_start_year => 1994, :session_end_year => 1995)
        sitting = mock_model(Sitting, :date => Date.new(1994, 11, 10),
                                      :volume => volume,
                                      :year => 1994,
                                      :month => 11,
                                      :day => 10, :debates => nil)
        expected = "http://www.publications.parliament.uk/pa/cm199495/cmhansrd/1994-11-10/Debate-1.html"
        link_to_commons_at_parliament_uk(sitting,'debindx', 'Debate').should == expected
      end
    end

    describe 'with a sitting dated prior to 1988-11-22' do
      it 'should return nil' do
        volume = mock_model(Volume, :session_start_year => 1985, :session_end_year => 1986)
        sitting = mock_model(Sitting, :date => Date.new(1985, 11, 8),
                                      :volume => volume,
                                      :year => 1985,
                                      :month => 11,
                                      :day => 8)
        link_to_commons_at_parliament_uk(sitting,'debindx', nil).should be_nil
      end
    end

    describe 'with a sitting in session that is missing start and end dates' do
      it 'should return nil' do
        volume = mock_model(Volume, :session_start_year => nil, :session_end_year => nil)
        sitting = mock_model(Sitting, :date => Date.new(1995, 11, 10),
                                      :volume => volume,
                                      :year => 1995,
                                      :month => 11,
                                      :day => 10)
        link_to_commons_at_parliament_uk(sitting, 'debindx', nil).should be_nil
      end
    end
  end

  describe "when linking to a sitting at parliament.uk" do
    it 'should return a link to a Lords sitting when called with a sitting of type "HouseOfLordsSitting"' do
      sitting = mock_model(HouseOfLordsSitting)
      should_receive(:link_to_lords_at_parliament_uk).with(sitting, '')
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Lords sitting when called with a sitting of type "LordsWrittenAnswersSitting"' do
      sitting = mock_model(LordsWrittenAnswersSitting)
      should_receive(:link_to_lords_at_parliament_uk).with(sitting, '#start_written')
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Lords sitting when called with a sitting of type "LordsWrittenStatementsSitting"' do
      sitting = mock_model(LordsWrittenStatementsSitting)
      should_receive(:link_to_lords_at_parliament_uk).with(sitting, '#start_minist')
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Commons sitting when called with a sitting of type "HouseOfCommonSitting"' do
      sitting = mock_model(HouseOfCommonsSitting)
      should_receive(:link_to_commons_at_parliament_uk).with(sitting, 'debindx', 'Debate')
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Commons sitting when called with a sitting of type "CommonsWrittenAnswersSitting"' do
      sitting = mock_model(CommonsWrittenAnswersSitting)
      should_receive(:link_to_commons_at_parliament_uk).with(sitting, 'index', 'Writtens')
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Commons sitting when called with a sitting of type "CommonsWrittenStatementsSitting"' do
      sitting = mock_model(CommonsWrittenStatementsSitting)
      should_receive(:link_to_commons_at_parliament_uk).with(sitting, 'wmsindx', nil)
      link_to_parliament_uk(sitting)
    end

    it 'should return a link to a Commons sitting when called with a sitting of type "WestminsterHallSitting"' do
      sitting = mock_model(WestminsterHallSitting)
      should_receive(:link_to_commons_at_parliament_uk).with(sitting, 'hallindx', nil)
      link_to_parliament_uk(sitting)
    end

    it 'should return a '' when called with a sitting of type "HouseOfLordsReport"' do
      sitting = mock_model(HouseOfLordsReport)
      link_to_parliament_uk(sitting).should == ''
    end
  end

  describe "when linking to a sitting anchor" do
    it 'should return an anchor' do
      sitting = Sitting.new
      sitting.should_receive(:anchor).and_return 'anchor'
      link_to_sitting_anchor(sitting).should == '<a href="#anchor">Sitting</a>'
    end
  end
  
  describe 'when generating a body class' do

    it 'should generate a body class of "house-of-commons-sitting" when given a sitting type of HouseOfCommonsSitting' do
      body_class(HouseOfCommonsSitting).should == 'house-of-commons-sitting'
    end
    
    it 'should generate a body class of "westminster-hall-sitting" when given a sitting type of WestminsterHallSitting' do
      body_class(WestminsterHallSitting).should == 'westminster-hall-sitting'
    end
    
    it 'should generate a body class of "commons-written-answers-sitting" when given a sitting type of CommonsWrittenAnswersSitting' do
      body_class(CommonsWrittenAnswersSitting).should == 'commons-written-answers-sitting'
    end
    
    it 'should generate a body class of "commons-written-statements-sitting" when given a sitting type of CommonsWrittenStatementsSitting' do
      body_class(CommonsWrittenStatementsSitting).should == 'commons-written-statements-sitting'
    end
    
    it 'should generate a body class of "house-of-lords-sitting" when given a sitting type of HouseOfLordsSitting' do
      body_class(HouseOfLordsSitting).should == 'house-of-lords-sitting'
    end
    
    it 'should generate a body class of "grand-committee-report-sitting" when given a sitting type of GrandCommitteeReportSitting' do
      body_class(GrandCommitteeReportSitting).should == 'grand-committee-report-sitting'
    end
    
    it 'should generate a body class of "lords-written-answers-sitting" when given a sitting type of LordsWrittenAnswersSitting' do
      body_class(LordsWrittenAnswersSitting).should == 'lords-written-answers-sitting'
    end
    
    it 'should generate a body class of "lords-written-statements-sitting" when given a sitting type of LordsWrittenStatementsSitting' do
      body_class(LordsWrittenStatementsSitting).should == 'lords-written-statements-sitting'
    end
    
    it 'should generate a body class of "house-of-lords-report" when given a sitting type of HouseOfLordsReport' do
      body_class(HouseOfLordsReport).should == 'house-of-lords-report'
    end
    
    it 'should generate a body class of "page" when given a sitting type of NilClass' do
      body_class(NilClass).should == 'page'
    end
    
    it 'should generate a body class of "page" when given a sitting type of TrueClass' do
      body_class(TrueClass).should == 'page'
    end
    
  end
  
  describe 'when generating a sitting keyword text' do

    it 'should generate a sitting keyword text of ", House of Commons sitting" when given a sitting type of HouseOfCommonsSitting' do
      sitting_keyword_with_comma(HouseOfCommonsSitting).should == ', House of Commons sitting'
    end
    
    it 'should generate a sitting keyword text of ", Westminster Hall sitting" when given a sitting type of WestminsterHallSitting' do
      sitting_keyword_with_comma(WestminsterHallSitting).should == ', Westminster Hall sitting'
    end
    
    it 'should generate a sitting keyword text of ", Commons Written Answers sitting" when given a sitting type of CommonsWrittenAnswersSitting' do
      sitting_keyword_with_comma(CommonsWrittenAnswersSitting).should == ', Commons Written Answers sitting'
    end
    
    it 'should generate a sitting keyword text of ", Commons Written Statements sitting" when given a sitting type of CommonsWrittenStatementsSitting' do
      sitting_keyword_with_comma(CommonsWrittenStatementsSitting).should == ', Commons Written Statements sitting'
    end
    
    it 'should generate a sitting keyword text of ", House of Lords sitting" when given a sitting type of HouseOfLordsSitting' do
      sitting_keyword_with_comma(HouseOfLordsSitting).should == ', House of Lords sitting'
    end
    
    it 'should generate a sitting keyword text of ", Grand Committee Report sitting" when given a sitting type of GrandCommitteeReportSitting' do
      sitting_keyword_with_comma(GrandCommitteeReportSitting).should == ', Grand Committee Report sitting'
    end
    
    it 'should generate a sitting keyword text of ", Lords Written Answers sitting" when given a sitting type of LordsWrittenAnswersSitting' do
      sitting_keyword_with_comma(LordsWrittenAnswersSitting).should == ', Lords Written Answers sitting'
    end
    
    it 'should generate a sitting keyword text of ", Lords Written Statements sitting" when given a sitting type of LordsWrittenStatementsSitting' do
      sitting_keyword_with_comma(LordsWrittenStatementsSitting).should == ', Lords Written Statements sitting'
    end
    
    it 'should generate a sitting keyword text of ", House of Lords Report" when given a sitting type of HouseOfLordsReport' do
      sitting_keyword_with_comma(HouseOfLordsReport).should == ', House of Lords Report'
    end
    
    it 'should generate a sitting keyword text of "" when given a sitting type of NilClass' do
      sitting_keyword_with_comma(NilClass).should == ''
    end
    
    it 'should generate a sitting keyword text of "" when given a sitting type of TrueClass' do
      sitting_keyword_with_comma(TrueClass).should == ''
    end
    
  end

  describe "when giving the title for a date at a resolution" do
    before(:all) do
      @date = Date.new(1928, 6, 1)
    end

    def expect_title(sitting_type, resolution, title)
      resolution_title(sitting_type, @date, resolution).should == "#{title}"
    end

    it 'should return "Sittings in the 20th century" given the date June 1 1928 and the resolution nil' do
      expect_title(Sitting, nil, "Sittings in the 20th century")
    end

    it 'should return "Sittings in the 1920s" given the date June 1 1928 and the resolution :decade' do
      expect_title(Sitting, :decade, "Sittings in the 1920s")
    end

    it 'should return "Sittings in 1928" given the date June 1 1928 and the resolution :year' do
      expect_title(Sitting, :year, "Sittings in 1928")
    end

    it 'should return "Sittings in June 1928" given the date June 1 1928 and the resolution :month' do
      expect_title(Sitting, :month, "Sittings in June 1928")
    end

    it 'should return "Sitting of 1 June 1928" given the date June 1 1928 and the resolution :day' do
      expect_title(Sitting, :day, "Sitting of 1 June 1928")
    end

    it 'should return "Commons Sittings in the 20th century" given the date June 1 1928, the sitting type HouseOfCommonsSitting and the resolution nil' do
      expect_title(HouseOfCommonsSitting, nil, "Commons Sittings in the 20th century")
    end

    it 'should return "Commons Sittings in the 1920s" given the date June 1 1928 the sitting type HouseOfCommonsSitting and the resolution :decade' do
      expect_title(HouseOfCommonsSitting, :decade, "Commons Sittings in the 1920s")
    end

    it 'should return "Commons Sittings in 1928" given the date June 1 1928 the sitting type HouseOfCommonsSitting and the resolution :year' do
      expect_title(HouseOfCommonsSitting, :year, "Commons Sittings in 1928")
    end

    it 'should return "Commons Sittings in June 1928" given the date June 1 1928 the sitting type HouseOfCommonsSitting and the resolution :month' do
      expect_title(HouseOfCommonsSitting, :month, "Commons Sittings in June 1928")
    end

    it 'should return "Commons Sitting of 1 June 1928" given the date June 1 1928 the sitting type HouseOfCommonsSitting and the resolution :day' do
      expect_title(HouseOfCommonsSitting, :day, "Commons Sitting of 1 June 1928")
    end

    it 'should return "Written Answers (Lords) of 1 June 1928" given the date June 1 1928 the sitting type LordsWrittenAnswersSitting and the resolution :day' do
      expect_title(LordsWrittenAnswersSitting, :day, "Written Answers (Lords) of 1 June 1928")
    end

    it 'should return "Written Statements (Commons) of 1 June 1928" given the date June 1 1928 the sitting type CommonsWrittenStatementsSitting and the resolution :day' do
      expect_title(CommonsWrittenStatementsSitting, :day, "Written Statements (Commons) of 1 June 1928")
    end

    it 'should return "Written Statements (Lords) of 1 June 1928" given the date June 1 1928 the sitting type LordsWrittenStatementsSitting and the resolution :day' do
      expect_title(LordsWrittenStatementsSitting, :day, "Written Statements (Lords) of 1 June 1928")
    end

    it 'should return "Lords Report of 1 June 1928" given the date June 1 1928 the sitting type LordsReport and the resolution :day' do
      expect_title(HouseOfLordsReport, :day, "Lords Report of 1 June 1928")
    end
  end

  describe 'when getting an options hash for the timeline' do
    it 'should return a hash specifying that :first_of_month is false' do
      timeline_options(nil, Sitting)[:first_of_month].should == false
      timeline_options(:decade, Sitting)[:first_of_month].should == false
      timeline_options(:year, Sitting)[:first_of_month].should == false
    end

    it 'should return a hash including the sitting type if one is passed to it' do
      timeline_options(nil, HouseOfCommonsSitting)[:sitting_type].should == HouseOfCommonsSitting
    end

    it 'should return a hash setting navigation to true' do
      timeline_options(:decade, Sitting)[:navigation].should be_true
    end
  end

  describe "when creating links to constituencies" do
    it 'should return "<a href="/constituencies/inverness" title="Inverness">(Inverness)</a>", when passed the text "(Inverness)" and the Inverness constituency' do
      constituency = Constituency.new :name => "Inverness", :slug => "inverness"
      link_to_constituency(constituency, "(Inverness)").should have_tag('a[href=http://test.host/constituencies/inverness][title=Inverness]', :text => "(Inverness)")
    end
  end

  describe 'when asked for a contribution permalink' do 
    
    before do 
      @contribution = mock_model(Contribution, :anchor_id => 'test anchor')
    end
    
    it 'should return an empty string if asked to hide markers' do 
      contribution_permalink(@contribution, :hide_markers => true).should == ''
    end
    
    it 'should return a link to the contribution anchor with class permalink and title "Link to this contribution" if not asked to hide markers' do 
      expected_tag = 'a.permalink[title=Link to this contribution][href=#test anchor]'
      contribution_permalink(@contribution, marker_options={}).should have_tag(expected_tag)
    end
    
  end
  
  describe 'when asked for a speech permalink' do
    
    before do 
      @contribution = mock_model(Contribution, :anchor_id => 'test anchor')
    end
    
    it 'should return an empty string if asked to hide markers' do 
      speech_permalink(@contribution, :hide_markers => true).should == ''
    end
    
    it 'should return a link to the contribution anchor with classes permalink and speech-permalink and title like "Link to this speech by Bob Member"' do 
      @contribution.stub!(:person).and_return(mock_model(Person, :name => 'Bob Member'))
      expected_tag = 'a.permalink.speech-permalink[title=Link to this speech by Bob Member][href=#test anchor]'
      speech_permalink(@contribution, marker_options={}).should have_tag(expected_tag)
    end
    
  end

  describe 'when formatting dates for a model with possibly unknown dates' do
    it 'should return text in the form "December 14, 1918 - May 30, 1929" for a model with start and end date' do
      model = mock('model', :start_date => Date.new(1918, 12, 14),
                            :end_date   => Date.new(1929, 5, 30))
      dates_or_unknown(model).should == "December 14, 1918 - May 30, 1929"
    end

    it 'should return text in the form "December 14, 1918 - ?" for a model without an end date' do
      model = mock('model', :start_date => Date.new(1918, 12, 14),
                            :end_date   => nil)
      dates_or_unknown(model).should == "December 14, 1918 - ?"
    end

    it 'should return text in the form "? - May 30, 1929" for a model without a start date' do
      model = mock('model', :start_date => nil,
                            :end_date   => Date.new(1929, 5, 30))
      dates_or_unknown(model).should == "? - May 30, 1929"
    end

    it 'should return text in the form "1918 - May 30, 1929" for a model with an estimated start date' do
      model = mock('model', :start_date => Date.new(1918, 12, 14),
                            :estimated_start_date? => true,
                            :end_date   => Date.new(1929, 5, 30))
      dates_or_unknown(model).should == "1918 - May 30, 1929"
    end

    it 'should return text in the form "December 14, 1918 - 1929" for a model with an estimated end date' do
      model = mock('model', :start_date => Date.new(1918, 12, 14),
                            :estimated_end_date? => true,
                            :end_date   => Date.new(1929, 5, 30))
      dates_or_unknown(model).should == "December 14, 1918 - 1929"
    end
  end

  describe 'when returning commons membership details' do
    before do
      @person = mock_model(Person, :name => 'Bob Member')
      stub!(:person_url).and_return("http://test.host/people/bob-member")
      stub!(:constituency_url).and_return("http://test.host/constituencies/manchesterford")
      stub!(:dates_or_unknown).and_return('formatted dates')
    end

    it 'should return text in the form "Bob Member formatted dates" for a membership ' do
      membership = mock_model(CommonsMembership, :person     => @person)
      commons_membership_details(membership).should == "<a href=\"http://test.host/people/bob-member\">Bob Member</a> formatted dates"
    end

    it 'should return text in the form "Manchesterford formatted dates" if asked to display constituency' do
      constituency = mock_model(Constituency, :name => 'Manchesterford')
      membership = mock_model(CommonsMembership, :constituency => constituency)
      commons_membership_details(membership, model=:constituency).should == "<a href=\"http://test.host/constituencies/manchesterford\">Manchesterford</a> formatted dates"
    end
  end

  describe "when making links to section contributions" do
    before do
      @section = Section.new
      @section.stub!(:title).and_return('section title')
      @contribution = Contribution.new(:section => @section)
      @contribution.stub!(:title_via_associations).and_return("a title")
      stub!(:section_url).and_return("http://www.test.url")
    end

    it 'should return "<a href=\"http://www.test.url\">section title</a>" when calling link_to_section with a section' do
      link_to_section(@section).should == '<a href="http://www.test.url">section title</a>'
    end

    it 'should ask for the contribution title via associations if there is a contribution' do
      @contribution.should_receive(:title_via_associations).and_return("a title")
      section_contribution_link(@contribution, @section)
    end
    
    it 'should return a link whose text is the section title if there is no contribution' do 
      section_contribution_link(nil, @section).should have_tag('a', :text => 'section title')
    end

    it 'should link to the section the contribution belongs to' do
      should_receive(:section_url).with(@section).and_return("http://www.test.url")
      section_contribution_link(@contribution, @section)
    end

    it 'should provide an anchor to the anchor_id of the contribution ' do
      @contribution.should_receive(:anchor_id).and_return("my_anchor_id")
      section_contribution_link(@contribution, @section).should have_tag("a[href=http://www.test.url#my_anchor_id]")
    end
  end

  describe "when returning the date-based urls" do
    it "should return a url in the format /commons/1985/dec/06 for a house of commons sitting" do
      sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 6))
      sitting_date_url(sitting).should == '/commons/1985/dec/06'
    end

    it "should return a url in the format /commons/1985/dec/06.xml for a sitting in xml" do
      sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 6))
      sitting_date_xml_url(sitting).should == '/commons/1985/dec/06.xml'
    end
  end

  describe "when returning links" do
    it "should return a link for a House of Commons sitting whose text is of the form 'Monday, December 16, 1985'" do
      sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 16))
      sitting_link(sitting).should have_tag("a", :text => "Monday, December 16, 1985")
    end
    
    it "should return a link for a House of Commons sitting whose text is of the form 'My Title &ndash; Monday, December 16, 1985' when given a title of 'My title'" do
      sitting = HouseOfCommonsSitting.new(:date => Date.new(1985, 12, 16))
      sitting.title = "My title"
      sitting_link(sitting).should have_tag("a", :text => "My Title &ndash; Monday, December 16, 1985")
    end
    
  end

  describe "when creating alphabetical links" do
    def get_links(models, current_letter=nil, field=:name)
      stub!(:test_models_url).and_return("http://test.host/tests")
      text = ''
      alphabet_links(models, :test_models_url, current_letter, field) do |letter|
        text += letter
      end
      text
    end

    it 'should yield a link to the model url with the letter filter if the model list has models whose name start with that letter' do
      models = [mock('model', :name => "Elephant")]
      should_receive(:test_models_url).with(:letter => "e").and_return('http://test.host/tests?letter=e')

      get_links(models).should have_tag(".letter-nav a[href=http://test.host/tests?letter=e]", :text => "E")
    end

    it 'should yield the letter with no link if the model list doesn\'t have models whose name starts with the letter' do
      models = [mock('model', :name => "Lion")]
      get_links(models).should have_tag(".letter-nav", :text => "E")
    end

    it 'should yield the letter in a "strong" tag if the letter is the current letter being displayed' do
      models = [mock('model', :name => "Lion")]
      get_links(models, 'e').should have_tag(".letter-nav .selected-letter", :text => "E")
    end

    it 'should accept an optional field parameter and yield a link to the model url with the letter filter if the model\'s value for the field starts with that letter' do
      models = [mock('model', :special_name => "Elephant")]
      should_receive(:test_models_url).with(:letter => "e").and_return('http://test.host/tests?letter=e')
      get_links(models, nil, :special_name).should have_tag(".letter-nav a[href=http://test.host/tests?letter=e]", :text => "E")
    end
  
  end

  describe 'when formatting total count of a model' do
    it 'should show formatted count' do
      model_type = mock_model(Act, :count => 1000, :name=>'Act')
      total_count(model_type).should == '1,000 acts in total'
    end
  end

  describe 'when asked for a preview' do
    it 'should return 75 chars of member and contribution text' do
      contribution = mock('contribution', :member_name=>'member', :text=>'<p>1234567891123456789212345678931234567894123456789512345678961234567897</p>')
      contribution2 = mock('contribution')
      contribution2.should_not_receive(:member_name)
      contribution2.should_not_receive(:text)
      section = mock('section', :contributions => [contribution, contribution2])
      preview(section).should == 'member 12345678911234567892123456789312345678941234567895123456789612345...'
    end
  end
  
  describe "when marking up official report references" do
    before do
      @contribution = mock_model(Contribution, :text => '', :mentions => [])
    end

    it 'should link a reference like "OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338." to that column, if it is unambiguous' do
      section = mock_model(Section)
      hansard_reference = mock_model(HansardReference,
                                    :find_sections => [section],
                                    :column => "20" )
      HansardReference.stub!(:new).and_return(hansard_reference)
      stub!(:column_url).with("20", section).and_return("http://www.example.com")
      markup_official_report_references(@contribution, "OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338.").should == '<a href="http://www.example.com">OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338.</a>'
    end

    it 'should not link a reference like "OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338." to that column, if it is ambiguous' do
      section = mock_model(Section)
      hansard_reference = mock_model(HansardReference,
                                    :find_sections => [section, section],
                                    :column => "20" )
      HansardReference.stub!(:new).and_return(hansard_reference)
      markup_official_report_references(@contribution, "OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338.").should == 'OFFICIAL REPORT, 4th July, 1938; col. 26, Vol. 338.'
    end

    it 'should create a date for an ambiguously dated reference using the year of the contribution' do
      @contribution.stub!(:year).and_return(1812)
      params = { :test_params => true, :month => 4, :day => 30 }
      resolver = mock_model(ReportReferenceResolver, :null_object => true, :reference_params => params)
      hansard_reference = mock_model(HansardReference, :find_sections => [])
      ReportReferenceResolver.stub!(:new).and_return(resolver)
      resolver.stub!(:markup_references).and_yield("reference")
      HansardReference.should_receive(:new).with({:date => Date.new(1812, 4, 30), :test_params => true}).and_return(hansard_reference)
      markup_official_report_references(@contribution, 'text')
    end
    
    it 'should not link a reference if there is an error in creating the reference params' do 
      resolver = mock_model(ReportReferenceResolver, :null_object => true)
      ReportReferenceResolver.stub!(:new).and_return(resolver)
      resolver.stub!(:markup_references).and_yield("reference")
      resolver.stub!(:reference_params).and_raise(ArgumentError)
      markup_official_report_references(@contribution, 'text')
    end

    it 'should not link a reference if the params extracted from it are empty' do
      bad_date_reference = '<span class="italic">Official Report,</span> 29 February 1986; Vol. 92, c. 506.'
      markup_official_report_references(@contribution, bad_date_reference).should == bad_date_reference
    end
  end
  
  describe 'when asked for a search form' do 
    
    it 'should escape the query string passed' do 
       form = capture_haml{ haml_search('form-id', 'f', "I don't know"){}}
       form.should have_tag('input[value=I don&apos;t know]')
    end
  
  end
  
  describe 'when asked for a timeline search form' do 
  
    it 'should include a century field when the params include a century param' do 
      form = capture_haml{ timeline_search_form(:century => 'C21') }
      form.should have_tag('input[type=hidden][name=century][value=C21]')
    end
    
    it 'should include a decade field when the params include a decade param' do 
      form = capture_haml{ timeline_search_form(:decade => '1970s') }
      form.should have_tag('input[type=hidden][name=decade][value=1970s]')
    end 
    
    it 'should include a year field when the params include a year param' do 
      form = capture_haml{ timeline_search_form(:year => '1974') }
      form.should have_tag('input[type=hidden][name=year][value=1974]')
    end
    
    it 'should include a year and month field when the params include a month param' do 
      form = capture_haml{ timeline_search_form(:month => 'oct', :year => '1974') }
      form.should have_tag('input[type=hidden][name=month][value=1974-10]')
    end           
  
    it 'should have a timeline-search-form id' do 
      form = capture_haml{ timeline_search_form(:month => 'oct', :year => '1974') }
      form.should have_tag('input[type=search][name=query][id=timeline-search-query]')
    end
  
  end
  
  describe "when returning column markers" do
    
    before do
      Sitting.stub!(:normalized_column).and_return("24B")
      @sitting = mock_model(Sitting, :null_object => true)
      @section = mock_model(Section, :markers => nil)
    end
    
    it "should return an 'a' tag with class 'permalink' containing the normalized column number for a column marker" do
      column_marker("24", @sitting).should have_tag("a.permalink", :text => "24B", :count => 1)
    end

    it "should return an 'a' tag with class 'column-permalink' for a column marker" do
      column_marker("24", @sitting).should have_tag("a.column-permalink", :count => 1)
    end

    it "should return an 'a' tag with id 'column_24B' for a column whose normalized number is 24B" do
      column_marker("24", @sitting).should have_tag("a[id=column_24b]", :count => 1)
    end

    it "should return an 'a' tag with title 'Col. 24B &mdash; ' and the hansard reference for column whose normalized number is 24B" do
      @sitting.stub!(:hansard_reference).and_return("hansard ref")
      column_marker("24", @sitting).should have_tag("a[title=Col. 24B &mdash; hansard ref]", :count => 1)
    end

    it "should return an 'a' tag with name 'column_24B' for column whose normalized number is 24B" do
      column_marker("24", @sitting).should have_tag("a[name=column_24b]", :count => 1)
    end

    it "should return an 'a' tag with href '#column_24B' for column whose normalized number is 24B" do
      column_marker("24", @sitting).should have_tag("a[href=#column_24b]", :count => 1)
    end

    it "should return an 'a' tag with rel bookmark for column 24" do
      column_marker("24", @sitting).should have_tag("a[rel=bookmark]", :count => 1)
    end

    it "should return an 'a' tag with text 24B for column whose normalized number is 24B" do
      column_marker("24", @sitting).should have_tag("a", :text => "24B", :count => 1)
    end

    it "should ask the sitting for the normalized column" do
      Sitting.should_receive(:normalized_column).and_return("24")
      column_marker("24", @sitting)
    end

    it "should use the normalized column in the column marker" do
      Sitting.stub!(:normalized_column).and_return("24M")
      column_marker("24", @sitting).should have_tag('a', :text => "24M", :count => 1)
    end
  end
  
  describe 'when asked for an image url' do 
    
    it 'should return "/images/pages/test_image.jpg" for "test_image"' do 
      image_url('test_image').should == '/images/pages/test_image.jpg'
    end
    
  end
  
  describe 'when asked whether an image exists' do 
  
    it 'should return true for "test_image" if the file "/public/images/pages/test_image.jpg" exists' do 
      File.stub!(:exist?).with("#{RAILS_ROOT}/public/images/pages/test_image.jpg").and_return(true)
      image_exists?('test_image').should be_true
    end
    
    it 'should return false for "test_image" if the file "/public/images/pages/test_image.jpg" does not exist' do
      File.stub!(:exist?).with("#{RAILS_ROOT}/public/images/pages/test_image.jpg").and_return(false)
      image_exists?('test_image').should be_false
    end
     
  end
  
  describe 'when returning image markers' do 
    
    before do 
      @image = 'test image'
      @sitting = mock_model(Sitting)
    end
  
    it 'should ask if the image exists' do 
      should_receive(:image_exists?).with("test image")
      image_marker(@image, @sitting)
    end
    
    describe 'if the image does not exist' do
      
      before do
        stub!(:image_exists?).and_return(false) 
      end
      
      it 'should return ""' do 
        image_marker(@image, @sitting).should == ""
      end
      
    end
    
    describe 'if the image exists' do
      
      before do 
        stub!(:image_exists?).and_return(true)
      end
      
      it 'should ask for the url of the image' do 
        should_receive(:image_url).with("test image")
        image_marker(@image, @sitting)
      end
      
      it 'should return a link to the image url' do 
        stub!(:image_url).and_return('/url/path/test')
        image_marker(@image, @sitting).should have_tag('a[href=/url/path/test]')
      end
      
      it 'should return a link with text "P"' do 
        image_marker(@image, @sitting).should have_tag('a', :text => 'P')
      end
      
      it 'should return a link with class "page-preview"' do 
        image_marker(@image, @sitting).should have_tag('a.page-preview')
      end
    
    end
  
  end
  
end
