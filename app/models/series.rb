class Series < ActiveRecord::Base

  has_many :volumes, :order => 'number asc, part asc'

  IN_WORDS = { 1 => "First",
               2 => "Second",
               3 => "Third",
               4 => "Fourth",
               5 => "Fifth",
               6 => "Sixth" }

   NUMBER_TO_OFFICIAL_SERIES_NAMES = {
     2 => "The Parliamentary Debates, New Series",
     3 => "Hansard's Parliamentary Debates (3rd Series)",
     4 => "The Parliamentary Debates (4th Series)",
     5 => "The Official Report, House of Commons (5th Series)",
     6 => "The Official Report, House of Commons (6th Series)"}

  def self.find_all
    @all ||= get_all
  end

  def self.get_all
    find(:all, :order => "number asc", 
                        :include => :volumes)
  end

  def self.percent_loaded
    series_list = find_all
    complete_volumes = series_list.inject(0){ |sum, series| sum + series.complete_volumes }
    expected_volumes = series_list.inject(0){ |sum, series| sum + series.last_volume }
    (complete_volumes.to_f / expected_volumes.to_f) * 100
  end

  def self.percent_success
    series_list = find_all
    volumes = series_list.map{ |series| series.volumes }.flatten
    volumes.inject(0){ |sum, volume| sum + volume.percent_success}.to_f / volumes.size.to_f
  end

  def complete_volumes
    @complete_volumes ||= calculate_complete_volumes
  end
  
  def calculate_complete_volumes
    volumes.inject(0){ |sum, volume| (volume.part.to_i > 0) ? sum + 0.5 : sum + 1 }
  end

  def percent_loaded
    (complete_volumes.to_f / last_volume.to_f) * 100
  end

  def percent_success
    return 0 if volumes.empty?
    volumes.inject(0){ |sum, volume| sum + volume.percent_success}.to_f / volumes.size.to_f
  end
  
  def volumes_for_number(number, volumes)
    vols_for_number = []
    while volumes.first and volumes.first.number == number
      vols_for_number << volumes.shift
    end
    vols_for_number
  end

  def expected_volumes
    expected = []
    1.upto(last_volume) do |volume_number| 
      volume_list_for_number(volume_number, volumes).each{ |volume| expected << volume }
    end
    expected
  end  
  
  def volume_list_for_number(number, volumes)
    vols_for_num = volumes_for_number(number, volumes)
    return [[number, 0, nil]] if vols_for_num.empty? 
    if vols_for_num.size == 1 and vols_for_num.first.part > 0
      volume = vols_for_num.first
      if volume.part == 1
        return [[number, 1, volume], [number, 2, nil]]
      elsif volume.part == 2
        return [[number, 1, nil], [number, 2, volume]]
      end
    else
      return vols_for_num.map{ |volume| [number, volume.part, volume] }
    end
  end

  def self.find_by_source_file(source_file)
    find_by_house_and_number(source_file.series_house, source_file.series_number)
  end

  def self.series_name(number)
    "#{IN_WORDS[number]} Series"
  end

  def self.house_from_series(series_string)
    house = nil
    house = 'commons' if /C/.match series_string
    house = 'lords' if /L/.match series_string
    house
  end

  def self.find_all_by_series(series_string)
    include_options = :volumes
    house = house_from_series(series_string)
    series_number = series_string.to_i
    series = []
    if house
      series = find_all_by_number_and_house(series_number, house, :include => include_options)
    else
      series = find_all_by_number(series_number, :include => include_options)
    end
    series
  end

  def self.find_by_series(series_string)
    house = house_from_series(series_string)
    series_number = series_string.to_i
    house = 'both' unless house
    find_by_number_and_house(series_number, house)
  end

  def official_series_name
    NUMBER_TO_OFFICIAL_SERIES_NAMES[number]
  end

  def name
    name = Series.series_name(number)
    name += " (#{house.titleize})" unless house == 'both'
    name
  end

  def id_hash
    series = number.to_s
    series += house.at(0).upcase unless house == 'both'

    { :series => series }
  end

end