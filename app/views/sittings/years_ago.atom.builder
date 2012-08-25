atom_feed do |feed|
  feed.title("HANSARD 1803&ndash;2005 - #{@years} years ago today", :type => 'html')
  feed.updated((Time.now))
  for section, date, content in @items
    feed.entry(section, :url => section_url(section), :updated => date, :published => section.date) do |entry|
      entry.title("#{section.title_via_associations}, #{resolution_title(section.sitting.class, section.date, :day)}", :type => 'html')
      entry.content(content, :type => 'html')
      entry.author do |author|
        author.name("Millbank Systems")
      end
    end
  end
end