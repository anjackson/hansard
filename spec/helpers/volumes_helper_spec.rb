require File.dirname(__FILE__) + '/../spec_helper'
include VolumesHelper

describe VolumesHelper, " when creating a series title" do 

  before do
    @series = mock_model(Series, :name => "series name")
    @series_list = [@series]
  end
  
  it 'should return the name of the series passed to it if there is only one' do 
    series_title('5', @series_list).should == "series name"
  end
  
  it 'should return the name of the numerical part of the series string passed to it if there is more or less than one series passed to it' do 
    Series.stub!(:series_name).with(5).and_return("fifth series name")
    series_title('5', [@series, @series]).should == "fifth series name"
  end 
  
end

describe VolumesHelper, " when creating a volume title" do 
  
  before do 
    @series = mock_model(Series, :name => "Sixth Series (Commons)")
  end
  
  it 'should return "Sixth Series (Commons), Volume 424 (Part 1)" if passed series "6C", volume "424" and part "1"' do 
    volume_title(@series, "424", "1").should == "Sixth Series (Commons), Volume 424 (Part 1)"
  end
  
  it 'should return "Sixth Series (Commons), Volume 424" if passed series "6C", volume "424" and no part' do 
    volume_title(@series, "424", nil).should == "Sixth Series (Commons), Volume 424"
  end
  
end


describe VolumesHelper, " when creating links to series" do 
  
  before do 
    @series = mock_model(Series, :name => "test series", :volumes => [], :id_hash => {})
    stub!(:series_index_url).and_return("http://test.series.url")
  end
  
  it 'should return a link to the series index url with the series name if the series has volumes' do 
    @series.stub!(:volumes).and_return(["a volume"])
    series_link(@series).should have_tag('a[href=http://test.series.url]', :text => 'test series')
  end
  
  it 'should return the series name if the series has no volumes' do 
    series_link(@series).should == 'test series'
  end
  
end

describe VolumesHelper, " when creating links to volumes" do 

  before do 
    stub!(:volume_url).and_return("http://test.host")
  end
  
  it 'should create a link with text "Volume 265" when passed a volume with the corresponding number and period' do 
    volume = mock_model(Volume, :name => "Volume 265", 
                                :period => "30 October–8 November 1995",
                                :id_hash => {})
    volume_link(volume).should have_tag('a', :text => 'Volume 265')
  end
  
end

describe VolumesHelper, " when asked for regnal years text for a volume" do 
  
  it 'should give text "17 (Commons)" when passed a volume with the corresponding attributes' do
    volume = mock_model(Volume, :house => 'commons', 
                                :first_regnal_year => 17,
                                :last_regnal_year => 17)
    regnal_years_text(volume).should ==  '17 (Commons)'
  end
end


describe VolumesHelper, " when creating links to monarchs" do
  
  it 'should create a link with text "Elizabeth II" for monarch "ELIZABETH II" if there are volumes for the monarch\'s reign' do
    Monarch.stub!(:volumes_by_monarch).and_return({ 'ELIZABETH II' => true })
    monarch_link('ELIZABETH II').should have_tag('a', :text => 'Elizabeth II')
  end
  
  it 'should create a link to the monarch url if there are volumes in the monarch\'s reign' do
    Monarch.stub!(:volumes_by_monarch).and_return({ 'ELIZABETH II' => true })
    stub!(:monarch_index_url).and_return('http://test.host/volumes/elizabeth-ii')
    monarch_link('ELIZABETH II').should have_tag('a[href=http://test.host/volumes/elizabeth-ii]')
  end
  
  it 'should not make a link if there are no volumes during the monarchs reign' do
    Monarch.stub!(:volumes_by_monarch).and_return({ 'ELIZABETH II' => false })
    monarch_link('ELIZABETH II').should_not have_tag('a')
  end

end

describe VolumesHelper, " when making links to columns in a sitting" do 


  it 'should create columns in "td" tags within a "tr" tag' do 
    stub!(:column_link).and_return("link")
    sitting = mock_model(Sitting, :start_column => 1,
                                  :end_column => 13,
                                  :find_section_by_column => nil)
    sitting_column_links(sitting).should have_tag('tr', :count => 2) do 
      with_tag('td.column-number', :count => 13, :text => 'link')
    end  
  end
  
end


describe VolumesHelper, " when making links to a column" do 

  before do 
    Sitting.stub!(:normalized_column).and_return("1B")
    @sitting = Sitting.new
    @section = mock_model(Section, :null_object => true)
    stub!(:column_url).and_return("http://www.test.host#column_1b")
  end
  
  it 'should ask for the normalized column' do 
    Sitting.should_receive(:normalized_column)
    column_link(1, nil, @sitting)
  end
  
  it 'should return the normalized column with no link if no section is given' do
    column_link(1, nil, @sitting).should have_tag('div.missing-column', :text => '1B')
  end
  
  it 'should should return a link if a section is given' do 
    column_link(1, @section, @sitting).should have_tag('a')
  end
  
  it 'should return a link to the section with column anchor' do
    column_link(1, @section, @sitting).should have_tag('a[href=http://www.test.host#column_1b]')
  end
  
  it 'should return a link whose text is the normalized column' do 
    column_link(1, @section, @sitting).should have_tag('a', :text => "1B")
  end
  
end

describe VolumesHelper, "when formatting percentages" do 

  it 'should  read "less than 1" if less than 1% but greater than 0%.' do
   format_percent(0.5).should == "less than 1<span class='percent'>%</span>"
  end

  it 'should read "none" if 0%, rather than 0%.' do 
    format_percent(0).should == "none"
  end
  
  it 'should read "5<span class=\'percent\'>%</span>" if 5' do 
    format_percent(5).should == "5<span class='percent'>%</span>"
  end
  
end
