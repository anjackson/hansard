require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::SchemaValidator do

  before :each do
    self.class.send(:include, Hansard::SchemaValidator)
  end
  
  describe 'when asked for schema file' do
    it 'should create path to schema file' do
      schema_file('Schema').should == "#{RAILS_ROOT}/public/schemas/schema"
    end
  end

  describe 'when asked for xml file' do
    it 'should create path to xml file' do
      xml_file('name').should == "#{RAILS_ROOT}/xml/name.xml"
    end
  end
  
  describe 'when asked to validate against schema' do
 
    it 'should validate against schema file' do
      schema = 'schema'; schema_file = 'schema_file'
      name = 'name'; xml_file = 'xml_file'
      should_receive(:schema_file).with(schema).and_return schema_file
      should_receive(:xml_file).with(name).and_return xml_file
      should_receive(:validate_against_schema_file).with(schema_file, xml_file)

      validate_against_schema(schema, name)
    end
 
    it 'should return any errors as a string' do
      should_receive(:validation_error_lines).and_return ['error','another error']
      validate_against_schema_file('schema_file', 'xml_file').should == 'error another error'
    end
 
    it 'should return empty string if no errors' do
      should_receive(:validation_error_lines).and_return ['xml validates']
      validate_against_schema_file('schema_file', 'xml_file').should == ''
    end
 
  end
  
  describe 'when asked for validation error lines' do

    it 'should use xmlint to perform validation' do
      stderr = mock('stderr')
      should_receive(:popen3).with("xmllint --noout --schema schema_file xml_file").and_return ['','',stderr]
      validation_error_lines('schema_file', 'xml_file').should == stderr
    end

  end

end
