require 'fileutils'

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

    DATE_PATTERN = /date format="(\d\d\d\d-\d\d-\d\d)">(.*?)<\/date>/
    SCHEMA_PATTERN = /xsi:noNamespaceSchemaLocation="(.*?)"/

    def initialize indented_copy, overwrite=true, verbose=true, sleep_seconds=nil
      @indented_copy = indented_copy
      @verbose = verbose
      @overwrite = overwrite
      @additional_lines = 0
      @sleep_seconds = sleep_seconds
    end

    def split base_path
      @files_created = []
      @base_path = base_path
      files_split = []
      Dir.mkdir(@base_path + '/data') unless File.exists?(@base_path + '/data')
      source_path = File.join @base_path, 'xml'

      raise "source directory #{source_path} not found" unless File.exists? source_path
      source_files = Dir.glob(File.join(source_path,'*'))
      raise "no source files found in #{source_path}" if source_files.size == 0

      source_files.each do |input_file|
        @additional_lines = 0
        puts input_file if @verbose
        source_file = handle_file(input_file)
        source_file.save!
        files_split << source_file
        sleep @sleep_seconds if @sleep_seconds
      end
      files_split
    end

    def split_file base_path, input_file
      @files_created = []
      @base_path = base_path
      @additional_lines = 0
      puts input_file if @verbose
      source_file = handle_file(input_file)
      source_file.save!
      source_file
    end

    def write_to_file name, buffer, date=nil
      name = name + '_' + date.to_s.gsub('-','_') if date
      file_name = File.join @result_path, name+'.xml'

      if @files_created.include? file_name
        index = 2
        while @files_created.include? file_name
          file_name = File.join @result_path, name+"_part_#{index}.xml"
          index = index.next
        end
      end

      File.open(file_name, 'w') do |file|
        file.write(buffer.join(''))
      end

      @files_created << file_name

      if (file_name.include? 'lords')
        @house = 'lords'
      elsif (file_name.include? 'commons')
        @house = 'commons'
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
      @new_section = true
    end

    def handle_section_end line
      if @section_name
        @buffer << line
        puts @date.to_s + "\t" + @section_name + "\t" + @start.to_s + '-' + @index.to_s + "\t" + @buffer.size.to_s  if @verbose

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

      start_end_on_same_line = false
      start_end_element = nil
      SPLIT_ON.each do |element|
        unless start_end_on_same_line
          start_end_on_same_line = line.starts_with?('</'+element+'><'+element+'>')
          start_end_element = element
        end
      end
      proxy_lines = []

      if start_end_on_same_line
        puts 'start and end on same line: ' + line if @verbose
        proxy_line = line.sub('</'+start_end_element+'>','')
        line = line.sub('<'+start_end_element+'>', '')
        proxy_lines << proxy_line
        @additional_lines = @additional_lines.next
      end

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

      check_for_date(line)
      check_for_schema(line) unless @source_file.schema
      check_for_image(line) 
      check_for_column(line)  
      proxy_lines.each {|l| handle_line l}
    end

    def clear_directory path
      if File.exists? path
        if @overwrite
          Dir.glob(File.join(path,'*.xml')).each do |file|
            File.delete file
          end
        end
      else
        Dir.mkdir path
      end
    end
    
    def check_for_image(line)
      if (match = @image_pattern.match line)
        new_image_num = match[1].to_i
        if @image_num+1 != new_image_num 
          @source_file.add_log "Missing image? Got: #{new_image_num}, expected #{@image_num+1} (last image #{@image_num})"
        end 
        @image_num = new_image_num
      end
    end
    
    def check_for_column(line)
      if (match = @column_pattern.match line)
        new_column_num = match[1].to_i
        if (@column_num+1 != new_column_num and !(@new_section and new_column_num == 1))  
          @source_file.add_log "Missing column? Got: #{new_column_num}, expected #{@column_num+1} (last column #{@column_num})"
        end 
        @column_num = new_column_num
        @new_section = false
      end
    end
    
    
    def check_for_date(line)
      if (match = DATE_PATTERN.match line)
        new_date = match[1]
        new_date_text = match[2]
        begin 
          if Date.parse(new_date_text.gsub(/\.|,/, '')) != Date.parse(new_date)
            @source_file.add_log("Bad date format: #{match[0]}")
          end 
        rescue
          @source_file.add_log("Bad date format: #{match[0]}")
        end
        @date = new_date
        @first_date = new_date unless @first_date
      end
    end
      
    def check_for_schema(line)
      if (match = SCHEMA_PATTERN.match line)
        @source_file.schema = match[1]
      end
    end

    def move_final_result directory_name, input_file
      size_in_mb = (File.size(input_file)/ 1048576.0)
      mb = size_in_mb.to_s[0..2]
      result_path = File.join(@base_path, 'data', @first_date.to_s.gsub('-','_')+'_'+@house)+'_'+mb+'mb'
      Dir.mkdir result_path unless File.exists?(result_path)
      result_directory = File.join(result_path, directory_name)
      FileUtils.remove_dir result_directory, true
      FileUtils.mv @result_path, result_directory
      @source_file.result_directory = result_directory
      @source_file
    end

    def handle_file input_file
      directory_name = input_file.split(File::SEPARATOR).last.chomp('.xml')
      @result_path = File.join @base_path, 'data', directory_name
      @indented_result_path = File.join @base_path, 'data', directory_name, 'indented'
      @source_file = SourceFile.from_file(input_file)
      @image_pattern = /image src="#{directory_name}I(\d\d\d\d)"\//
      @column_pattern = /<col>(\d+)<\/col>/
      @image_num = 0
      @column_num = 0
      process_file input_file, directory_name
    end

    def process_file input_file, directory_name
      clear_directory @result_path
      clear_directory @indented_result_path if @indented_copy

      @index = 0
      @surrounding_buffer = []
      @buffer = []
      @outside_buffer = nil
      @section_name = nil
      @date = nil
      @first_date = nil

      File.new(input_file).each_line { |line| handle_line line }

      puts 'header ' + @surrounding_buffer.size.to_s  if @verbose
      write_to_file 'header', @surrounding_buffer

      check_line_count_correct input_file
      move_final_result directory_name, input_file
    end

    def check_line_count_correct input_file
      total_lines = 0
      Dir.glob(File.join(@result_path,'*.xml')).each do |result|
        lines = 0
        File.open(result).each_line {|line| lines += 1}
        total_lines += lines
      end
      puts "total\t" + total_lines.to_s  if @verbose
      input_lines = @additional_lines
      File.open(input_file).each_line {|line| input_lines += 1}
      puts "original\t" + input_lines.to_s  if @verbose

      if total_lines != input_lines
        raise "Number of lines don't match! Expected: #{input_lines} Got: #{total_lines}"
      else
        puts "Processed expected number of lines\t" + total_lines.to_s  if @verbose
      end
    end

  end
end
