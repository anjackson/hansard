require 'open-uri'

class SearchController < ApplicationController


  def index
    @query = params[:query]
    @member = params[:member]
    if @member
      @result_set = Contribution.find_by_solr("text:#{@query} AND member:\"#{@member}\"") 
    else
      @member_facets = []
      @result_set = Contribution.find_by_solr("text:#{@query}", 
                                              :facets => {:fields =>[:member]})
      unless @result_set.facets["facet_fields"].empty?
        found_facets = @result_set.facets["facet_fields"]["member_facet"]
        found_facets = found_facets.select{|member,value| value > 0}
        found_facets.sort{|a,b| b[1]<=>a[1]}.each do |member|
          @member_facets << member
        end
      end 
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