class EcDirectiveResolver < ExternalReferenceResolver

  DIRECTIVE = '[d|D]irective'
  NUM = '\d+\/\d+'
  EC_EXTENSION = '\/EE?C'
  NUMBER_NUMBER_EC = /#{NUM}#{EC_EXTENSION}/
  EC_DIRECTIVE_NUMBER = /(European\sCommunity|EC).*?#{DIRECTIVE}\s\(?(#{NUM})(?:#{EC_EXTENSION})?\)?/
  EC_DIRECTIVE_NO_NUMBER = /(European\sCommunity|EC)\s#{DIRECTIVE}\sNo.\s(#{NUM})/
  DIRECTIVE_NUMBER = /#{DIRECTIVE}\s(#{NUM}(#{EC_EXTENSION})?)/

  def positive_pattern_groups
    [[DIRECTIVE_NUMBER, 1],
     [NUMBER_NUMBER_EC, 0], 
     [EC_DIRECTIVE_NUMBER, 2],
     [EC_DIRECTIVE_NO_NUMBER, 2]]
  end
  
  def reference_replacement(ref)
    encoded_ref = CGI.escape(ref)
    %Q|<cite class="reference"><a href="http://www.google.com/search?q=site%3Aeuropa.eu+#{encoded_ref}" rel="ref">#{ref}</a></cite>|
  end
  
end
