require 'open-uri'

class SearchController < ApplicationController

  before_filter :redirect_to_search_result_url, :only => 'show'

  def index
  end

  def show
    @query = params[:query]
    render :template => "search/index" and return if @query.blank? 
    options = get_search_params(params) 
    @search = Search.new(options)
    respond_to do |format|
      format.html do 
        handle_hansard_reference(@search.hansard_reference) and return if @search.hansard_reference
        success = get_search_results
        render :template => "search/query_error" and return false if !success
      end
      format.atom do
        success = get_search_results
        if success
          render :template => 'search/show.atom.builder' and return false
        else
          render :template => 'search/query_error.atom.builder' and return false
        end
      end
    end
  end

  private

    def get_search_results
      success = false
      begin
        @search.get_results
        @paginator = WillPaginate::Collection.new(@search.page, @search.num_per_page, @search.results_size) 
        success = true
      rescue SearchException => e
        logger.error "Solr error: #{e.to_s}"
      end
      return success
    end
    
    def get_search_params params
      options = {}
      sort_options = ['date', 'reverse_date']
      param_keys = [:query, :speaker, :century, :decade, :year, :month, :day, :sort, :type, :all_speaker_filters]
      param_keys.each{ |key| options[key] = params[key] }
      options[:page] = params[:page].to_i if !params[:page].blank?
      options[:century] = nil unless /C\d\d/.match options[:century]
      options[:decade] = nil unless /\d\d\d\ds/.match options[:decade]
      options[:year] = nil unless /\d\d\d\d/.match options[:year]
      options[:month] = nil unless /\d\d\d\d-\d\d?/.match options[:month]
      options[:day] = nil unless /\d\d\d\d-\d\d?-\d\d?/.match options[:day]
      options[:sort] = nil unless sort_options.include? options[:sort]
      return options
    end

    def handle_hansard_reference reference
      @reference = reference
      if !@reference.find_sections.empty?
        redirect_to column_url(@reference.column, @reference.find_sections.first)
      else
        render :template => 'search/reference_not_found'
      end
    end

    def redirect_to_search_result_url
      if params[:query]
        params[:query].gsub!('.','')
      end
      redirect_to params and return false if request.post? and not params[:query].nil?
    end
    
end