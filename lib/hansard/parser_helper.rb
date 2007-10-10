
module Hansard
end

module Hansard::ParserHelper

  def per_data_file pattern, &block
    directories = Dir.glob(File.dirname(__FILE__) + "/../../data/*").select{|f| File.directory?(f)}
    directories.each do |directory|
      Dir.glob(directory + "/*").select{|f| File.directory?(f)}.each do |d|
        Dir.glob(d+'/'+pattern).each do |file|
          yield d, file
        end
      end
    end
  end

  def reload_sitting_on_date date, house_type, sitting_model, parser_type
    date_part = date.to_s.gsub('-','_')
    file_name = "house#{house_type}_#{date_part}.xml"
    data_file = DataFile.find_by_name(file_name)
    data_file.reset_fields if data_file

    sitting = sitting_model.find_by_date(date)
    if sitting
      puts 'destroying sitting instance for ' + date.to_s
      sitting.destroy
    end

    per_data_file(file_name) do |directory, file|
      source_file = SourceFile.from_file(directory)
      parse_file(file, parser_type, source_file)
    end
    data_file
  end

  def parse_file(file, parser, source_file=nil)
    data_file = DataFile.from_file(file)
    unless data_file.saved?
      data_file.source_file = source_file
      data_file.log = ''
      data_file.add_log "parsing\t" + data_file.name, false
      data_file.add_log "directory:\t" + data_file.directory, false
      data_file.attempted_parse = true
      begin
        result = parser.new(file, data_file).parse
        data_file.parsed = true

        begin
          data_file.attempted_save = true
          result.data_file = data_file
          result.save!
          data_file.add_log "saved\t" + data_file.name, false
          data_file.saved = true
          data_file.save!
        rescue Exception => e
          data_file.add_log "saving FAILED\t" + e.to_s
          data_file.save!
        end
      rescue Exception => e
        data_file.add_log "parsing FAILED\t" + e.to_s
        data_file.save!
      end
    end
  end
end

