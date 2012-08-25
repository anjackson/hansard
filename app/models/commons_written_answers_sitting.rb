class CommonsWrittenAnswersSitting < WrittenAnswersSitting

  def self.anchor
    "commons_#{self.uri_component}"
  end

  def self.house
    'Commons'
  end

  protected

    def self.hansard_reference_prefix
      "HC"
    end

    def self.hansard_reference_suffix
      "W"
    end

end