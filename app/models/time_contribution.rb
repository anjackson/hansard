class TimeContribution < ProceduralContribution

  before_validation_on_create :populate_time

  def timestamp
    date = section.sitting.date
    Time.utc(date.year, date.month, date.day, time.hour, time.min).xmlschema
  end


  protected

    def populate_time
      if self.text
        normalized_time_text = self.text.gsub('.',':').gsub("&#x00B7;", ":")
        self.time = Time.parse(normalized_time_text)
      end
    end
end
