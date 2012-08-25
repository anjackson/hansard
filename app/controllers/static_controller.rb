class StaticController < ApplicationController

  def send_404
    respond_with_404
  end

  def api
    @title = "API"
  end
  
  def credits
    @title = "Credits"
  end
  
  def typos
    @title = "Typos"
  end
  
end