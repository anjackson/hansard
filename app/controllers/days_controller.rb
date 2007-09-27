class DaysController < ApplicationController

  def index
    @sitting = Sitting.most_recent
  end

end