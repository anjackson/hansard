class Volume < ActiveRecord::Base

  belongs_to :series
  has_many :sittings, :dependent => :destroy, :order => 'date asc, start_column asc'
  belongs_to :source_file
  belongs_to :data_file
  belongs_to :parliament_session
  before_validation_on_create :normalize_monarch, :populate_first_and_last_regnal_years, :populate_start_and_end_date

  DAY_SUFFIX = '(?:th|st|nd|rd|d(?= ))'
  DAY = /(\d\d?)#{DAY_SUFFIX}?/i
  YEAR = /(\d\d\d\d)/
  TO = /[Tt][Oo]/
  DASH = /(?:&#x[20][20]1[34];|-)/
  DASH_PERIOD_PATTERN = /#{DAY} ?(.*?)#{DASH}.*?#{DAY},? ?(.*?) ?#{YEAR}/  
  DASH_TWO_YEAR_PATTERN = /#{DAY}(.*?),? ?#{YEAR}#{DASH}.*?#{DAY},? (.*?),? ?#{YEAR}/
  BETWEEN_WORDS_PATTERN = /#{DAY} OF (.*?) .*? #{DAY} OF (.*?) #{YEAR}/
  BETWEEN_ALTERNATIVE_PATTERN = /#{DAY} (.*?),? #{YEAR},? (?:AND|#{TO}).*?,? ?#{DAY},? (.*?),? #{YEAR}/
  WORDS_PERIOD_PATTERN = / (.*?) DAY O ?F (.*?),? #{YEAR}, ?#{TO}? .*? (.*?) (?:DAY )?OF (.*?),? #{YEAR}/
  WORDS_IN_ONE_MONTH_PATTERN = /THE (.*?) #{TO} THE (.*?) DAY OF (.*?),? #{YEAR}/
  REVERSE_WORDS_IN_ONE_MONTH_PATTERN = /THE (.*?) DAY OF (.*?), #{TO} THE (.*?),? #{YEAR}/
  WORDS_SINGLE_YEAR_PERIOD_PATTERN = / (.*?) DAY OF (.*?) #{TO} .*? (.*?) (?:DAY )?OF (.*?),? #{YEAR}/
  COMMAS_PERIOD_SINGLE_YEAR_PATTERN = /#{DAY} (.*?),?\.? .*?#{TO}.*? #{DAY} (.*?),? #{YEAR}/
  NO_YEAR_PERIOD_PATTERN = /#{DAY} (.*?),? #{TO} .*? #{DAY} (\S+)\.?,?( |$)/
  NO_YEAR_ONE_MONTH_DASH_PATTERN = /#{DAY}#{DASH}#{DAY} (.*)/
  NO_YEAR_TWO_MONTH_DASH_PATTERN = /#{DAY} (.*?)#{DASH}(?:.*?)#{DAY} (.*)/
  REVERSE_DATE_PATTERN = /(.*?) #{DAY},? #{YEAR},? #{TO} .*? (.*?) #{DAY},? #{YEAR}/
  REVERSE_SINGLE_YEAR_PATTERN = /(.*?) #{DAY},? #{TO} .*? (.*?) #{DAY},? #{YEAR}/
  NO_SEPARATOR_PATTERN = /(?: |^)#{DAY} (\S+) #{DAY} (\S+) #{YEAR}/
  REVERSE_WORDS_NO_YEAR_PATTERN = /THE (.*?) DAY OF (.*?) #{TO} THE (.*?) DAY OF (.*)/
  TWO_DAYS_PATTERN = /(.*?) AND (.*?) DAYS OF (.*?),? #{YEAR}/

  def self.start_and_end_date_from_period(period, year=nil)
    start_date = end_date = nil

    case clean_days_in_period(period)
      when DASH_PERIOD_PATTERN
        start_month = $2.blank? ? $4 : $2
        start_date = Date.parse("#{$1} #{start_month} #{$5}")
        end_date = Date.parse("#{$3} #{$4} #{$5}")
      
      when NO_SEPARATOR_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{$5}")
        end_date = Date.parse("#{$3} #{$4} #{$5}")
          
      when WORDS_PERIOD_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$2} #{$3}")
        end_date = Date.parse("#{$4.ordinal_to_number} #{$5} #{$6}")
        
      when WORDS_SINGLE_YEAR_PERIOD_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$2} #{$5}")
        end_date = Date.parse("#{$3.ordinal_to_number} #{$4} #{$5}")

      when BETWEEN_ALTERNATIVE_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{$3}")
        end_date = Date.parse("#{$4} #{$5} #{$6}")

      when BETWEEN_WORDS_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{$5}")
        end_date = Date.parse("#{$3} #{$4} #{$5}")
        
      when WORDS_IN_ONE_MONTH_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$3} #{$4}")
        end_date = Date.parse("#{$2.ordinal_to_number} #{$3} #{$4}")
            
      when REVERSE_WORDS_IN_ONE_MONTH_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$2} #{$4}")
        end_date = Date.parse("#{$3.ordinal_to_number} #{$2} #{$4}")    

      when REVERSE_DATE_PATTERN
        start_date = Date.parse("#{$2} #{$1} #{$3}")
        end_date = Date.parse("#{$5} #{$4} #{$6}")  
         
      when DASH_TWO_YEAR_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{$3}")
        end_date = Date.parse("#{$4} #{$5} #{$6}")  
        
      when COMMAS_PERIOD_SINGLE_YEAR_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{$5}")
        end_date = Date.parse("#{$3} #{$4} #{$5}")
        
      when REVERSE_SINGLE_YEAR_PATTERN
        start_date = Date.parse("#{$2} #{$1} #{$5}")
        end_date = Date.parse("#{$4} #{$3} #{$5}")

      when NO_YEAR_PERIOD_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{year}")
        end_date = Date.parse("#{$3} #{$4} #{year}")
               
      when REVERSE_WORDS_NO_YEAR_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$2} #{year}")
        end_date = Date.parse("#{$3.ordinal_to_number} #{$4} #{year}") 
    
      when NO_YEAR_ONE_MONTH_DASH_PATTERN
        start_date = Date.parse("#{$1} #{$3} #{year}")
        end_date = Date.parse("#{$2} #{$3} #{year}")
    
      when NO_YEAR_TWO_MONTH_DASH_PATTERN
        start_date = Date.parse("#{$1} #{$2} #{year}")
        end_date = Date.parse("#{$3} #{$4} #{year}")
        
      when TWO_DAYS_PATTERN
        start_date = Date.parse("#{$1.ordinal_to_number} #{$3} #{$4}")
        end_date = Date.parse("#{$2.ordinal_to_number} #{$3} #{$4}")
        
    end if period

    return start_date, end_date
  end

  def self.find_all_by_identifiers(series_string, number, part)
    series = Series.find_by_series(series_string)
    return [] unless series
    if part.blank?
      find_all_by_series_id_and_number(series.id, number, :order => "part asc")
    else
      find_all_by_series_id_and_number_and_part(series.id, number, part)
    end
  end

  def self.first_and_last_from_regnal_years regnal_years
    return [nil, nil] unless regnal_years
    if (number = regnal_years.ordinal_to_number)
      [number, number]
    else
      begin
        year_parts = regnal_years.split(' ')
        [year_parts[0].to_i, year_parts[-1].to_i]
      rescue
        [nil, nil]
      end
    end
  end

  def self.clean_days_in_period(period)
    badly_formed_day = /(\d)(l)(#{DAY_SUFFIX})/i
    period.gsub!(badly_formed_day, '\11\3')
    badly_formed_day = /(\d)(O)(#{DAY_SUFFIX})/i
    period.gsub!(badly_formed_day, '\10\3')
    badly_formed_day = /(i)(\d)(#{DAY_SUFFIX})/i  
    period.gsub!(badly_formed_day, '1\2\3')
    period
  end

  def self.volume_name(number, part)
    name = "Volume #{number}"
    name += " (Part #{part})" if part > 0
    name
  end
  

  def name
    Volume.volume_name(number, part)
  end

  def session_start_year
    return nil unless parliament_session
    parliament_session.start_year
  end
  
  def session_end_year
    return nil unless parliament_session
    parliament_session.end_year
  end

  def start_year
    start_date.year
  end

  def end_year
    end_date.year
  end

  def id_hash
    hash = series.id_hash.update(:volume_number => number)
    hash.update(:part => part) if part > 0
    hash
  end

  def house
    if series.house == 'both'
      nil
    else
      series.house
    end
  end

  def first_and_last_regnal_years
    Volume.first_and_last_from_regnal_years(regnal_years)
  end

  def start_and_end_date
    if source_file and source_file.start_date
      year = source_file.start_date.year
    else
      year = nil
    end
    Volume.start_and_end_date_from_period(period, year)
  end

  def percent_success
    @percent_success ||= calculate_percent_success
  end
  
  def calculate_percent_success
    return 0 if sittings_count == 0 and sittings_tried_count == 0
    (sittings_count.to_f / sittings_tried_count.to_f) * 100
  end
  
  def missing_sittings
    sittings_tried_count - sittings_count
  end

  def missing_sittings?
    return true if percent_success < 100
  end

  def missing_columns?
    return true if missing_first_column?
    return true if !source_file.missing_columns.empty?
    return false
  end
  
  def missing_column_numbers
    missing_columns = []
    missing_columns << 1 if missing_first_column? 
    missing_columns += source_file.missing_columns
  end
  
  def missing_first_column?
    if part <= 1
      return true if !sittings.empty? and Sitting.column_number(sittings.first.start_column) != 1
    end
    return false
  end

  def sittings_by_date_and_column
    sittings.sort{ |a, b| a.date_and_column_sort_params <=> b.date_and_column_sort_params }
  end

  protected

    def normalize_monarch
      self.monarch = "VICTORIA" if monarch == 'VICTORI&#x00C6;'
      self.monarch = 'ELIZABETH II' if monarch == 'ELIZABETH'
    end

    def populate_start_and_end_date
      self.start_date, self.end_date = start_and_end_date
    end

    def populate_first_and_last_regnal_years
      self.first_regnal_year, self.last_regnal_year = first_and_last_regnal_years
    end

end
