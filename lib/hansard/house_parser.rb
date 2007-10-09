require 'rubygems'
require 'open-uri'
require 'hpricot'

module Hansard
  TIME_PATTERN = /^(\d\d?(\.|&#x00B7;)\d\d (am|pm))$/ unless defined?(TIME_PATTERN)
end

class Hansard::HouseParser

  def initialize file, logger=nil
    @logger = logger
    @unexpected = false
    @doc = Hpricot.XML open(file)
  end

  def log text
    @logger.add_log text if @logger
  end

  def parse
    type = @doc.children[0].name

    if type == 'housecommons'
      create_house_commons
    else
      raise 'cannot create sitting, unrecognized type: ' + type
    end
  end

  protected

    def create_section(section_type)
      section_type.new({
        :start_column => @column,
        :start_image_src => @image,
        :sitting => @sitting
      })
    end

    def handle_vote text, division, vote_type
      parts = text.split('(')
      log 'vote_type nil: ' + division.inspect unless vote_type
      vote = vote_type.new({
        :name => parts[0].strip,
        :column => @column,
        :image_src => @image
      })
      if parts.size > 1
        vote.constituency = parts[1].chomp(')')
      end
      vote.division = division
      division.votes << vote
    end

    def handle_division_table table, division
      left_cells = (table/'tr').collect {|e| (e/'td')[0] }
      (table/'tr/td').each do |cell|
        text = cell.inner_text.strip
        unless text.blank?
          if text.downcase.include? 'division no'
            # it's the division number, ignore
          elsif (/\d\d /.match text or /\d\.\d /.match text)
            # it's the time, ignore
          elsif text.downcase == 'ayes'
            @vote_type = AyeVote
          elsif text.downcase == 'noes'
            @vote_type = NoeVote
          elsif /teller(s)? for the ayes/.match text.downcase
            @vote_type = AyeTellerVote
          elsif /teller(s)? for the noes/.match text.downcase
            @vote_type = NoeTellerVote
          else
            vote_type = @vote_type
            if @vote_type == AyeTellerVote
              if left_cells.include? cell
                vote_type = AyeVote
              end
            end
            if @vote_type == NoeTellerVote
              if left_cells.include? cell
                vote_type = NoeVote
              end
            end
            handle_vote text, division, vote_type
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
            log 'unexpected element in non_procedural_section: ' + name + ': ' + node.to_s
          end
        end
      end
      placeholder.division = division
      placeholder.section = debate
      debate.contributions << placeholder
    end

    def handle_node_text element
      text = ''
      element.children.each do |child|
        text += child.elem? ?  child.to_original_html : child.to_s
      end
      text = text.gsub("\r\n","\n").strip
    end

    def set_columns_and_images_on_contribution element, contribution
      (element/'col').each do |col|
        handle_image_or_column "col", col
        contribution.column_range += ','+@column
      end
      (element/'image').each do |image|
        handle_image_or_column "image", image
        contribution.image_src_range += ','+@image
      end
    end

    def handle_contribution_text element, contribution
      set_columns_and_images_on_contribution element, contribution
      contribution.text = handle_node_text element
    end

    def handle_member_name element, contribution
      element.children.each do |node|
        if node.text?
          text = node.to_s.strip
          contribution.member += text if text.size > 0

        elsif node.elem?
          if node.name == 'memberconstituency'
            contribution.member_constituency = clean_html(node)
          else
            log 'unexpected element in member_name: ' + name + ': ' + node.to_s
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
      contribution.member = ''

      still_in_member_contribution = true

      element.children.each do |node|
        if node.elem?
          name = node.name

          if still_in_member_contribution
            if name == 'member'
              handle_member_name node, contribution
            elsif name == 'i'
              if contribution.procedural_note
                contribution.procedural_note += node.to_s
              else
                contribution.procedural_note = node.to_s
              end
            elsif name == 'membercontribution'
              handle_contribution_text node, contribution
            elsif name == 'ol'
              set_columns_and_images_on_contribution element, contribution
              contribution.text += clean_text(node.to_s)
            elsif name == 'quote'
              still_in_member_contribution = false
              contribution.section = debate
              debate.contributions << contribution
              handle_quote_contribution node, debate
            else
              log 'unexpected element: ' + name + ': ' + node.to_s
            end
          else
            if name == 'quote'
              handle_quote_contribution node, debate
            else
              log 'unexpected element: ' + name + ': ' + node.to_s
            end
          end
        end

        if node.text?
          unless node.to_s.strip.empty?
            log 'unexpected text: ' + node.to_s.strip
          end
        end
      end

      if still_in_member_contribution
        contribution.section = debate
        debate.contributions << contribution
      end
    end

    def handle_time_contribution node, debate, time_text
      time = TimeContribution.new({
        :xml_id => node.attributes['id'],
        :column_range => @column,
        :image_src_range => @image
      })
      time.text = clean_html(node)
      time.time = Time.parse(time_text.gsub('.',':').gsub("&#x00B7;", ":"))

      time.section = debate
      debate.contributions << time
      time
    end

    def handle_procedural_contribution node, debate
      procedural = ProceduralContribution.new({
        :xml_id => node.attributes['id'],
        :column_range => @column,
        :image_src_range => @image
      })
      procedural.text = handle_contribution_text(node, procedural)

      node.children.each do |part|
        if (part.elem? and part.name == 'member')
          procedural.member = '' unless procedural.member
          handle_member_name part, procedural
        end
      end

      if (match = /^(\d+\.?)/.match procedural.text)
        procedural.question_no = match[1]
      end

      style_atts = node.attributes.reject{|att, value| att == 'id'}
      style_list = []
      style_atts.each do |att, value|
        style_list << "#{att}=#{value}"
      end
      procedural.style = style_list.join(" ")
      procedural.section = debate
      debate.contributions << procedural
      procedural
    end

    def handle_quote_contribution node, debate
      quote = QuoteContribution.new({
        :column_range => @column,
        :image_src_range => @image,
        :text => clean_html(node).strip
      })
      quote.section = debate
      debate.contributions << quote
    end

    def handle_table_element node, debate
      if node.name == 'p'
        text = clean_html(node).strip
      else
        text = clean_text(node.to_s).strip
      end
      table = TableContribution.new({
        :column_range => @column,
        :image_src_range => @image,
        :text => text
      })
      if (id = node.attributes['id'])
        table.xml_id = id
      end
      table.section = debate
      debate.contributions << table
    end

    def handle_section_element section_element, debates
      section = create_section(Section)
      section_element.children.each do |node|
        if node.elem?
          name = node.name
          if name == 'title'
            section.title = handle_node_text(node)
          elsif name == 'p'
            inner_html = clean_html(node).strip

            if (match = Hansard::TIME_PATTERN.match inner_html)
              time_text = match[0]
              handle_time_contribution node, section, time_text
            elsif inner_html.include? 'membercontribution'
              handle_member_contribution node, section
            else
              handle_procedural_contribution node, section
            end
          elsif name == 'quote'
            handle_quote_contribution node, section
          elsif (name == 'col' or name == 'image')
            handle_image_or_column name, node
          elsif name == 'section'
            handle_section_element node, section
          elsif name == 'table'
            handle_table_element node, section
          elsif name == 'division'
            handle_division node, section
          elsif name == 'ul'
            contribution = handle_procedural_contribution node, section
            contribution.text = "<ul>\n"+contribution.text+"\n</ul>"
          elsif name == 'ol'
            contribution = handle_procedural_contribution node, section
            contribution.text = "<ol>\n"+contribution.text+"\n</ol>"
          else
            log 'unexpected element in section: ' + name + ': ' + node.to_s
          end
        end
      end

      section.parent_section = debates
      debates.sections << section
    end

    def get_contribution_type_for_question element
      contribution_type = nil

      if (element.at('member') or element.at('membercontribution'))
        # question_summary = element.inner_text.match /^\d+\./
        contribution_type = MemberContribution
      elsif element.at('quote')
        contribution_type = QuoteContribution
      else
        contribution_type = ProceduralContribution
      end

      contribution_type
    end

    def handle_element_in_question_contribution node, contribution, element, in_member_contribution_text, in_between_member_and_member_contribution
      name = node.name
      if name == 'member'
        handle_member_name node, contribution
        in_between_member_and_member_contribution = true
      elsif name == 'membercontribution'
        handle_contribution_text node, contribution
        in_between_member_and_member_contribution = false
      elsif name == 'i'
        if in_member_contribution_text
          handle_contribution_text element, contribution
        else
          if contribution.procedural_note
            contribution.procedural_note += node.to_s
          else
            contribution.procedural_note = node.to_s
          end
        end
      elsif (name == 'col' or name == 'image')
        handle_image_or_column name, node
        if in_member_contribution_text
          contribution.text += node.to_s
        end
      elsif name == 'lb'
        if in_member_contribution_text
          contribution.text += node.to_s.sub('<lb></lb>', '<lb/>')
        end
      else
        raise 'unexpected element in question_contribution: ' + name + ': ' + node.to_s
      end

      in_between_member_and_member_contribution
    end

    def handle_text_in_question_contribution node, contribution, element, in_member_contribution_text, in_between_member_and_member_contribution
      text = node.to_s.strip
      if (match = /^(Q?\d+\.? and \d+\.?)/.match text)
        contribution.question_no = match[1]
      elsif (match = /^(Q?\d+\.?)/.match text)
        contribution.question_no = match[1]
      elsif text.size > 0
        if contribution.member.size == 0
          contribution.member = text.gsub("\r\n","\n").strip + ' '
        elsif !@unexpected
          if element.at('membercontribution')
            if text == ':'
              contribution.text += node.to_s.squeeze(' ')
            elsif text == ']' || text == '.'
              contribution.text += text
            elsif in_between_member_and_member_contribution && (text == '(')
              contribution.procedural_note = '('
            elsif in_between_member_and_member_contribution && (text == ')')
              contribution.procedural_note += ')'
            else
              log 'unexpected text: ' + text + ' in contribution ' + contribution.inspect
              log 'will suppress rest of unexpected messages'
              @unexpected = true
            end
          else
            in_member_contribution_text = true
            suffix = node.to_s.ends_with?("\r\n") ? '\n' : ''
            prefix = node.to_s.starts_with?("\r\n") ? '\n' : ''
            contribution.text += prefix + text.gsub("\r\n","\n").strip + suffix
          end
        end
      elsif node.to_s == "\r\n"
        if in_member_contribution_text
          contribution.text += '\n'
        end
      end

      return in_member_contribution_text, in_between_member_and_member_contribution
    end

    def handle_question_contribution element, question_section
      contribution_type = get_contribution_type_for_question(element)

      if contribution_type == QuoteContribution
        handle_quote_contribution element, question_section
      elsif contribution_type == ProceduralContribution
        handle_procedural_contribution element, question_section
      else
        contribution = contribution_type.new({
           :xml_id => element.attributes['id'],
           :column_range => @column,
           :image_src_range => @image,
           :member => '',
           :text => ''})

        in_member_contribution_text = false
        in_between_member_and_member_contribution = false
        element.children.each do |node|
          if node.elem?
            in_between_member_and_member_contribution = handle_element_in_question_contribution node, contribution, element, in_member_contribution_text, in_between_member_and_member_contribution

          elsif node.text?
            in_member_contribution_text, in_between_member_and_member_contribution = handle_text_in_question_contribution node, contribution, element, in_member_contribution_text, in_between_member_and_member_contribution
          end
        end

        contribution.section = question_section
        question_section.contributions << contribution
      end
    end

    def is_orders_of_the_day? title
      /orders of the day/i.match(title)
    end

    def is_business_of_the_house? title
      /business of the house/i.match(title)
    end

    def handle_image_or_column name, node
      if name == "image"
        @image = node.attributes['src']
      elsif name == "col"
        @column = clean_html(node)
      end
    end

    def handle_section section, debates
      if (title = section.at('title/text()'))
        handle_section_element section, debates
      else
        raise 'unexpected to find section with no title: ' + section.to_s
      end
    end

    def handle_prayers_outside_section node, debates
      section = create_section(Section)
      section.title = node.inner_html.to_s
      element = node.next_sibling
      if (element.elem? and element.inner_html.to_s.include?('Chair'))
        handle_procedural_contribution element, section
      else
        raise 'unexpected sibling after prayers: ' + element.to_s
      end

      section.parent_section = debates
      debates.sections << section
    end

    def handle_debates sitting, debates
      sitting.debates = create_section(Debates)
      debates.children.each do |node|
        handle_debates_child node, sitting
      end
    end

    def create_house_commons
      @column =  clean_html(@doc.at('housecommons/col'))
      @image =  @doc.at('housecommons/image').attributes['src']

      @sitting = HouseOfCommonsSitting.new({
        :start_column => @column,
        :start_image_src => @image,
        :title => clean_html(@doc.at('housecommons/title')),
        :text => clean_html(@doc.at('housecommons/p')),
        :date_text => clean_html(@doc.at('housecommons/date')),
        :date => @doc.at('housecommons/date').attributes['format']
      })

      if (texts = (@doc/'housecommons/p'))
        @sitting.text = ''
        texts.each do |text|
          @sitting.text += text.to_s
        end
      end

      if (debates = @doc.at('housecommons/debates'))
        handle_debates @sitting, debates
      end

      @sitting
    end

    def clean_html node
      clean_text node.inner_html
    end

    def clean_text text
      text.chars.gsub("\r\n","\n").to_s
    end
end
