class WrittenAnswersBody < Section

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.body do
      yield
    end
  end
  
end