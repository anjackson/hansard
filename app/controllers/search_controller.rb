require 'open-uri'

class SearchController < ApplicationController

  def index
    if params[:query]
     @query = params[:query]
     @per_page = 10
     @search_params = {"q"       => CGI.escape(@query),
                       "site"    => "prototypes",
                       "client"  => "default_frontend",
                       "output"  => "xml_no_dtd",
                       "start"   => 0,
                       "as_sitesearch" => "rua.parliament.uk/hansard",
                       "num" => @per_page}
     @search_params.update("start" => params[:start]) if !params[:start].nil?
     @gquery = "#{APPLICATION_URLS[:search]}?#{hash_to_query(@search_params)}"
     @xml_results = open(@gquery, :proxy => false).read
     print "RESULTS ARE #{@xml_results}"
     @result_set = ResultSet.new(@xml_results)
    end
  end

  private

    def hash_to_query(hash)
      params = []
      hash.each do |k,v|
        params << k+'='+v.to_s
      end
      params.join('&')
    end

end