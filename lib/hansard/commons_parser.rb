require File.dirname(__FILE__) + '/commons_division_handler.rb'

module Hansard; end

class Hansard::CommonsParser < Hansard::HouseParser

  include Hansard::CommonsDivisionHandler

  def handle_child_element node, sitting
    case node.name
      when "section"
        handle_section node, sitting.debates
      when "oralquestions"
        handle_oral_questions node, sitting.debates, sitting
      when 'col', 'image'
        handle_image_or_column node
      when 'p'
        raise 'unexpected paragraph in debates section: ' + node.to_s
      else
        raise 'unknown debates section type: ' + node.name
    end if node.elem?

    raise_error_if_non_blank_text node
  end

  COMMONS_HOUSE_DIVIDED = regexp('((<i>)?the\s+(committee|house)[s]?\s+(having\s)?divided(</i>)?.+)$', 'i')
  def handle_divided_text_in_member_contribution contribution, section
    if (divided_text = COMMONS_HOUSE_DIVIDED.match(contribution.text))
      contribution.text = contribution.text.sub(divided_text[1],'').strip.chomp('<lb/>')
      divided_contribution = create_house_divided_contribution(divided_text[1].chomp('<lb/>') )
      add_division_after_divided_text section, divided_contribution
    end
  end

  def is_house_met_text? text
    !text.downcase[/\Athe house met/].nil?
  end

  def handle_oral_questions section, debates, sitting
    still_in_oral_questions = true
    oral_questions = create_section(OralQuestions)

    section.children.each do |node|
      if still_in_oral_questions
        case node.name
          when 'title'
            oral_questions.title = clean_html(node)
          when 'section'
            still_in_oral_questions, non_oral_question_nodes = handle_oral_questions_section(node, oral_questions, sitting)
            unless still_in_oral_questions
              debates.add_section oral_questions
              non_oral_question_nodes = non_oral_question_nodes.collect do |n|
                if n.is_a? Hpricot::Text
                  n.to_s.strip.size > 0 ? n : nil
                else
                  n
                end
              end.compact
              if non_oral_question_nodes.size > 0
                non_oral_question_nodes.each do |non_question_node|
                  handle_child_element non_question_node, sitting
                end
              else
                handle_child_element node, sitting
              end
            end
          when 'col', 'image'
            handle_image_or_column node
          when 'division'
            handle_division(node, nil)
          else
            log 'unexpected element in oral_questions: ' + node.name + ': ' + node.to_s
        end if node.elem?
      else
        handle_child_element node, sitting
      end
    end

    if still_in_oral_questions
      oral_questions.end_column = @column
      debates.add_section oral_questions
    end
  end

  def handle_oral_questions_section section, oral_questions, sitting
    still_in_oral_questions = true
    non_oral_question_nodes = []
    questions_section = create_section(OralQuestionsSection)
    has_introduction = ((section/'p').size == 1) && !((section.at('membercontribution')))

    section.children.each do |node|
      case node.name
        
        when 'title'
          title = clean_html(node)
          if is_orders_of_the_day?(title) || is_business_of_the_house?(title)
            still_in_oral_questions = false
            break
          end
          questions_section.title = title
        when 'section'
          still_in_oral_questions, other_non_oral_question_nodes = handle_oral_question_section node, questions_section
          unless still_in_oral_questions
            oral_questions.add_section questions_section
            non_oral_question_nodes << node
          end
        when 'col', 'image'
          handle_image_or_column node
        when 'p'
          if has_introduction
            procedural = handle_procedural_contribution node, questions_section
            questions_section.introduction = procedural
          else
            handle_question_contribution node, questions_section
          end
        when 'division'
          handle_division(node, questions_section)
        else
          log 'unexpected element in oral_questions_section: ' + node.name + ': ' + node.to_s
      end if still_in_oral_questions && node.elem?

      non_oral_question_nodes << node if still_in_oral_questions && !node.elem?
    end

    if still_in_oral_questions
      questions_section.end_column = @column
      oral_questions.add_section questions_section
    end
    return still_in_oral_questions, non_oral_question_nodes
  end

  def handle_oral_question_section section, questions
    still_in_oral_questions = true
    question_section = create_section(OralQuestionSection)

    section.children.each do |node|
      case node.name
        when 'title'
          title = clean_html(node)
          if is_business_of_the_house?(title)
            still_in_oral_questions = false
            break
          end
          question_section.title = title
        when 'p'
          inner_html = clean_html(node).strip
          if inner_html.starts_with?('<table') && inner_html.ends_with?('</table>')
            handle_table_or_division node.at('table'), question_section, node.attributes['id']
          else
            handle_question_contribution node, question_section
          end
        when 'quote'
          handle_question_contribution node, question_section
        when 'col', 'image'
          handle_image_or_column node
        when 'section'
          still_in_oral_questions = handle_oral_question_section(node, question_section)
          unless still_in_oral_questions
            question_section.parent_section = questions
            questions.questions << question_section
          end
        when 'table'
          handle_table_or_division node, question_section
        when 'division'
          handle_division(node, question_section)
        else
          log 'unexpected element in oral_question_section: ' + node.name + ': ' + node.to_s
      end if still_in_oral_questions && node.elem?
    end

    if still_in_oral_questions
      question_section.end_column = @column
      question_section.parent_section = questions
      questions.questions << question_section
    end
    return still_in_oral_questions
  end
end
