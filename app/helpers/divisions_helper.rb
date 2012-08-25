module DivisionsHelper

  def division_title division
    name = division.name ? division.name : 'Division'
    "#{division.section_title}—#{name}"
  end

  def one_division_section? divisions_by_section
    divisions_by_section.size == 1 && divisions_by_section[0].size > 0 &&
      divisions_by_section[0].collect(&:sub_section).compact.size == 0
  end

  def division_url division
    if division.number.nil? || division.number == '?'
      division_in_section_url division
    else
      section = division.sub_section ? division.sub_section : division.section
      "#{section_url(section)}/division_#{division.number}"
    end
  end

  def division_in_section_url division
    section = division.sub_section ? division.sub_section : division.section
    url = section_url(section)
    url += "##{division.anchor_id}"
    url
  end

  def link_to_division division
    label = division.number ? division.number : '?'
    link_to(label, division_url(division))
  end

  def link_to_divisions divisions
    divisions.collect{ |division| link_to_division(division) }.join(', ')
  end

  def format_division_section_title(division)
    if title = division.section_title
      if division.respond_to? :bill and division.bill
        link_to(title, bill_url(division.bill))
      else
        title
      end
    else
      ''
    end
  end
end
