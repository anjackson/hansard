class Hansard::DivisionBookmarks
  def initialize
    @bookmarks = []
  end

  def need_to_store?
    !empty?
  end

  def add_bookmark placeholder, node, section
    if placeholder
      # raise 'unexpected: ' + placeholder.division.votes.select {|v| v.is_a? AyeVote}.size.to_s + ' ' +
        # placeholder.division.votes.select {|v| v.is_a? AyeTellerVote}.size.to_s + ' ' +
        # placeholder.division.votes.select {|v| v.is_a? NoeVote}.size.to_s + ' ' +
        # placeholder.division.votes.select {|v| v.is_a? NoeTellerVote}.size.to_s + ' ' +
        # placeholder.division.votes.size.to_s + "\n" +
        # placeholder.division.votes.collect {|v| v.inspect}.join("\n")

      raise Hansard::DivisionParsingException, 'Expected a DivisionPlaceholder, but received: ' + placeholder.inspect unless placeholder.is_a?(DivisionPlaceholder)

      @bookmarks << Hansard::DivisionBookmark.new(placeholder, section)
    else
      raise Hansard::DivisionParsingException, 'Expected division placeholder for: ' + node.to_s
    end
  end

  def empty?
    @bookmarks.empty?
  end

  def clear
    @bookmarks.clear
  end

  def last_placeholder
    @bookmarks.last.placeholder
  end

  def have_a_complete_division? house_divided_text
    empty? ? false : last_placeholder.have_a_complete_division?(house_divided_text)
  end

  def last_division
    @bookmarks.last ? @bookmarks.last.division : nil
  end

  def division_text
    if @bookmarks.empty?
      ''
    elsif @bookmarks.size == 1
      @bookmarks.first.division_text
    elsif @bookmarks.size > 1
      text = @bookmarks.collect(&:division_text).join("\n")
      text = text.gsub(/<table[^>]*>/,'').gsub(/<\/table>/,'')
      text = "<table>" + text + "</table>"
      text
    end
  end

  def convert_to_unparsed_division_placeholders
    check_for_nil_sections

    @bookmarks.in_groups_by(&:section).each do |bookmarks|
      index_adj = 0
      bookmarks.sort_by(&:index_in_section).each do |bookmark|
        bookmark.convert_to_unparsed_division_placeholder(index_adj)
        index_adj = index_adj.next
      end
    end
  end

  def check_for_nil_sections
    @bookmarks.collect(&:section).each do |section|
      raise Hansard::DivisionParsingException, 'Unable to continue parsing, as division section not bookmarked' unless section
    end
  end
end

