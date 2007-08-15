require 'rubygems'
require 'open-uri'
require 'hpricot'

# ruby script/generate rspec_model sitting      type:string date:date title:string date_text:string column:string text:text
# ruby script/generate rspec_model section      type:string title:string time:time time_text:string column:string
# ruby script/generate rspec_model contribution type:string xml_id:string member:string memberconstituency:string membercontribution:string column:string oral_question_no:string

module Hansard
  TIME_PATTERN = /^(\d\d?(\.|&#x00B7;)\d\d (am|pm))$/
end

class Hansard::HouseCommonsParser

  def initialize file
    @unexpected = false
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

    def handle_non_procedural_section section, debates
      debate = DebatesSection.new
      debate.column = @column

      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            debate.title = node.inner_html
          elsif name == 'p'
            if (match = Hansard::TIME_PATTERN.match node.inner_html)
              debate.time_text = match[0]
              debate.time = Time.parse(match[0].gsub('.',':'))
              handle_procedural_contribution node, debate
            else
              handle_member_contribution node, debate
            end
          end
        end
      end

      debate.parent_section = debates
      debates.sections << debate
    end

    
    def handle_contribution_text element, contribution
      element.children.each do |node|
        if node.elem?
          if node.name == 'col'
            @column = node.inner_html
            contribution.column += ','+@column
          end
        end
      end
      contribution.text = element.inner_html.gsub("\r\n","\n")
    end

    
    def handle_member_contribution element, debate
      contribution = MemberContribution.new({
         :xml_id => element.attributes['id'],
         :column => @column
      })
      
      element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'member'
            contribution.member = node.inner_html
          elsif name == 'membercontribution'
            handle_contribution_text node, contribution
          else
            unless @unexpected
              puts 'unexpected element: ' + name + ': ' + node.to_s
              puts 'will suppress rest of unexpected messages'
            end
            @unexpected = true
          end
        end
      end
      contribution.section = debate
      debate.contributions << contribution
    end

    def handle_procedural_contribution node, debate
      procedural = ProceduralContribution.new({
        :xml_id => node.attributes['id'],
        :column => @column,
        :text => node.inner_html
      })
      procedural.section = debate
      debate.contributions << procedural
    end

    def handle_procedural_section section, debates
      procedural = ProceduralSection.new
      procedural.column = @column

      procedural.contributions
      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            procedural.title = node.inner_html
          elsif name == 'p'
            handle_procedural_contribution node, procedural
          elsif name == 'col'
            @column = node.inner_html
          else
            
          end
        end
      end

      procedural.parent_section = debates
      debates.sections << procedural
    end

    def handle_question_contribution element, question_section
      contribution = question_section.contributions.create({
         :xml_id => element.attributes['id'],
         :column => @column
      })

      contribution.section = question_section
      
      element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'member'
            contribution.member = node.inner_html
          elsif name == 'membercontribution'
            contribution.text = node.inner_html.chars.gsub("\r\n","\n")
          else
            raise 'unexpected element: ' + name + ': ' + node.to_s
          end

        elsif node.text?
          text = node.to_s.strip
          if (match = /^(\d+.)/.match text)
            contribution.oral_question_no = match[1]
          elsif text.size > 0
            unless @unexpected
              puts 'unexpected text: ' + text
              puts 'will suppress rest of unexpected messages'
            end
            @unexpected = true
          end
        end
      end
    end

    def handle_oral_question_section section, questions
      question_section = OralQuestionSection.new
      
      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            question_section.title = node.inner_html
          elsif name == 'p'
            handle_question_contribution node, question_section
          end
        end
      end

      question_section.parent_section = questions
      questions.questions << question_section
    end

    def handle_oral_questions_section section, oral_questions
      questions_section = OralQuestionsSection.new

      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            questions_section.title = node.inner_html
          elsif name == 'section'
            handle_oral_question_section node, questions_section
          end
        end
      end

      questions_section.parent_section = oral_questions
      oral_questions.sections << questions_section      
    end

    def handle_oral_questions section, debates
      oral_questions = OralQuestions.new
      
      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            oral_questions.title = node.inner_html
          elsif name == 'section'
            handle_oral_questions_section node, oral_questions
          elsif name == 'col'
            @column = node.inner_html
          else
            
          end
        end
      end

      oral_questions.parent_section = debates
      debates.sections << oral_questions
    end
    
    def handle_image
      
    end

    def handle_section section, debates
      if (title = section.at('title/text()'))
        if (title.to_s.strip.downcase == 'prayers' or !section.to_s.include?('membercontribution'))
          handle_procedural_section section, debates
        else
          handle_non_procedural_section section, debates
        end
      else
        raise 'unexpected to find section with no title: ' + section.to_s
      end
    end

    def handle_debates sitting, debates
      sitting.debates = Debates.new
      debates.children.each do |node|
        if node.elem?
          name = node.name
          if name == "section"
            handle_section node, sitting.debates
          elsif name == "oralquestions"
            handle_oral_questions node, sitting.debates
          elsif name == "image"
            handle_image
          elsif name == "col"
            @column = node.inner_html
          else
            raise 'unknown debates section type: ' + name
          end
        elsif node.text?          
          raise 'unexpected text outside of section: ' + node.to_s if node.to_s.strip.size > 0 
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

