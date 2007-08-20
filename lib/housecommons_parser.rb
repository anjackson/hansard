require 'rubygems'
require 'open-uri'
require 'hpricot'

# ruby script/generate rspec_model sitting      type:string date:date title:string date_text:string column:string text:text
# ruby script/generate rspec_model section      type:string title:string time:time time_text:string column:string
# ruby script/generate rspec_model contribution type:string xml_id:string member:string member_constituency:string membercontribution:string column:string oral_question_no:string

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

    def handle_vote text, division
      parts = text.split('(')
      vote = @vote_type.new({
        :name => parts[0].strip,
        :column => @column,
        :image_src => @image_src
      })
      if parts.size > 1
        vote.constituency = parts[1].chomp(')')
      end
      vote.division = division
      division.votes << vote
    end

    def handle_division_table table, division
      (table/'tr/td').each do |cell|
        text = cell.inner_text.strip
        unless text.blank?
          if text.downcase.include? 'division no'
            #ignore
          elsif /\d\d/.match text
            #ignore
          elsif text.downcase == 'ayes'
            @vote_type = AyeVote
          elsif text.downcase == 'noes'
            @vote_type = NoeVote
          else
            handle_vote text, division
          end
        end
      end
    end

    def handle_division node, debate
      placeholder = DivisionPlaceholder.new
      division = Division.new({
        :name => node.at('table/tr[1]/td[1]/b/text()').to_s,
        :time_text => node.at('table/tr[1]/td[2]/b/text()').to_s
      })

      node.children.each do |child|
        if child.elem?
          name = child.name
          if name == 'table'
            handle_division_table child, division
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, child
          else
            puts 'unexpected element in non_procedural_section: ' + name + ': ' + node.to_s
          end
        end
      end
      placeholder.division = division
      placeholder.section = debate
      debate.contributions << placeholder
    end

    def handle_contribution_text element, contribution
      element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'col'
            handle_image_or_column name, node
            contribution.column_range += ','+@column
          elsif name == 'image'
            handle_image_or_column name, node
            contribution.image_src_range += ','+@image
          else
            # don't need to handle as we set contribution.text to inner_html
          end
        end
      end
      contribution.text = element.inner_html.gsub("\r\n","\n")
    end

    def handle_member_name element, contribution
      element.children.each do |node|
        if node.text?
          text = node.to_s.strip
          contribution.member = text if text.size > 0

        elsif node.elem?
          if node.name == 'memberconstituency'
            contribution.member_constituency = node.inner_html
          else
            puts 'unexpected element in member_name: ' + name + ': ' + node.to_s
          end
        end
      end
    end

    def handle_member_contribution element, debate
      contribution = MemberContribution.new({
         :xml_id => element.attributes['id'],
         :column_range => @column,
         :image_src_range => @image
      })

      element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'member'
            handle_member_name node, contribution
          elsif name == 'i'
            contribution.procedural_note = node.to_s
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
        :column_range => @column,
        :image_src_range => @image,
        :text => node.inner_html.strip
      })
      procedural.section = debate
      debate.contributions << procedural
      procedural
    end

    def handle_quote_contribution node, debate
      quote = QuoteContribution.new({
        :column_range => @column,
        :image_src_range => @image,
        :text => node.inner_html.strip
      })
      quote.section = debate
      debate.contributions << quote
    end

    def handle_orders_of_the_day section, debates
      orders = Section.new({
        :start_column => @column,
        :start_image_src => @image
      })
      section.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            orders.title = node.inner_html
          elsif name == 'section'
            handle_section_element node, orders
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
          else
            puts 'unexpected element in orders_of_the_day: ' + name + ': ' + node.to_s
          end
        end
      end
      orders.parent_section = debates
      debates.sections << orders
    end


    def handle_section_element section_element, debates
      section = Section.new({
        :start_column => @column,
        :start_image_src => @image
      })

      section_element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            section.title = node.inner_html
          elsif name == 'p'
            if (match = Hansard::TIME_PATTERN.match node.inner_html)
              section.time_text = match[0]
              section.time = Time.parse(match[0].gsub('.',':').gsub("&#x00B7;", ":"))
              handle_procedural_contribution node, section
            elsif not(node.inner_html.include? 'membercontribution')
              handle_procedural_contribution node, section

            else
              handle_member_contribution node, section
            end
          elsif name == 'quote'
            handle_quote_contribution node, section
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
          elsif name == 'section'
            handle_section_element node, section
          elsif name == 'division'
            handle_division node, section
          else
            puts 'unexpected element in non_procedural_section: ' + name # + ': ' + node.to_s
          end
        end
      end

      section.parent_section = debates
      debates.sections << section
    end

    def handle_question_contribution element, question_section
      contribution = question_section.contributions.create({
         :xml_id => element.attributes['id'],
         :column_range => @column,
         :image_src_range => @image
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
            raise 'unexpected element in question_contribution: ' + name + ': ' + node.to_s
          end

        elsif node.text?
          text = node.to_s.strip
          if (match = /^(Q?\d+\.?)/.match text)
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
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
          else
            puts 'unexpected element in oral_question_section: ' + name + ': ' + node.to_s
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
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
          elsif name == 'p'
            if questions_section.introduction
              raise "unexpected second paragraph under oral questions section"
            else
              procedural = handle_procedural_contribution node, questions_section
              questions_section.introduction = procedural
            end
          else
            puts 'unexpected element in oral_questions_section: ' + name + ': ' + node.to_s
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
          elsif (name == 'image' or name == 'col')
            handle_image_or_column name, node
          else
            puts 'unexpected element in oral_questions: ' + name + ': ' + node.to_s
          end
        end
      end

      oral_questions.parent_section = debates
      debates.sections << oral_questions
    end

    def handle_image_or_column name, node
      if name == "image"
        @image = node.attributes['src']
      elsif name == "col"
        @column = node.inner_html
      end
    end

    def handle_section section, debates
      if (title = section.at('title/text()'))
        title = title.to_s.strip.downcase.squeeze(' ')

        if title == 'orders of the day'
          handle_orders_of_the_day section, debates
        else
          handle_section_element section, debates
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
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
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
      @image =  @doc.at('housecommons/image').attributes['src']

      sitting = HouseOfCommonsSitting.new({
        :start_column => @column,
        :start_image_src => @image,
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

