class TimeContribution < ProceduralContribution

  TIME_PATTERN = regexp '\A(\d\d?(\.|&#x00B7;)\d\d (am|pm))\Z' unless defined?(TIME_PATTERN)
  OLD_TIME_TEXT = regexp '\(\d\d?\.\d\d?\.\)' unless defined?(OLD_TIME_TEXT)

  before_validation_on_create :populate_time

  def timestamp
    if time
      date = section.sitting.date
      Time.utc_time(date.year, date.month, date.day, time.hour, time.min).xmlschema
    else
      nil
    end
  end
  
  def populate_mentions
    # overrides method to prevent act and bill matching in time contribution
  end

  protected

    def populate_time
      if text
        unless OLD_TIME_TEXT.match text
          normalized_time_text = self.text.gsub('.',':').gsub("&#x00B7;", ":")
          self.time = Time.parse(normalized_time_text)
        end
      end
    end
end
