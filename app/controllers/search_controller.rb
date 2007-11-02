require 'open-uri'

class SearchController < ApplicationController

  def index
  end

  def random
    size = Section.count
    section = Section.find(rand(size-1))
    redirect_to section_url(section)
  end

  def show
    @query = params[:query]
    @member = params[:member]
    @decade = params[:decade]
    @page = (params[:page] or 1).to_i
    @num_per_page = 30
    @sort = params[:sort]

    @decade = nil unless /\d\d\d\ds/.match @decade
    @sort = nil unless 'date' == @sort

    redirect_to :back and return if @member.blank? and @query.blank?

    @search_options = pagination_options.merge(highlight_options)
    @search_options = @search_options.merge(sort_options) if @sort

    if @member
      query = members_speech_search(@member, @query)
    elsif @decade
      query = decade_search(@decade, @query)
    else
      query = text_search(@query)
      @search_options = @search_options.merge(facet_options)
    end

    begin
      @result_set = Contribution.find_by_solr(query, @search_options)
      @paginator = WillPaginate::Collection.new(@page, @num_per_page, @result_set.total_hits)
    rescue
      render :template => "search/query_error"
    end

  end

  private

    def text_search(query)
      "text:#{query}"
    end

    def decade_search(decade, query)
      start_year = decade.to_i
      "text:#{query} AND date:[#{start_year}-01-01 TO #{start_year + 9}-12-31]"
    end

    def members_speech_search(member_name, query)
      "text:#{query} AND member_name:\"#{member_name}\""
    end

    def sort_options
      { :order => "#{@sort} asc" }
    end

    def highlight_options
      { :highlight => { :fields =>"text",
                        :prefix => "<em>",
                        :suffix => "</em>",
                        :require_field_match => true } }
    end

    def pagination_options
      { :offset => (@page - 1) * @num_per_page,
        :limit  => @num_per_page }
    end

    def facet_options
      { :facets => { :fields => [:member_name, :date],
                     :zeros => false, :sort => true } }
    end

end