class SittingsController < ApplicationController
  
  def show
    @sitting = Sitting.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @sitting.to_xml }
    end
  end
  
end