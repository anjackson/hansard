module SearchHelper


  def link_for interval, resolution, counts, options
    if counts.sum > 0
      link_to interval.to_s, {:controller => "search",
                              :action     => "show",
                              :query      => @query,
                              :decade     => interval}
    else
      interval
    end
  end

  def sort_link(current_sort)
    # if current_sort == "date"
    #       params.delete(:sort)
    #       link_to "<p><button id='sort_by_frequency'>Sort results by frequency</button></p>", params
    #     else
    #       link_to "<p><button id='sort_by_date'>Sort results by date</button></p>", params.merge(:sort => "date")
    #     end
  end

  def hit_fragment(result_set, contribution)
    if result_set.highlights[contribution.id]["text"]
      fragment = result_set.highlights[contribution.id]["text"].join << " &hellip;"
    else
      fragment = ''
    end
    format_result_fragment(fragment)
  end

  def format_result_fragment(fragment)
    # unescape any full html entities
    fragment = CGI::unescapeHTML(fragment)
    leading_punctuation = /^(\/|\\|;|\.|,|\(|\)|:)/
    problems = [leading_punctuation]
    problems.each do |problem|
      fragment.gsub!(problem, '')
    end
    fragment
  end

  def member_name_facets(result_set)
    if result_set.facets and !result_set.facets["facet_fields"].empty?
      member_name_facets = result_set.facets["facet_fields"]["member_name_facet"]
      member_name_facets = sort_by_reverse_value_then_key(member_name_facets)
      yield member_name_facets
    end
  end

  def date_facets(result_set)
    return false if !result_set.facets
    return false if result_set.facets["facet_fields"].nil?
    return false if result_set.facets["facet_fields"].empty?
    return false if result_set.facets["facet_fields"]["date_facet"].nil?
    return false if result_set.facets["facet_fields"]["date_facet"].empty?
    return result_set.facets["facet_fields"]["date_facet"]
  end

  def date_timeline(result_set)
    return nil if !date_facets(result_set)
    options = { :num_years => 200,
                :first_of_month => false }
    timeline(Date.new(2004, 12, 31), :century, options) do |start_date, end_date|
      date_facet_hash(result_set, start_date, end_date)
    end
  end

  def date_facet_hash(result_set, start_date, end_date)
    date_facets = date_facets(result_set)
    date_facets = date_facets.collect{|date_string, count| [ Date.parse(date_string), count] }
    facet_hash = {}
    date_facets.each{ |k,v| facet_hash[k] = v }
    facet_hash
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

  def member_name_facet_link(member, times, query)
    if times > 1
      link_to "<strong>" << times.to_s << "</strong> " << format_member_name(member), member_name_facet_url(member, query)
    else
      link_to format_member_name(member), member_name_facet_url(member, query)
    end
  end

  def member_name_facet_url(member, query)
    {:controller => "search",
     :action     => "show",
     :member     => member,
     :query      => query,
     :page       => nil}
  end

  def search_results_title(member_name, decade, query)
    title = "Search: '#{query}'"
    title += " spoken by #{link_to_member_from_name(format_member_name(member_name))}" if member_name
    title += " in the #{decade}" if decade
    title
  end

  def search_results_summary(result_set, query)
    text = ''

    if result_set.results.empty?
      text += "<h3>No results found for <em>#{query}</em>.</h3>"
      text += "<p>Try your search on more recent Parliament information?</p>"
      text += google_custom_search_form(query)
    else
       if result_set.total_hits <= @num_per_page
          text += "<h3>#{result_set.total_hits} results</h3>"
        else
      start = ((@page - 1) * @num_per_page) + 1
      finish = start + (@num_per_page - 1)
      finish = result_set.total_hits if finish > result_set.total_hits
      text += "<h3>Results #{start} to #{finish} of #{result_set.total_hits}</h3>"
    end
    end

    text
  end

  def format_member_name(name)
    CGI::unescapeHTML(name)
  end

end