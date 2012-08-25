require File.dirname(__FILE__) + '/lords_division_handler.rb'

module Hansard; end

class Hansard::LordsParser < Hansard::HouseParser

  include Hansard::LordsDivisionHandler

  def handle_child_element node, sitting
    case node.name
      when "section"
        handle_section node, sitting.debates
      when 'col', 'image'
        handle_image_or_column node
      when 'p'
        raise 'unexpected paragraph in debates section: ' + node.to_s
      else
        raise 'unexpected element under debates element: ' + node.name
    end if node.elem?

    raise_error_if_non_blank_text node
  end

  LORDS_HOUSE_DIVIDED = regexp('((<i>)?their\s+(lordships)[s]?\s+(having\s)?divided(</i>)?.+)$', 'i')

  def handle_divided_text_in_member_contribution contribution, section
    if (divided_text = LORDS_HOUSE_DIVIDED.match(contribution.text))
      contribution.text = contribution.text.sub(divided_text[1],'').strip.chomp('<lb/>')
      divided_contribution = create_house_divided_contribution(divided_text[1].chomp('<lb/>') )
      add_division_after_divided_text section, divided_contribution
    end
  end

end
