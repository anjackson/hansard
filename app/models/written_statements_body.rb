class WrittenStatementsBody < Section

  def id_hash
    parent_section.id_hash
  end

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.body do
      yield
    end
  end
  
  def is_written_body?
    true
  end

end