
module Hansard
end

class Hansard::HouseCommonsParser < Hansard::HouseParser

  protected

    def handle_debates_child node, sitting
      if node.elem?
        name = node.name
        if name == "section"
          handle_section node, sitting.debates
        elsif name == "oralquestions"
          handle_oral_questions node, sitting.debates, sitting
        elsif (name == 'col' or name == 'image')
          handle_image_or_column name, node
        elsif (name == 'p')
          if node.inner_html.to_s == 'PRAYERS'
            handle_prayers_outside_section node, sitting.debates
          elsif node.inner_html.to_s == '[Mr. SPEAKER <i>in the Chair</i>]'
            # handled in handle_prayers_outside_section
          else
            raise 'unexpected paragraph in debates section: ' + node.to_s
          end
        else
          raise 'unknown debates section type: ' + name
        end
      elsif node.text?
        raise 'unexpected text outside of section: ' + node.to_s if node.to_s.strip.size > 0
      end
    end

    def handle_oral_questions section, debates, sitting
      still_in_oral_questions = true
      oral_questions = create_section(OralQuestions)

      section.children.each do |node|
        if still_in_oral_questions
          if node.elem?
            name = node.name
            if name == 'title'
              oral_questions.title = clean_html(node)
            elsif name == 'section'
              still_in_oral_questions, non_oral_question_nodes = handle_oral_questions_section(node, oral_questions, sitting)
              unless still_in_oral_questions
                oral_questions.parent_section = debates
                debates.sections << oral_questions
                non_oral_question_nodes = non_oral_question_nodes.collect do |n|
                  if n.is_a? Hpricot::Text
                    n.to_s.strip.size > 0 ? n : nil
                  else
                    n
                  end
                end.compact
                if non_oral_question_nodes.size > 0
                  non_oral_question_nodes.each do |non_question_node|
                    handle_debates_child non_question_node, sitting
                  end
                else
                  handle_debates_child node, sitting
                end
              end
            elsif (name == 'image' or name == 'col')
              handle_image_or_column name, node
            else
              log 'unexpected element in oral_questions: ' + name + ': ' + node.to_s
            end
          end
        else
          handle_debates_child node, sitting
        end
      end

      if still_in_oral_questions
        oral_questions.parent_section = debates
        debates.sections << oral_questions
      end
    end

    def handle_oral_questions_section section, oral_questions, sitting
      still_in_oral_questions = true
      non_oral_question_nodes = []
      questions_section = create_section(OralQuestionsSection)
      has_introduction = ((section/'p').size == 1)

      section.children.each do |node|
        if still_in_oral_questions
          if node.elem?
            name = node.name
            if name == 'title'
              title = clean_html(node)
              if is_orders_of_the_day?(title) || is_business_of_the_house?(title)
                still_in_oral_questions = false
                break
              end
              questions_section.title = title
            elsif name == 'section'
              still_in_oral_questions, other_non_oral_question_nodes = handle_oral_question_section node, questions_section
              unless still_in_oral_questions
                questions_section.parent_section = oral_questions
                oral_questions.sections << questions_section
                non_oral_question_nodes << node
              end
            elsif (name == 'col' or name == 'image')
              handle_image_or_column name, node
            elsif name == 'p'
              if has_introduction
                procedural = handle_procedural_contribution node, questions_section
                questions_section.introduction = procedural
              else
                handle_question_contribution node, questions_section
              end
            else
              log 'unexpected element in oral_questions_section: ' + name + ': ' + node.to_s
            end
          else
            non_oral_question_nodes << node
          end
        end
      end

      if still_in_oral_questions
        questions_section.parent_section = oral_questions
        oral_questions.sections << questions_section
      end
      return still_in_oral_questions, non_oral_question_nodes
    end

    def handle_oral_question_section section, questions
      still_in_oral_questions = true
      question_section = create_section(OralQuestionSection)

      section.children.each do |node|
        if still_in_oral_questions
          if node.elem?
            name = node.name
            if name == 'title'
              title = clean_html(node)
              if is_business_of_the_house?(title)
                still_in_oral_questions = false
                break
              end
              question_section.title = title
            elsif name == 'p'
              inner_html = clean_html(node).strip
              if inner_html.starts_with?('<table>') && inner_html.ends_with?('</table>')
                handle_table_element node, question_section
              else
                handle_question_contribution node, question_section
              end
            elsif (name == 'col' or name == 'image')
              handle_image_or_column name, node
            elsif name == 'section'
              still_in_oral_questions = handle_oral_question_section(node, question_section)
              unless still_in_oral_questions
                question_section.parent_section = questions
                questions.questions << question_section
              end
            elsif name == 'table'
              handle_table_element node, question_section
            else
              log 'unexpected element in oral_question_section: ' + name + ': ' + node.to_s
            end
          end
        end
      end

      if still_in_oral_questions
        question_section.parent_section = questions
        questions.questions << question_section
      end
      return still_in_oral_questions
    end

end
