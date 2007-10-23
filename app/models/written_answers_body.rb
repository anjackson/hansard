class WrittenAnswersBody < Section

  def title
    parent_section.title
  end

  def id_hash
    parent_section.id_hash
  end

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.body do
      yield
    end
  end

end