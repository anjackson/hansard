module Hansard
  class Splitter

    SPLIT_ON = [
        'houselords',
        'housecommons',
        'writtenstatements',
        'writtenanswers',
        'westminsterhall',
        'index'
    ]
  
    DATE_PATTERN = /date format="(\d\d\d\d-\d\d-\d\d)"/
  
    def write_to_file name, buffer, date=nil
      name = name + '_' + date.to_s.gsub('-','_') if date
      file_name = File.join @result_path, name+'.xml'
      File.open(file_name, 'w') do |file|
        file.write(buffer.join(''))
      end

      if @indented_copy
        indented_file = File.join @indented_result_path, name+'_indented.xml'
        indent_cmd = "xmllint --format #{file_name} > #{indented_file}"
        `#{indent_cmd}`
      end
    end
  
    def handle_section_start element, line
      if @section_name # inside section already
        @outside_buffer = @buffer # backup outside section
        @outside_section_name = @section_name
        @outside_date = @date
        @buffer = []
      end
      @section_name = element
      @start = @index
    end
  
    def handle_section_end line
      if @section_name
        @buffer << line
        puts @date.to_s + '    ' + @section_name + ' start:' + @start.to_s + ' end:' + @index.to_s + ' lines:' + @buffer.size.to_s
  
        write_to_file @section_name, @buffer, @date
        @buffer = []
      elsif @outside_buffer # write out backup if there is one
        @outside_buffer << line
        write_to_file @outside_section_name, @outside_buffer, @outside_date
        @outside_buffer = nil
      end
        
      @section_name = nil
      @date = nil
    end
  
    def handle_line line
      @index = @index.next
  
      token_element = false
  
      SPLIT_ON.each do |element|
        if line.include? '<'+element+'>'
          handle_section_start element, line
          token_element = true
        end
  
        if line.include? '</'+element+'>'
          handle_section_end line
          token_element = true
        end
      end
  
      if (@section_name == nil) and (token_element == false)
        @surrounding_buffer << line
      end
  
      if @section_name
        @buffer << line
      end
  
      if (match = DATE_PATTERN.match line)
        new_date = match[1]
        @date = new_date
      end
    end

    def clear_directory path
      if File.exists? path
        Dir.glob(File.join(path,'*.xml')).each do |file|
          File.delete file
        end
      else
        Dir.mkdir path
      end
    end

    def split base_path, indented_copy=false
      @base_path = base_path
      @indented_copy = indented_copy
      source_path = File.join @base_path, 'xml'

      raise "source directory #{source_path} not found" unless File.exists? source_path
      source_files = Dir.glob(File.join(source_path,'*'))
      raise "no source files found in #{source_path}" if source_files.size == 0

      source_files.each do |input_file|
        puts input_file
        directory_name = input_file.split(File::SEPARATOR).last.chomp('.xml').downcase
        @result_path = File.join @base_path, 'data', directory_name
        @indented_result_path = File.join @base_path, 'data', directory_name, 'indented'
        clear_directory @result_path
        clear_directory @indented_result_path

        @index = 0
        @surrounding_buffer = []
        @buffer = []
        @outside_buffer = nil
        @section_name = nil
        @date = nil

        File.new(input_file).each_line do |line|
          handle_line line
        end

        puts 'header ' + @surrounding_buffer.size.to_s
        write_to_file 'header', @surrounding_buffer

        total_lines = 0
        Dir.glob(File.join(@result_path,'*.xml')).each do |result|
          # total_lines += `wc -l #{result}`.split(' ')[0].to_i
        end
        puts 'total lines: ' + total_lines.to_s
        # puts 'original lines: ' + `wc -l #{input_file}`.split(' ')[0]
      end
    end
  end
end
