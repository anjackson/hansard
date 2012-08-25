class BillsController < ApplicationController

  caches_page :index, :show
  before_filter :check_letter_index, :only => [:index]

  def index
    @bills = Bill.find_all_sorted
    @list_bills = @bills.select{|bill| bill.name[/\A#{@letter}/i] }
  end

  def show
    @bill = Bill.find_by_slug(params[:name])
    no_model_response "bill" and return false unless @bill
    @other_bills = @bill.others_by_name
  end
end