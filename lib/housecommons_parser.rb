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

    def create_house_commons
      sitting = HouseOfCommonsSitting.new({
        :column => @doc.at('housecommons/col').inner_html,
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

      sitting.debates = DebatesSection.new
      sitting
    end
  
end

