require 'rubygems'
require 'open-uri'
require 'hpricot'

# ruby script/generate rspec_model sitting      type:string date:date title:string date_text:string column:string text:text
# ruby script/generate rspec_model section      type:string title:string time:time time_text:string column:string
# ruby script/generate rspec_model contribution type:string xml_id:string member:string memberconstituency:string membercontribution:string column:string oral_question_no:string

module Hansard
end

class Hansard::HouseCommonsParser

  def initialize file
    @doc = Hpricot.XML open(file)
  end

  def parse
    type = @doc.children[0].name

    if type == 'housecommons'
      create_house_commons
    else
      raise 'cannot create sitting, unrecognized type: ' + type
    end
  end

  private

    def handle_section section, debates
      procedural = ProceduralSection.new
      procedural.column = @column

      section.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'title'
            procedural.title = child.inner_html
          elsif name == 'p'
            procedural.xml_id = child.attributes['id']
            procedural.text = child.to_s
          elsif name == 'col'
            @column = child.inner_html
          else
            
          end
        end
      end

      procedural.parent_section = debates
      debates.sections << procedural
    end

    # <p id="S6CV0089P0-00362">1. <member>Mr. Douglas</member><membercontribution> asked the Secretary of State for Energy if he will make a statement on visits by Ministers in his Department to pits in the Scottish coalfield.</membercontribution></p>
    def handle_question_contribution element, question_section
      contribution = question_section.contributions.create({
         :xml_id => element.attributes['id'],
         :column => @column
      })

      contribution.section = question_section
      
      element.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'member'
            contribution.member = child.inner_html
          elsif name == 'membercontribution'
            contribution.text = child.inner_html
          end

        elsif child.text?
          text = child.to_s.strip
          if (match = /^(\d+.)/.match text)
            contribution.oral_question_no = match[1]
          elsif text.size > 0
            raise 'unexpected text: ' + text
          end
        end
      end
    end

    def handle_oral_question_section section, questions
      question_section = OralQuestionSection.new
      
      section.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'title'
            question_section.title = child.inner_html
          elsif name == 'p'
            handle_question_contribution child, question_section
          end
        end
      end

      question_section.parent_section = questions
      questions.questions << question_section
    end

    def handle_oral_questions_section section, oral_questions
      questions_section = OralQuestionsSection.new

      section.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'title'
            questions_section.title = child.inner_html
          elsif name == 'section'
            handle_oral_question_section child, questions_section
          end
        end
      end

      questions_section.parent_section = oral_questions
      oral_questions.sections << questions_section      
    end

    def handle_oral_questions section, debates
      oral_questions = OralQuestions.new
      
      section.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'title'
            oral_questions.title = child.inner_html
          elsif name == 'section'
            handle_oral_questions_section child, oral_questions
          elsif name == 'col'
            @column = child.inner_html
          else
            
          end
        end
      end

      oral_questions.parent_section = debates
      debates.sections << oral_questions
    end
    
    def handle_image
      
    end

    def handle_debates sitting, debates
      sitting.debates = DebatesSection.new
      debates.children.each do |child|
        if child.elem?
          name = child.name
          if name == "section"
            handle_section child, sitting.debates
          elsif name == "oralquestions"
            handle_oral_questions child, sitting.debates
          elsif name == "image"
            handle_image
          elsif name == "col"
            @column = child.inner_html
          else
            raise 'unknown debates section type: ' + name
          end
        elsif child.text?          
          raise 'unexpected text outside of section: ' + child.to_s if child.to_s.strip.size > 0 
        end
      end
    end

    def create_house_commons
      @column = @doc.at('housecommons/col').inner_html

      sitting = HouseOfCommonsSitting.new({
        :column => @column,
        :title => @doc.at('housecommons/title').inner_html,
        :text => @doc.at('housecommons/p').inner_html,
        :date_text => @doc.at('housecommons/date').inner_html,
        :date => @doc.at('housecommons/date').attributes['format']
      })

      if (texts = (@doc/'housecommons/p'))
        sitting.text = ''
        texts.each do |text|
          sitting.text += text.to_s
        end
      end

      if (debates = @doc.at('housecommons/debates'))
        handle_debates sitting, debates
      end

      sitting
    end
  
end
