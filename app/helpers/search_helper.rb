module SearchHelper
  
  def hit_fragment(result_set, contribution)
    fragment = result_set.highlights[contribution.id]["text"].join("...")
    format_result_fragment(fragment) 
  end
  
  def format_result_fragment(fragment)
    # unescape any full html entities
    fragment = CGI::unescapeHTML(fragment)
    leading_punctuation = /^(\/|\\|;|\.|,|\(|\)|:)/
    leading_tag_closure = /^[^<]*?>/
    problems = [leading_punctuation, leading_tag_closure]
    problems.each do |problem|
      fragment.gsub!(problem, '')
    end
    fragment
  end

  def member_facets(result_set)
    if result_set.facets and !result_set.facets["facet_fields"].empty?
      member_facets = result_set.facets["facet_fields"]["member_facet"]
      member_facets = select_positive_values(member_facets)
      member_facets = sort_by_reverse_value_then_key(member_facets)
      yield member_facets
    end
  end

  def select_positive_values(hash)
    hash.select{ |key,value| value > 0 }
  end
  
  def sort_by_reverse_value_then_key(hash)
    # sorts by score from high to low and then by name from a to z
    hash.sort{ |a,b| [b[1], a[0].downcase] <=> [a[1], b[0].downcase] }.collect
  end
  
  def hit_link(contribution)
    link_text = contribution.section.title || contribution.section.sitting.title
    url = section_url(contribution.section) + "##{contribution.xml_id}"
    link_to link_text, url
  end
  
  def member_facet_link(member, times, query)
    link = ''
    if times > 1
      link = "<span style='font-size: #{1 + 0.05 * times.to_f }em'>"
      link += link_to "<strong>#{times}, #{format_member_name(member)}</strong>", member_facet_url(member, query)
      link += '</span>'
    else 
      link = link_to format_member_name(member), member_facet_url(member, query)
    end
    link
  end
  
  def member_facet_url(member, query)
    {:controller => "search", 
     :action     => "index", 
     :member     => member, 
     :query      => query,
     :page       => nil}
  end
  
  def search_results_title(member, query)
    title = "Search: <code>#{query}</code>"
    title += " spoken by #{format_member_name(member)}" if member
    title
  end
  
  def search_results_summary(result_set, query)
    text = ''
    if result_set.results.empty?
      text += "<h3>No results found for <code>#{query}</code>.</h3>"
      text += "<p>Try your search on more recent Parliament information?</p>"
      text += google_custom_search_form(query) 
    else
      start = ((@page - 1) * @num_per_page) + 1
      finish = start + (@num_per_page - 1)
      finish = result_set.total_hits if finish > result_set.total_hits
      text += "<h3>Results #{start} to #{finish} of #{result_set.total_hits}</h3>"
    end
    text
  end
  
  def format_member_name(name)
    CGI::unescapeHTML(name)
  end
  
end