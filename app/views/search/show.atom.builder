atom_feed('xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/') do |feed|
  feed.title("HANSARD 1803&ndash;2005 Search Results", :type => 'html')
  feed.updated((Time.now))
  feed.openSearch(:totalResults, @paginator.total_entries)
  feed.openSearch(:startIndex, @paginator.offset+1)
  feed.openSearch(:itemsPerPage, @paginator.per_page)
  feed.openSearch(:Query, :role => 'request', :searchTerms => @search.query, :startPage => @paginator.current_page)
  
  atom_link(feed, 'first', first_results_url)
  atom_link(feed, 'previous',  previous_results_url(@paginator)) if @paginator.current_page > 1
  atom_link(feed, 'next',  next_results_url(@paginator)) if @paginator.current_page < @paginator.total_pages
  atom_link(feed, 'last', last_results_url(@paginator))
  
  feed.link(:rel => 'search', :href => "http://#{request.host_with_port}/search.xml", :type => 'application/opensearchdescription+xml')  
  
  for result in @search.get_results
    feed.entry(result, :url => section_contribution_url(result, result.section), :updated => Time.now, :published => result.date) do |entry|
      entry.title(result.title_via_associations, :type => 'html')
      entry.content(hit_fragment(result, @search), :type => 'html')
      entry.author do |author|
        author.name("Millbank Systems")
      end
    end
  end
end