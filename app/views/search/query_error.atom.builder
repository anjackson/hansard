atom_feed('xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/') do |feed|
  feed.title("HANSARD 1803&ndash;2005 Search Results - Error", :type => 'html')
  feed.updated((Time.now))
  feed.openSearch(:totalResults, 1)
  feed.openSearch(:startIndex, 1)
  feed.openSearch(:itemsPerPage, 1)
  feed.entry('', :url => '', :updated => Time.now, :published => Time.now) do |entry|
    entry.title('Search Error')
    entry.content("We couldn't help with the search you were trying. There's a problem with our search engine.", :type => 'html')
    entry.author do |author|
      author.name("Millbank Systems")
    end
  end
end