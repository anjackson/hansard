require 'open3'
module Hansard
end

module Hansard::SchemaHelper

  include Open3

  def validate_schema schema, name
    schema_file = "#{RAILS_ROOT}/public/schemas/#{schema}"
    xml_file = "#{RAILS_ROOT}/xml/#{name}.xml"

    errors = ''
    if File.exist? schema_file
      stdin, stdout, stderr = popen3("xmllint --noout --schema #{schema_file} #{xml_file}")
      stderr.each do |line|
        is_error_message = (/xml validates$/.match(line) == nil)

        if is_error_message
          errors += (line.chomp + ' ')
        end
      end
    end
    errors
  end

end
