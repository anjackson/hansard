module Hansard
end

class Hansard::WestminsterHallParser < Hansard::CommonsParser

  include Hansard::CommonsDivisionHandler

  def handle_child_element node, sitting
    case node.name
      when "section"
        handle_section node, sitting.debates
      when 'col', 'image'
        handle_image_or_column node
      when "oralquestions"
        handle_oral_questions node, sitting.debates, sitting
      else
        raise 'unexpected element inside westminsterhall element: ' + node.name + ' ' + node.to_s
    end if node.elem?

    raise_error_if_non_blank_text node
  end
end