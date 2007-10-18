module SearchHelper
  
  def format_result_fragment(fragment)
    # unescape any full html entities
    fragment = CGI::unescapeHTML(fragment)
    
    # get rid of leading punctuation
    fragment.gsub!(/^(\.|,|\(|\)|:)/, '')
    
    fragment
  end
  
  def format_member_name(name)
    CGI::unescapeHTML(name)
  end
  
end