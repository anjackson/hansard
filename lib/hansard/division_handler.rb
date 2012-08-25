module Hansard
end

class Hansard::DivisionHandler

  def initialize
    @division_bookmarks = Hansard::DivisionBookmarks.new
    @house_divided_text = []
    @division_result = nil # a procedural contribution
    @placeholder_following_divided_text = nil
    @house_divided = false
  end

  def last_division
    @division_bookmarks.last_division
  end

  def first_house_divided_text
    @house_divided_text.first
  end

  def delete_first_house_divided_text
    @house_divided_text.delete(first_house_divided_text)
  end

  def division_text
    @division_bookmarks.division_text
  end

  def add_division_result section, procedural
    if @division_bookmarks.empty?
      section.contributions << procedural
    else
      @division_result = procedural
    end
  end

  def reset_house_divided_text placeholder
    division_list_number = division_list_number_from_divided_text(first_house_divided_text)
    placeholder.division_name = division_list_number if division_list_number
    delete_first_house_divided_text
  end

  def populate_last_division
    unless @division_bookmarks.empty?
      if @placeholder_following_divided_text
        proceed_with_populate_last_division
      else
        @division_bookmarks.convert_to_unparsed_division_placeholders
        raise Hansard::DivisionParsingException, "Don't know where to place division, division is: #{division_text.gsub(/<[^>]+>/,'')[0..40]}..."
      end
    end
  end

  def proceed_with_populate_last_division
    text = @division_result ? "#{division_text}\n<p>#{@division_result.text}</p>" : division_text
    @placeholder_following_divided_text.text = text
    @division_bookmarks.clear
    @division_result = nil
    reset_house_divided_text @placeholder_following_divided_text
    @placeholder_following_divided_text = nil
  end

  def handle_division node, section, placeholder, is_new_division
    populate_last_division if is_new_division

    if placeholder && @house_divided
      set_placeholder_following_divided_text placeholder, section
      @house_divided = false
    end

    if placeholder.have_a_complete_division? first_house_divided_text

      if @division_bookmarks.need_to_store?
        @division_bookmarks.add_bookmark placeholder, node, section
      else
        reset_house_divided_text placeholder
      end
    else
      @division_bookmarks.add_bookmark placeholder, node, section
    end
  end

  def set_placeholder_following_divided_text placeholder, section
    placeholder.division.xml_id = section.contributions.last.xml_id if !section.contributions.empty?
    section.add_contribution placeholder    
    @placeholder_following_divided_text = placeholder
  end

  def add_division_after_divided_text section, procedural
    procedural.section = section
    section.contributions << procedural
    @house_divided = true

    @house_divided_text << procedural.text
    if @division_bookmarks.have_a_complete_division?(first_house_divided_text)
      set_placeholder_following_divided_text @division_bookmarks.last_placeholder, section
      populate_last_division
      @house_divided = false if @house_divided_text.empty?
    end
  end

  NUMBER_IN_DIVIDED_TEXT = regexp '(Division List No\.? ?\d+\.?)', 'i' unless defined?(NUMBER_IN_DIVIDED_TEXT)

  def division_list_number_from_divided_text text
    return nil unless text
    if NUMBER_IN_DIVIDED_TEXT.match(text)
      $1
    else
      nil
    end
  end
end
