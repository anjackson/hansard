class WrittenStatementsGroup < Section

   belongs_to :sitting

   def outer_tag(options)
     xml = options[:builder] ||= Builder::XmlMarkup.new
     xml.group do
       yield
     end
   end

end
