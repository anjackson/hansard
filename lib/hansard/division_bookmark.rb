class Hansard::DivisionBookmark

  attr_reader :placeholder, :section, :index_in_section

  def initialize placeholder, section
    @placeholder, @section = placeholder, section
    @index_in_section = (section ? section.contributions.size : nil)
  end

  def division
    @placeholder.division
  end

  def division_text
    @placeholder.text
  end

  def convert_to_unparsed_division_placeholder index_adj
    unparsed_placeholder = UnparsedDivisionPlaceholder.new @placeholder.attributes
    unparsed_placeholder.section = @section
    index = @index_in_section + index_adj
    previous_contribution = @section.contributions[index-1]
    unparsed_placeholder.xml_id = previous_contribution.xml_id if previous_contribution
    @section.contributions.insert(index, unparsed_placeholder)
  end
end
