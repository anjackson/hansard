class LordsWrittenStatementsSitting < WrittenStatementsSitting

  def self.anchor
    "lords_#{self.uri_component}"
  end

  def self.house
    'Lords'
  end

  protected

    def self.hansard_reference_prefix
      "HL"
    end

    def self.hansard_reference_suffix
      "WS"
    end

end