describe 'a json-rendering model', :shared => true do 
  
  it 'should not render id-based attributes if passed json defaults' do 
    json = @model.to_json(@model.class.json_defaults)
    json_hash = ActiveSupport::JSON.decode(json)
    json_hash.should_not match(/_id/)
    json_hash.should_not match(/"id/)
  end

end