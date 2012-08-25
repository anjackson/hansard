class MembershipsController < ApplicationController

  before_filter :check_valid_date
  
  def show 
    @commons_count, @commons_memberships = CommonsMembership.members_on_date_by_constituency(@date)
    @lords_count, @lords_memberships = LordsMembership.members_on_date_by_person(@date)
    respond_to do |format|
      format.html { }
      format.js do
        
        render :text => [@commons_memberships.to_json(CommonsMembership.json_defaults), 
                         @lords_memberships.to_json(LordsMembership.json_defaults)], 
               :content_type => "text/x-json"
      end
    end
  end
  
end