class UrlDate

  attr_reader :year, :month, :day, :hash
  
  def UrlDate::mm_to_mmm mm
    Date::ABBR_MONTHNAMES[mm.to_i].downcase
  end

  def initialize params
    @hash = params
    @year = params[:year]
    @month = params[:month]
    @day = params[:day]
  end

  def to_date
    if is_valid_date?
      m = Date::ABBR_MONTHNAMES.index(month.capitalize)
      Date.new(year.to_i, m, day.to_i)
    else
      nil
    end
  end

  def is_valid_date?
    @year.length == 4 and (!@month or @month.length == 3) and (!@day or @day.length == 2)
  end

  def month
    if @month and @month.length < 3
      UrlDate.mm_to_mmm @month
    elsif @month and @month.length > 3
      UrlDate.mm_to_mmm Date::MONTHNAMES.index(@month.downcase)
    else
      @month
    end
  end

  def day
    if @day and (@day.length == 1)
      '0'+@day
    else
      @day
    end
  end

  def strftime pattern
    if pattern == "%d %b %Y"
      if @day
        day = if @day.index('0') == 0
                @day[1..1]
              else
                @day
              end
        day + ' ' + month.titlecase + ' ' + @year
      elsif @month
        month.titlecase + ' ' + @year.to_s
      else
        @year.to_s
      end
    else
      ''
    end
  end

end