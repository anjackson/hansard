require File.dirname(__FILE__) + '/../spec_helper'

describe DaysHelper, " when rendering a calendar" do
  
  before do
    @current_date = Date.new(2004, 10, 24)
    @other_date_with_material = Date.new(2004, 10, 11)
    @no_material_date = Date.new(2004, 10, 1)
    @dates_with_material = [@current_date, @other_date_with_material]
    stub!(:find_next_day_with_material).and_return(@current_date)
    stub!(:date_link).and_return('<a href="">a link</a>')
    stub!(:calendar).and_yield(@current_date)
  end
  
  it "should ask for the first day in the next month with material" do 
    should_receive(:find_next_day_with_material).with(@current_date, ">>", :month)
    render_calendar(@current_date, @dates_with_material)
  end
  
  it "should ask for the first day in the previous month with material" do 
    should_receive(:find_next_day_with_material).with(@current_date, "<<", :month)
    render_calendar(@current_date, @dates_with_material)
  end
  
  it "should ask for the first day in the corresponding month next year with material" do
    should_receive(:find_next_day_with_material).with(@current_date, ">>", :year)
    render_calendar(@current_date, @dates_with_material)
  end
  
  it "should ask for the first day in the corresponding month last year with material" do
    should_receive(:find_next_day_with_material).with(@current_date, "<<", :year)
    render_calendar(@current_date, @dates_with_material)
  end
  
  it "should ask for a calendar, passing the current date params and links to the next and previous months and years" do
    should_receive(:calendar).with(:year => @current_date.year, 
                                   :month => @current_date.month, 
                                   :day => @current_date.day, 
                                   :next_month => '<a href="">a link</a>',
                                   :prev_month => '<a href="">a link</a>',
                                   :next_year  => '<a href="">a link</a>',
                                   :prev_year => '<a href="">a link</a>')
    render_calendar(@current_date, @dates_with_material)
  end
  
  it "should render a day in the list of days with material as a link to that day with class 'day-with-material', title 'day-with-material'" do
    stub!(:calendar).and_yield(@other_date_with_material)
    render_calendar(@current_date, @dates_with_material).should == ["<a href=\"\">a link</a>", {:class=>"day-with-material", :title=>"Day with material"}]
  end
  
  it "should render the current day with id 'current-day' " do
    stub!(:calendar).and_yield(@current_date)
    render_calendar(@current_date, @dates_with_material).should == ["<a href=\"\">a link</a>", {:class=>"day-with-material", :title=>"Day with material", :id => "current-day"}]
  end
  
  it "should render a day not in the list of days with material as the day of the month" do
    stub!(:calendar).and_yield(@no_material_date)
    render_calendar(@current_date, @dates_with_material).should == [@no_material_date.mday, nil]
  end
  
end

describe DaysHelper, " when creating a date link" do
  
  before do
    @date = Date.new(1911, 1, 24)
    stub!(:url_for).and_return("http://www.test.url")
  end
  
  it "should make the text of the link the text it is passed" do
    date_link(@date, "moo").should have_tag("a[href=http://www.test.url]", :text => "moo")
  end
  
  it "should make the text of the link the day of the month if not passed some text" do
    date_link(@date).should have_tag("a[href=http://www.test.url]", :text => "24")
  end
  
  it "should ask for the url for the show action on the days controller, passing the date params" do
    should_receive(:url_for).with(:controller => 'days', :action => 'show', :year => 1911, :month => 1, :day => 24)
    date_link(@date)
  end

end

describe DaysHelper, " when finding the first day with material in the next or previous month" do
  
  before do
    @current_date = Date.new(1955, 3, 10)
    @prev_date = Date.new(1955, 2, 10)
    @first = Date.new(1955, 2, 1)
    @last = Date.new(1955, 2, 28)
    @current_date.stub!(:<<).and_return(@prev_date)
    @prev_date.stub!(:first_and_last_of_month).and_return([@first, @last])
  end
  
  it "should ask for the corresponding day to the current day in the month" do
    @current_date.should_receive(:<<).with(1).and_return(@prev_date)
    find_next_day_with_material(@current_date, '<<')
  end
  
  it "should find the first and last days of the month" do
    @prev_date.should_receive(:first_and_last_of_month).and_return([@first, @last])
    find_next_day_with_material(@current_date, '<<')
  end
  
  it "should find the days in the month with material" do
    @first.should_receive(:material_dates_upto).with(@last).and_return([])
    find_next_day_with_material(@current_date, '<<')
  end
  
  it "should return the first day with material if there are dates with material" do
    @first.stub!(:material_dates_upto).and_return([@current_date])
    find_next_day_with_material(@current_date, '<<').should == @current_date
  end
  
  it "should return the first day of the month if there are no dates with material" do
    @first.stub!(:material_dates_upto).and_return([])
    find_next_day_with_material(@current_date, '<<').should == @first
  end
  
end