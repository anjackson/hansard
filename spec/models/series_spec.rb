require File.dirname(__FILE__) + '/../spec_helper'

describe Series, " when giving its name" do 
  
  it 'should give "Fifth Series" if its number is 5 and house is "both"' do 
    Series.new(:number => 5, :house => 'both').name.should == "Fifth Series"
  end
  
  it 'should give "Sixth Series (Commons)" if its number is 6 and house is "commons"' do 
    Series.new(:number => 6, :house => 'commons').name.should == 'Sixth Series (Commons)'
  end
  
end

describe Series, " when giving its official series name" do 
  
  it 'should give "The Official Report, House of Commons (6th Series)" if its number is 6 and house is "commons"' do 
    Series.new(:number => 6, :house => 'commons').official_series_name.should == "The Official Report, House of Commons (6th Series)"
  end
  
  it 'should give "The Official Report, House of Commons (5th Series)" if its number is 5 and house is "commons"' do 
    Series.new(:number => 5, :house => 'commons').official_series_name.should == "The Official Report, House of Commons (5th Series)"
  end
  
  it 'should give "The Parliamentary Debates (4th Series)" if its number is 4' do 
    Series.new(:number => 4).official_series_name.should == "The Parliamentary Debates (4th Series)"
  end
  
  it 'should give "Hansard\'s Parliamentary Debates (3rd Series)" if its number is 3' do 
    Series.new(:number => 3).official_series_name.should == "Hansard\'s Parliamentary Debates (3rd Series)"
  end
  
  it 'should give "The Parliamentary Debates, New Series" if its number is 2' do
    Series.new(:number => 2).official_series_name.should == "The Parliamentary Debates, New Series"
  end
  
end

describe Series, " when asked for all series" do 

  it 'should return series sorted by number in ascending order' do 
    Series.should_receive(:find).with(:all, :order => "number asc", 
                                            :include => :volumes)
    Series.get_all
  end
  
end

describe Series, " when asked for a series by source file" do 

  it 'should ask for the series by the source files\'s series house and number' do 
    source_file = mock_model(SourceFile, :series_house => 'both', :series_number => 4)
    Series.should_receive(:find_by_house_and_number).with('both', 4)
    Series.find_by_source_file(source_file)
  end
  
end

describe Series, " when finding series" do 

  it 'should look for series with house "commons" and number 4 when given "4C"' do 
    Series.should_receive(:find_by_number_and_house).with(4, "commons")
    Series.find_by_series("4C")
  end
  
  it 'should look for series with house "commons" and number 4 when given "4L"' do 
    Series.should_receive(:find_by_number_and_house).with(4, "lords")
    Series.find_by_series("4L")
  end
  
  it 'should look for series with number 4 and house "both" when given "4"' do 
    Series.should_receive(:find_by_number_and_house).with(4, "both")
    Series.find_by_series("4")
  end
 
end

describe Series, " when finding  all series" do 


  it 'should look for all series with house "commons" and number 4 when given "4C"' do 
    Series.should_receive(:find_all_by_number_and_house).with(4, "commons", :include => :volumes)
    Series.find_all_by_series("4C")
  end
  
  it 'should look for all series with house "commons" and number 4 when given "4L"' do 
    Series.should_receive(:find_all_by_number_and_house).with(4, "lords", :include => :volumes)
    Series.find_all_by_series("4L")
  end
  
  it 'should look for all series with number 4 when given "4"' do 
    Series.should_receive(:find_all_by_number).with(4, :include => :volumes)
    Series.find_all_by_series("4")
  end
 
end

describe Series, " when asked for an id hash" do 
  
  it 'should return "4C" if it has house "commons" and number 4' do 
    series = Series.new(:house => 'commons', :number => 4)
    series.id_hash.should == { :series => '4C' }
  end
  
  it 'should return "4L" if it has house "lords" and number 4' do 
    series = Series.new(:house => 'lords', :number => 4)
    series.id_hash.should == { :series => '4L' }
  end
  
  it 'should return "4" if it has house "both" and number 4' do
    series = Series.new(:house => 'both', :number => 4)
    series.id_hash.should == { :series => '4' }
  end
  
