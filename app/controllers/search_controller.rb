require 'open-uri'

class SearchController < ApplicationController

  def index 
  end
  
  
  def show
    @query = params[:query]

    @member = params[:member]
    @page = (params[:page] or 1).to_i
    @num_per_page = 10

    @search_options = pagination_options.merge(highlight_options)
    if @member
      query = members_speech_search(@member, @query)
    else
      query = text_search(@query)
      @search_options = @search_options.merge(facet_options)
    end
    @result_set = Contribution.find_by_solr(query, @search_options)
    @paginator = WillPaginate::Collection.new(@page, @num_per_page, @result_set.total_hits)

  end

  private

    def text_search(query)
      "text:#{query}"
    end

    def members_speech_search(member, query)
      "text:#{query} AND member:\"#{member}\""
    end

    def highlight_options
      { :highlight => {:fields =>"text",
                      :prefix => "<span class='highlight'>",
                      :suffix => "</span>" }  }
    end

    def pagination_options
      { :offset => (@page - 1) * @num_per_page }
    end

    def facet_options
      { :facets => { :fields =>[:member] } }
    end

end