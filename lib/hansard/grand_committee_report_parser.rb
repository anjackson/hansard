class Hansard::GrandCommitteeReportParser < Hansard::HouseParser

  include Hansard::LordsDivisionHandler

  def handle_grand_committee_report report, root
    report.section = create_section(Section)
    report.section.title = report.title
    get_date(report, root)
    past_title_element = false
    root.children.each do |node|
      if !past_title_element
        past_title_element = (node.elem? && node.name == 'title')
      else
        handle_section_element_children node, report.section
      end
    end
    report.section.end_column = @column
    report.end_column = @column
  end

  def get_date(report, root)
    return if report.date
    dates = root.search("p").select { |ele| ele.inner_text =~ /^ *?([^ ]*?) \d\d? ([^ ]*?) \d\d\d\d\.? *?/ }
    if dates
      date = Date.parse(dates.first.inner_html)
      report.section.date = date
      report.date = date
      report.date_text = dates.first.inner_html.gsub(/<\/?i>/,'').strip.chomp('.')
    end
  end
  
  def handle_child_element node, sitting
    case node.name
      when "section"
        handle_section node, sitting.debates
      when 'col', 'image'
        handle_image_or_column node
      when 'p'
        raise 'unexpected paragraph in grandcommitteereport section: ' + node.to_s
      else
        raise 'unexpected element inside grandcommitteereport element: ' + node.name + ' ' + node.to_s
    end if node.elem?

    raise_error_if_non_blank_text node
  end
end