end

describe Series, " when asked for the percent loaded" do 
  
  def setup_volumes(number)
    volumes = []
    volume = mock_model(Volume, :part => nil)
    number.times{ volumes << volume }
    volumes.stub!(:count).and_return(number)
    volumes
  end
  
  it 'should return an overall statistic of around 66.66 if there are two series, one with two volumes out of four loaded and one with two volumes out of two loaded' do 
    one_volume_series = Series.new(:last_volume => 4)
    one_volume_series.stub!(:volumes).and_return(setup_volumes(2))
    two_volume_series = Series.new(:last_volume => 2)
    two_volume_series.stub!(:volumes).and_return(setup_volumes(2))
    Series.stub!(:find_all).and_return([one_volume_series, two_volume_series])
    Series.percent_loaded.should be_close(66.66, 0.007)
  end
  
  it 'should return around 33.33 for a series if it has three expected volumes and one has been loaded' do 
    series = Series.new(:last_volume => 3)
    series.stub!(:volumes).and_return(setup_volumes(1))
    series.percent_loaded.should be_close(33.33, 0.004)
  end
  
  it 'should return 75 for a series if it has 10 expected volumes and 8 have been loaded, one of which is a volume part' do 
    volumes = setup_volumes(7)
    part_volume = mock_model(Volume, :part => 2)  
    volumes << part_volume
    volumes.stub!(:count).and_return(8)
    series = Series.new(:last_volume => 10)
    series.stub!(:volumes).and_return(volumes)
    series.percent_loaded.should == 75
  end
  
end

describe Series, " when asked for percent success" do 

  it 'should return an overall statistic of 20 if there are 5 volumes loaded each with 20% success' do 
    volumes = []
    5.times{ volumes << mock_model(Volume, :percent_success => 20)}
    Series.stub!(:find_all).and_return([mock_model(Series, :volumes => volumes)])
    Series.percent_success.should == 20
  end
  
  it 'should return 0 for a series with no volumes' do 
    series = Series.new
    series.percent_success.should == 0
  end
  
  it 'should return 40 for a series with three volumes loaded, with 20, 40, and 60% success each' do 
    twenty_percent = mock_model(Volume, :percent_success => 20)
    forty_percent = mock_model(Volume, :percent_success => 40)
    sixty_percent = mock_model(Volume, :percent_success => 60)
    series = Series.new
    series.stub!(:volumes).and_return([forty_percent, twenty_percent, sixty_percent])
    series.percent_success.should == 40
  end
  
end

describe Series, 'when asked for a volume by number' do 
  
  before do 
    @volume = mock_model(Volume, :number => 4)
    @series = Series.new(:volumes => [@volume])
  end
  
  it 'should return any volumes with that number' do 
    @series.volumes_for_number(4, @series.volumes).should == [@volume]
  end
  
  it 'should return an empty list if no volumes exist with that number' do
    @series.volumes_for_number(5, @series.volumes).should == []
  end
  
end

describe Series, 'when asked for its expected volumes' do 
  
  it 'should yield for each expected volume in the series a list of the number and the volume if loaded' do 
    volume_three = mock_model(Volume, :number => 3, :part => 0)
    volume_four_part_two = mock_model(Volume, :number => 4, :part => 2)
    volume_five_part_one = mock_model(Volume, :number => 5, :part => 1)
    volume_five_part_two = mock_model(Volume, :number => 5, :part => 2)    
    expected = [[1, 0, nil], 
                [2, 0, nil], 
                [3, 0, volume_three], 
                [4, 1, nil], 
                [4, 2, volume_four_part_two], 
                [5, 1, volume_five_part_one], 
                [5, 2, volume_five_part_two], 
                [6, 0, nil]]
    volumes = [volume_three, volume_four_part_two, volume_five_part_one, volume_five_part_two]
    series = Series.new(:volumes => volumes, :last_volume => 6)
    series.expected_volumes.should == expected
  end

end
