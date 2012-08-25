require 'rexml/document'
require 'rexml/sax2listener'

module Hansard
end

class Hansard::Transformer2
  include REXML
  include REXML::SAX2Listener

  attr_reader :document

  UNWANTED_TAGS = ['b','Question','QuestionText','Number','Uin','Fragment',
    'hs_6bDepartment', 'TwoColumn', 'NamesAyes', 'NamesNoes', 'TellerNamesAyes', 'TellerNamesNoes',
    'Body','System','HansardDoc'].inject({}) {|hash, tag| hash[tag]=true; hash} unless defined?(UNWANTED_TAGS)

  IGNORE_ELEMENTS = ['Header', 'ignore',
    'TableWrapper'].inject({}) {|hash, tag| hash[tag]=true; hash} unless defined?(IGNORE_ELEMENTS)

  def initialize
    @document = REXML::Document.new
    @last_tag = nil
    @last_popped_element = nil
    @hold_title_while_in_column = nil
    @elements = [@document]
    @ignore = false
    @in_member_contribution = false
    @in_division = false
    @division = nil
    @created_debates_element = false
    @last_class = false
    @house_divided_paragraph = false
  end

  def tag_start(tag, attributes)
    @last_tag = tag
    @ignore = ignore_element?(tag) unless @ignore

    if want_tag? tag
      mark_if_in_member_contribution tag
      hold_title_while_in_column if col_element_inside_title_element(tag)
      add_new_line if need_new_line(tag)
      element = add_element tag, attributes
      mark_if_in_division tag, element
    end
  end

  def text text
    unless @ignore
      text = strip_line_breaks(text)
      add_section_element if hit_new_section_title(text)
      mark_if_house_divided_paragraph(text)
      @elements.last.add_text(' ') if is_question_text(text)
      @elements.last.add_text(text.gsub('&',''))
    end
  end

  def tag_end tag
    pop_member_contribution if end_of_member_contribution(tag)

    moved = (tag == 'quote') ? move_quote_to_preceding_paragraph : false
    moved = (tag == 'p') ? move_paragraph_to_preceding_contribution : false unless moved
    moved = (tag == 'p' && @house_divided_paragraph) ? move_house_divided_outside_of_division : false unless moved

    if (tag == 'division')
      result_paragraph = nil

      if @elements.last.name == 'table'
        table = pop_element
        last = table.children.delete_if {|c| c.class != REXML::Element}.last
        if last && last.name == 'p'
          result_paragraph = last
          table.delete_element result_paragraph
        end
      end

      if @elements.last.name == 'division'
        division = pop_element
        if result_paragraph
          result_paragraph.parent = division.parent
          division.parent.add_element result_paragraph
        end
      end
      @in_division = false
      @division = nil
      moved = true
    end

    unless moved
      pop_element if want_tag?(tag)
      add_title_held_while_in_column if col_element_was_in_title_element(tag)
      add_member_contribution_element if (tag == 'member' && @in_member_contribution)
    end

    @ignore = false if ignore_element?(tag)
  end

  def instruction x, y
    # do nothing
  end

  private

  def want_tag? tag
    wanted = !@ignore && !UNWANTED_TAGS.has_key?(tag)

    if wanted
      italic_in_date = (tag == 'i' && @elements.last.name == 'date')
      wanted = false if italic_in_date
    end
    wanted
  end

  def ignore_element? tag
    IGNORE_ELEMENTS.has_key? tag
  end

  def pop_element
    @last_popped_element = @elements.pop
    @last_popped_element
  end

  def pop_and_remove_element
    element = pop_element
    element.parent.delete_element element
    element
  end

  def back_to tag_list
    while @elements.last and not(tag_list.include?(@elements.last.name))
      pop_element
    end
  end

  def add_element tag, attributes={}
    parent = @elements.last
    begin
      element = Element.new(tag, parent, {:raw => :all})
      element.add_attribute 'format', attributes['format'] if attributes.has_key? 'format'
      element.add_attribute 'align', attributes['align'] if attributes.has_key? 'align'
      element.add_attribute 'colspan', attributes['colspan'] if attributes.has_key? 'colspan'
      element.add_attribute 'id', attributes['uid'] if (attributes.has_key?('uid') && tag == 'p')
      if attributes.has_key?('class')
        @last_class = attributes['class']
        element.add_attribute 'class', attributes['class'] if (tag == 'span')
      end
    rescue Exception => e
      puts 'element: ' + tag
      raise e
    end
    @elements << element
    element
  end

  def col_element_inside_title_element tag
    tag == 'col' && @elements.last.name == 'title'
  end

  def col_element_was_in_title_element(tag)
    tag == 'col' && @hold_title_while_in_column
  end

  def hold_title_while_in_column
    @hold_title_while_in_column = pop_and_remove_element
  end

  def add_title_held_while_in_column
    @elements.last.add_element @hold_title_while_in_column
    @elements << @hold_title_while_in_column
    @hold_title_while_in_column = nil
  end

  def hit_new_section_title text
    if @elements.last.name == 'title'
      if (text == 'Prayers' || text == 'House of Commons' || text.blank?)
        false
      else
        true
      end
    else
      false
    end
  end

  def pop_member_contribution
    pop_element
    @in_member_contribution = false
  end

  def end_of_member_contribution tag
    (tag == 'p' && @in_member_contribution)
  end

  def clean text
    text.gsub("\n",' ').gsub("\r",' ').squeeze(' ')
  end

  def mark_if_house_divided_paragraph text
    if (@in_division && clean(text) =~ /The House divided/i)
      text.gsub!("\n",' ')
      text.gsub!("\r",' ')
      text.squeeze!(' ')
      @house_divided_paragraph = true
    end
  end

  def mark_if_in_member_contribution tag
    @in_member_contribution = true if (tag == 'member' && !@in_division)
  end

  def mark_if_in_division tag, element
    if (tag == 'division')
      @in_division = true
      @division = element
      add_new_line
      add_element 'table' # put rest of division in table
      add_new_line
    end
  end

  def is_question_text text
    @last_tag == 'QuestionText' && !text.blank?
  end

  def add_new_line
    @elements.last.add_text("\n")
  end

  def need_new_line tag
    (tag == 'p' || tag == 'title' || tag == 'date' || tag == 'date')
  end

  def strip_line_breaks text
    if text.blank?
      text
    elsif (@elements.last.name == 'title')
      text.gsub("\n",' ').gsub("\r",' ').squeeze(' ').strip
    else
      text.gsub("\r",' ')
    end
  end

  def add_member_contribution_element
    add_element 'membercontribution'
  end

  def add_oral_questions_element
    add_element 'oralquestions'
  end

  def last_class
    @last_class
  end

  def find_preceding
    preceding_paragraph = column = nil
    previous_element = @elements.last ? @elements.last.previous_element : nil

    if previous_element
      if previous_element.name == 'p'
        preceding_paragraph = previous_element
      elsif previous_element.name == 'col'
        column = previous_element
        if column.previous_element.name == 'p'
          preceding_paragraph = column.previous_element
        end
      end
    end

    return preceding_paragraph, column
  end

  def move_column_to_preceding_element column, preceding_element
    column.parent.delete_element column
    column.parent = preceding_element
    preceding_element.add_element column
  end

  def move_paragraph_to_preceding_contribution
    paragraph_is_new_member_contribution = @elements.last.elements['membercontribution']
    moved = false
    unless (@in_division || paragraph_is_new_member_contribution)
      preceding_paragraph, column = find_preceding

      if preceding_paragraph && (contribution = preceding_paragraph.elements['membercontribution'])
        move_column_to_preceding_element(column, contribution) if column
        line_break_element = Element.new('lb', contribution, {:raw => :all})

        paragraph = pop_and_remove_element
        paragraph.children.each do |node|
          node.parent = contribution
          if node.class == REXML::Element
            contribution.add_element node
          elsif node.class == REXML::Text
            contribution.add_text node
          end
        end
        moved = true
      end
    end

    moved
  end

  def pop_table_cell
    pop_element
  end

  def convert_to_table_cell text
    paragraph = pop_and_remove_element
    add_element 'tr'
    add_element 'td'
  end

  def move_house_divided_outside_of_division
    house_divided = pop_and_remove_element

    parent = @division.parent # remove division element
    parent.delete_element @division

    house_divided.parent = parent
    parent.add_element house_divided # add house divided paragraph
    parent.add_element @division # add back division element

    @house_divided_paragraph = false
    true
  end

  def move_quote_to_preceding_paragraph
    preceding_paragraph, column = find_preceding

    if preceding_paragraph
      contribution = preceding_paragraph.elements['membercontribution']
      parent = contribution ? contribution : preceding_paragraph

      move_column_to_preceding_element(column, parent) if column
      parent.add_text ' '

      quote = pop_and_remove_element
      quote.parent = parent
      parent.add_element quote
      true
    else
      false
    end
  end

  def add_section_element
    title = pop_and_remove_element

    unless @created_debates_element
      add_new_line
      add_element 'debates' # add debates wrapper
      @created_debates_element = true
    end

    if @elements.last.name == 'section'
      pop_element # pop previous section
    end

    add_new_line

    if last_class == 'hs_3OralAnswers'
      add_oral_questions_element
      add_new_line
    end
    if last_class == 'hs_2cStatement'
      if @elements.last.name == 'oralquestions'
        pop_element # pop oralquestions element
      end
    end

    add_element 'section'
    add_new_line
    @elements.last.add_element title
    @elements << title
  end

end