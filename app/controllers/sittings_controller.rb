class SittingsController < ApplicationController
  
  def initialize
    today = Date.today
    @year = today.year
    @month = today.month - 1
  end
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @month = params[:month].to_i if params[:month]
    @year = params[:year].to_i if params[:year]
  end

  def show
    @sitting = Sitting.find(params[:id])
    @sections = @sitting.original_sections
    @turns = @sitting.original_turns
  end

  def turns_sparkline
    name = params['id']
    sitting = Sitting.find(params[:id])
    turns_by_interval = sitting.turns_by_interval(15)

    counts = []
    turns_by_interval.keys.sort.each do |interval|
      counts << turns_by_interval[interval].size
    end
    
    params = { :type => 'smooth', :height => 100, :width => 100, :line_color => 'darkgrey' }
    send_data(Sparklines.plot(counts, params),
      :disposition => 'inline',
      :type => 'image/png',
      :filename => "spark_#{params[:type]}.png" )
      
  end
  
  def turns_graph
    
    sitting = Sitting.find(params[:id])
    
    g = Gruff::Line.new(400)
    g.title = "Turns (" + sitting.date + ")" 
    
    turns_by_interval = sitting.turns_by_interval(sitting.SatAt.midnight + 9.hours, sitting.SatAt.midnight + 1.day + 8.hours + 15.minutes, 30)

    counts = []
    turns_by_interval.keys.sort.each do |interval|
      counts << turns_by_interval[interval].size
    end
    
    g.data("Turns", counts)
    g.labels = {0 => turns_by_interval.keys.sort[0].strftime("%I:%M%p"), (turns_by_interval.size-1) => turns_by_interval.keys.sort[(turns_by_interval.size-1)].strftime("%I:%M%p")}
    
    send_data(g.to_blob, 
      :disposition => 'inline', 
      :type => 'image/png', 
      :filename => "Turns Graph.png")
    
  end
  
  def stage_graph
   
    doctype = Doctype.find_by_Name(params[:name])
    sitting = Sitting.find(params[:id])
    
    documents = sitting.original_turns if params[:name] == "Turn" 
    documents = sitting.original_sections if params[:name] == "Section"

    
    g = Gruff::Pie.new(400)
    g.title = params[:name] + "s Stage Graph" 
    g.title_font_size = 30
    g.hide_legend = false
    g.marker_font_size = 18
    g.theme = {
      :colors => %w(red orange green),
      :maker_color => '#bbbbbb',
      :background_colors => %w(#eeeeee #eeeeee)
    }
    
    
    counts = []
    
    i = 0
    for stage in doctype.stages
      stage_documents = documents.select{|document|document.Stage == stage.Stage}      
      g.data(stage.Code, [stage_documents.size])
      
      i += 1
    end
    
    labels = {0 => "Debate"}
    g.labels = labels

    send_data(g.to_blob, 
      :disposition => 'inline', 
      :type => 'image/png', 
      :filename => "Stage Graph.png")
  
  end


end
