class ResultSet
  
  def initialize xml
    @doc = REXML::Document.new(xml)
  end
   
  def summary_node 
    @summary_node ||= REXML::XPath.first(@doc, '/GSP/RES/')
  end

  def total_node
    @total_node ||= REXML::XPath.first(@doc, '/GSP/RES/M/')
  end

  def first
    summary_node.nil? ? 0 : summary_node.attribute('SN').value.to_i
  end

  def last 
    summary_node.nil? ? 0 : summary_node.attribute('EN').value.to_i
  end

  def total
    total_node.nil? ? 0 : total_node.text.to_i
  end

  def hits
    hits = []
    REXML::XPath.each(@doc, '/GSP/RES/R/') do |match| 
      hit = {:title      => first_text(match, 'T'),
             :text       => first_text(match, 'S'),
             :link_text  => first_text(match, 'UE'),
             :link       => first_text(match, 'U')}
      hits << hit
    end
    hits
  end

  def suggestion_node
    REXML::XPath.first(@doc, '/GSP/Spelling/Suggestion/')
  end 

  def suggestion
    suggestion_node.nil? ? nil : suggestion.attribute('q')
  end

  def first_text source_element, name
    elements = source_element.get_elements(name)
    if !elements.nil? 
      element = elements.first
      if !element.nil?
        if !element.text.nil?
          CGI.unescapeHTML(element.text)
        end
      end
    end
  end
end