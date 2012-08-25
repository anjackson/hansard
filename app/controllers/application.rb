class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  helper_method :section_url
  helper_method :column_url
  session :off

  def self.is_production?
    RAILS_ENV == 'production'
  end

  def section_show_params
    { :controller => "sections",
      :action => "show", 
      :format => nil }
  end

  def section_url(section)
    url_for(section.id_hash.merge(section_show_params))
  end

  def section_path(section)
    params = section.id_hash
    general_params = section_show_params.merge(:skip_relative_url_root => true,
                                               :only_path => true)
    url_for(params.merge(general_params))
  end

  def column_url(column, section)
    column_string = section.sitting.class.normalized_column(column.to_s)
    "#{section_url(section)}#column_#{column_string.downcase}"
  end

  def check_valid_date
    return true unless has_date_params?
    if params[:day]
      @resolution = :day
    elsif params[:month]
      @resolution = :month
    elsif params[:year]
      @resolution = :year
    elsif params[:decade]
      @resolution = :decade
    end

    @url_date = case @resolution
      when :day;    UrlDate.new(params)
      when :month;  UrlDate.new(params.merge(:day=>'01'))
      when :year;   UrlDate.new(params.merge(:month=>'jan',:day=>'01'))
      when :decade; UrlDate.new(params.merge(:year => year_from_decade(params[:decade]), :month => 'jan', :day => '01'))
      else;         UrlDate.new(params.merge(:year => Date.year_from_century_string(params[:century]).to_s, :month => 'jan', :day => '01'))
    end

    redirect_date @url_date unless @url_date.is_valid_date?

    begin
      @date = @url_date.to_date
    rescue
      redirect_to :action => "index"
    end
  end

  def redirect_date date
    params[:day] = date.day
    params[:month] = date.month
    params[:action] = "show" if params[:day]
    params[:action] = "show_division" if params[:day] && params[:controller] == 'divisions'
    redirect_to(params, :status => :moved_permanently) and return false
  end

  protected

    def strip_images
      self.response.body = self.response.body.gsub(/<image src="[^"]*"><\/image>/, '')
    end
    
    def year_from_decade decade
      (decade.to_i).to_s
    end

    def has_date_params?
      (params[:year] or params[:decade] or params[:century]) ? true : false
    end

    def no_model_response model_name
      respond_to do |format|
        format.html { render :template => "#{model_name.pluralize}/no_#{model_name}" }
        format.all  { render :nothing => true, :status => "404 Not Found" }
      end
      true
    end

    def check_letter_index
      letter = params[:letter]
      redirect_to_letter letter.downcase if letter && letter[/[A-Z]/]
      @letter = letter || 'a'
    end

    def redirect_to_letter letter
      url = url_for :controller => params[:controller], :action => params[:action], :letter => letter
      redirect_to url, :status => :moved_permanently
    end

    def with_sitting type, date
      if sitting = Sitting.find_sitting(type, date)
        yield sitting
      else
        respond_with_404
      end
    end

    def with_sitting_and_section type, date, slug
      sitting, section = Sitting.find_sitting_and_section(type, date, slug)
      if section
        yield sitting, section
      elsif slug.ends_with? '-'
        url_params = params.merge({ :id=> slug.chomp('-') })
        url = url_for url_params
        redirect_to url, :status => :moved_permanently
      else
        respond_with_404
      end
    end

    def respond_with_404
      @title = 'Page not found'
      respond_to do |format|
        format.html { render :template => "static/404", :status => "404 Not Found" and return true }
        format.all  { render :nothing => true, :status => "404 Not Found" and return true }
      end
    end
end
