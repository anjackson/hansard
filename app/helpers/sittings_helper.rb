module SittingsHelper
  
  include PresentOnDateTimelineHelper
  
  def frequent_section_titles(date, resolution)
    start_date = get_start_date(date, resolution, {})
    end_date = get_end_date(date, resolution, {})
    Section.frequent_titles_in_interval(start_date, end_date).each do |title|
      yield title, start_date, end_date
    end
  end
  
end