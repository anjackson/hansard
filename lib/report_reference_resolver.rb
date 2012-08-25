class ReportReferenceResolver < ExternalReferenceResolver
  
  ITALIC_OPEN = /(?:<span class="italic">)/
  ITALIC_CLOSE = /(?:<\/span>)/
  PUNCT = /[:|,|;|\.]?/
  OFFICIAL_REPORT = /#{ITALIC_OPEN}?(?:OFFICIAL REPORT|Official Report),?#{ITALIC_CLOSE}?/
  SHORT_DATE = /\d\d?\/\d\d?\/\d\d/
  LONG_DATE = /\d+(?:th|rd|st|St)?\s[A-Za-z]{3,10}#{PUNCT}?(?:\s\d\d\d\d)?/
  DATE = /((?:#{LONG_DATE}|#{SHORT_DATE}))#{PUNCT}?/
  HYPHEN = /(?:–|-|\.|&#x2013;)/
  COLS = /c(?:ol)?(?:umn)?s?\.?\s/
  COLUMN = /#{COLS}?#{ITALIC_OPEN}?(?:WA\s)?(\d+)(?:WS)?(?:#{HYPHEN}\d+)?(?:, \d+)*W?#{ITALIC_CLOSE}?/
  VOLUME = /Vol\.? (\d+)/i
  TYPE = /(?:(House of Commons|House of Lords|Written Answers|\(?Commons,? W\.?A\.?\)?)#{PUNCT}?)/
  COL_AND_VOL = /(#{COLUMN},\s#{VOLUME}|#{VOLUME},\s#{COLUMN}|#{COLUMN})/
  TYPE_AND_DATE = /(?:\s(#{DATE}\s?#{TYPE}?|#{TYPE}?\s?#{DATE})\s)/
     
  REPORT_REFERENCE = /(#{OFFICIAL_REPORT}
                       #{PUNCT}
                       #{TYPE_AND_DATE}
                       #{COL_AND_VOL}
                       #{PUNCT}?)/x

  ALTERNATE_REPORT_REFERENCE = /(#{DATE}\s?
                                 \(?#{OFFICIAL_REPORT}
                                 #{PUNCT}\s
                                 #{COLUMN}\)?)/x
                                 
  def positive_pattern_groups    
    [[REPORT_REFERENCE, 1],
     [ALTERNATE_REPORT_REFERENCE, 1]]
  end
  
  def reference_params(ref)
    alternate_match = false
    match = REPORT_REFERENCE.match(ref)
    
    if !match 
      match = ALTERNATE_REPORT_REFERENCE.match(ref)
      alternate_match = true
    end
    if match 
      if alternate_match
        date = get_alternate_date(match)
        column = get_alternate_column(match)
        type = nil
        params = {}
      else
        type, date = get_type_and_date(match)
        column = get_column(match)
      end
      return {} if ! date
      params = { :date   => date, 
                 :column =>column }
      if params[:date].year == Time.now.year
        date = params.delete(:date)
        params[:month] = date.month
        params[:day] = date.day
      end
      params[:written_answer] = true if written_answer?(ref)
      params[:written_statement] = true if written_statement?(ref)

      if (house = get_house(ref))
        params[:house] = house
      end
    end
    
    params
  end
  
  def get_type(type_and_date)
    type = TYPE.match(type_and_date)
    type ? type[1] : nil
  end
  
  def get_type_and_date(match)
    [get_type(match[2]), get_date(match[2])]
  end
  
  def get_alternate_date(match)
    date = DATE.match(match[1])
    return Date.parse(date[1])
  end
  
  def get_alternate_column(match)
    match[3]
  end
  
  def get_column(match)
    column = match[8] || match[11] || match[12] || match[10]
  end

  def get_date(type_and_date)   
    begin 
      if (short_date = SHORT_DATE.match(type_and_date))
        day, month, year = short_date[0].split('/')
        return Date.parse("#{month}/#{day}/#{year}", comp=true)
      else
        date = DATE.match(type_and_date)
        return Date.parse(date[1]) if date
        date = DATE_WITHOUT_YEAR.match(type_and_date)
        return Date.parse(date[1])
      end
    rescue
      return nil
    end
  end
  
  def get_house string
    return nil unless string
    return 'lords' if /Lords/i.match string
    return 'commons' if /Commons/i.match string
    nil
  end
  
  def written_answer? string
    return false unless string
    return true if /Written Answers/.match string
    return true if /W\.?A\.?/.match string
    return true if /W$/.match string
    nil
  end
  
  def written_statement? string
    return false unless string
    return true if /WS/.match string
    nil
  end
  
end