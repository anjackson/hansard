require 'open3'
module Hansard
end

module Hansard::SchemaValidator

  include Open3

  def schema_file schema
    "#{RAILS_ROOT}/public/schemas/#{schema.downcase}"
  end

  def xml_file name
    "#{RAILS_ROOT}/xml/#{name}.xml"
  end

  def validate_against_schema schema, name
    validate_against_schema_file schema_file(schema), xml_file(name)
  end

  def validate_against_schema_file schema_file, xml_file
    errors = ''
    validation_error_lines(schema_file, xml_file).each do |line|
      is_error_message = (/xml validates$/.match(line) == nil)

      if is_error_message
        errors += (line.chomp + ' ')
      end
    end
    errors.chomp(' ')
  end

  def validation_error_lines schema_file, xml_file
    stdin, stdout, stderr = popen3("xmllint --noout --schema #{schema_file} #{xml_file}")
    stderr
  end

end
