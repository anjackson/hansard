class UrlResolver < ExternalReferenceResolver

  def positive_pattern_groups
    start = /(:?\A|\s|\(|:)/
    slash =  /(&#x002F;|\/)/
    protocol = /(h?ttps?)/
    host_delimiter = /[\-\.\s?]{1}\s?/
    any_host_part = /[a-z0-9]+/i
    known_host_part = /(gov)/
    host_start = /#{any_host_part}/
    host_part = /(#{host_delimiter}?\s?#{known_host_part}|#{host_delimiter}#{any_host_part})/
    any_top_level_domain = /[a-z]{2,5}/i
    known_top_level_domain = /(uk)/
    top_level_domain = /(\.?\s?#{known_top_level_domain}|\.#{any_top_level_domain})/
    host = /#{host_start}(#{host_part})+#{top_level_domain}/i
    protocol_and_host = /#{protocol}\s?:#{slash}#{slash}?\s?(#{host})/
    no_protocol_www_host = /(www(#{host_part})+#{top_level_domain})/i
    segment_text = /[a-z0-9\-_&#;]/i
    spaced_url_segments = /((\/\s?#{segment_text}+)+)/i
    url_segments = /((\/#{segment_text}+)+)/i
    
    extensions = ['shtml','html', 'pdf', 'asp', 'hcsp', 'htm']
    file_with_extension = /(\/#{segment_text}+\.[a-z]{3,4})/i
    file_with_known_extension = /(\/?\s?#{segment_text}+\.\s?#{Regexp.union(*extensions)})/i
    
    [[/#{start}(#{protocol_and_host}#{spaced_url_segments}?#{file_with_known_extension})/i, 2],
     [/#{start}(#{protocol_and_host}#{url_segments}?#{file_with_extension})/i, 2],
     [/#{start}(#{protocol_and_host}#{url_segments}?\/?)/i, 2],
     [/#{start}(#{no_protocol_www_host}#{url_segments}?#{file_with_extension})/i, 2],
     [/#{start}(#{no_protocol_www_host}#{url_segments}?\/?)/i, 2]]
  end
  
  def reference_replacement(url)
    href = url.gsub(/\s/, '')
    href.gsub!(/&#x002F;/, '/')
    href.gsub!(/&#x2013;/, '-')
    href = 'http://' + href unless /http/.match url
    "<a class='resolved-url' href=\"#{href}\">#{url}</a>"    
  end
end