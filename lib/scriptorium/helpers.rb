# Path magic

module PathSep
  def /(right)
    s1 = self.to_s.dup
    s2 = right.to_s.dup
    s1 << "/" unless s1.end_with?("/") || s2.start_with?("/")
    path = s1 + s2
    path.gsub!("//", "/")
    path
  end
end

String.include(PathSep)
Symbol.include(PathSep)

## Helpers

module Scriptorium::Helpers
  include Scriptorium::Exceptions
  def getvars(file)
    lines = read_file(file, lines: true)
    lines.map! {|line| line.sub(/ #.*$/, "").strip }
    lines.reject! {|line| line.empty? }
    # FIXME - what if variable value has a # in it?
    vhash = Hash.new("")
    lines.each do |line|
      var, val = line.split(" ", 2)
      vhash[var.to_sym] = val
    end
    vhash
  end

  def d4(num)
    "%04d" % num
  end

  def view_dir(name)
    @root/:views/name
  end

  def write_file(file, *lines)
    # Input validation
    raise CannotWriteFilePathNil if file.nil?
    
    raise CannotWriteFilePathEmpty if file.to_s.strip.empty?
    
    # Ensure parent directory exists
    FileUtils.mkdir_p(File.dirname(file))
    
    # Write the file with error handling
    begin
      File.open(file, "w") do |f|
        lines.each {|line| f.puts line }
      end
    rescue Errno::ENOSPC => e
      raise CannotWriteFileDiskFull(file, e.message)
    rescue Errno::EACCES => e
      raise CannotWriteFilePermissionDenied(file, e.message)
    rescue Errno::ENOENT => e
      raise CannotWriteFileDirectoryNotFound(file, e.message)
    rescue => e
      raise CannotWriteFileError(file, e.message)
    end
  end

  def make_dir(dir, create_parents = false)
    # Input validation
    raise CannotCreateDirectoryPathNil if dir.nil?
    
    raise CannotCreateDirectoryPathEmpty if dir.to_s.strip.empty?
    
    # Create parent directories if requested
    if create_parents
      FileUtils.mkdir_p(dir)
    else
      # Create single directory with error handling
      begin
        Dir.mkdir(dir)
      rescue Errno::ENOSPC => e
        raise CannotCreateDirectoryDiskFull(dir, e.message)
      rescue Errno::EACCES => e
        raise CannotCreateDirectoryPermissionDenied(dir, e.message)
      rescue Errno::ENOENT => e
        raise CannotCreateDirectoryParentNotFound(dir, e.message)
      rescue Errno::EEXIST => e
        # Directory already exists - this is usually not an error
        # But we could make this configurable if needed
      rescue => e
        raise CannotCreateDirectoryError(dir, e.message)
      end
    end
  end

  def system!(command, description = nil)
    # Input validation
    raise CannotExecuteCommandNil if command.nil?
    
    raise CannotExecuteCommandEmpty if command.to_s.strip.empty?
    
    # Execute command with error handling
    success = system(command)
    
    unless success
      desc = description ? " (#{description})" : ""
      raise CommandFailedWithDesc(desc, command)
    end
    
    success
  end

  def need(type, path, exception_class = RuntimeError)
    # Input validation
    raise CannotRequirePathNil(type) if path.nil?
    
    raise CannotRequirePathEmpty(type) if path.to_s.strip.empty?
    
    # Check if file/directory exists
    exists = case type
             when :file
               File.exist?(path)
             when :dir
               Dir.exist?(path)
             else
               raise InvalidType(type)
             end
    
    unless exists
      raise RequiredFileNotFound(type, path) if exception_class == RuntimeError
      
      # Exception class - try to call it as a method first, then as constructor
      raise exception_class.call(path) if exception_class.respond_to?(:call)
      raise exception_class.new(path)
    end
    
    path
  end

  def read_file(file, options = {})
    # Input validation
    raise CannotReadFilePathNil if file.nil?
    
    raise CannotReadFilePathEmpty if file.to_s.strip.empty?
    
    # Handle missing file with fallback
    if options[:missing_fallback]
      return options[:missing_fallback] unless File.exist?(file)
    end
    
    # Read the file with error handling
    begin
      if options[:lines]
        # Read as lines
        if options[:chomp]
          File.readlines(file, chomp: true)
        else
          File.readlines(file)
        end
      else
        # Read as content
        File.read(file)
      end
    rescue Errno::ENOENT => e
      if options[:missing_fallback]
        return options[:missing_fallback]
      else
        raise CannotReadFileNotFound(file, e.message)
      end
    rescue Errno::EACCES => e
      raise CannotReadFilePermissionDenied(file, e.message)
    rescue => e
      raise CannotReadFileError(file, e.message)
    end
  end

  def write_predef(sym, path)
    contents = @predef.send(sym, :raw)
    write_file(@root/path, [contents])
  end

  def change_config(file_path, target_key, new_value)
    pattern = /
      ^(?<leading>\s*#{Regexp.escape(target_key)}\s+)  # key and spacing
      (?<old_value>[^\#]*?)                            # value (non-greedy up to comment)
      (?<trailing>\s*)                                 # trailing space
      (?<comment>\#.*)?$                               # optional comment
    /x
  
    lines = read_file(file_path, lines: true)
    updated_lines = lines.map do |line|
      if match = pattern.match(line)
        leading  = match[:leading]
        trailing = match[:trailing]
        comment  = match[:comment] || ''
        "#{leading}#{new_value}#{trailing}#{comment}\n"
      else
        line
      end
    end
  
    write_file(file_path, *updated_lines)
  end
  
  def slugify(id, title)
    slug = title.downcase.strip
               .gsub(/[^a-z0-9\s_-]/, '')  # remove punctuation
               .gsub(/[\s_-]+/, '-')       # replace spaces and underscores with hyphen
               .gsub(/^-+|-+$/, '')        # trim leading/trailing hyphens
    "#{d4(id)}-#{slug}"
  end
  
  def ymdhms
    Time.now.strftime("%Y-%m-%d-%H-%M-%S")
  end

  def see_file(file)   # Really from TestHelpers
    puts "----- File: #{file}"
    system!("cat #{file}", "displaying file contents")
    puts "-----"
  end

  def see(label, var)
    puts "#{label} = \n<<<\n#{var}\n>>>"
  end

  def make_tree(base, text)
    lines = text.split("\n").map(&:chomp)
    lines.each {|line| line.gsub!(/ *#.*$/, "") }
    entries = []
  
    # Determine the root name
    first_line = lines.shift
    root = first_line.strip.sub(/\/$/, "") # remove trailing slash
    root_path = File.join(base, root)
    make_dir(root_path) unless File.exist?(root_path)
  
    # Prepare stack starting from root
    stack = [root_path]
  
    # Parse the remaining lines
    lines.each do |line|
      if (i = line.index(/ [a-zA-Z0-9_.]/))
        name = line[(i + 1)..-1]
        level = i / 4
      else
        name = line.strip
        level = 0
      end
      entries << [level, name]
    end
  
    entries.each do |level, name|
      stack = stack[0..level]
      full_path = File.join(stack.last, name)
  
      if name.end_with?("/")
        make_dir(full_path) unless File.exist?(full_path)
        stack << full_path
      else
        write_file(full_path, "Empty file generated at #{Time.now}")
      end
    end
  end            

  def substitute(obj, text)
    vars = obj.is_a?(Hash) ? obj : obj.vars
    text % vars
  end

  def escape_html(str)
    str.gsub(/&/, '&amp;')
       .gsub(/</, '&lt;')
       .gsub(/>/, '&gt;')
       .gsub(/"/, '&quot;')
       .gsub(/'/, '&#39;')
  end
  
  def read_commented_file(file_path)
    return [] unless File.exist?(file_path)
  
    lines = read_file(file_path, lines: true)  # Read file and remove newline characters
  
    # Process the lines to remove empty lines and comments
    lines.reject! do |line|
      line.strip.empty? || line.strip.start_with?("#")
    end
  
    # Strip trailing comments and their preceding spaces
    lines.map! do |line|
      line.sub(/#.*$/, "").strip  # Remove everything after '#' and strip spaces
    end
  
    lines  # Return the cleaned lines
  end
      
  def cf_time(t1, t2)
    t1 = t1.split(/- :/, 6)
    t2 = t2.split(/- :/, 6)
    t1 = Time.new(*t1)
    t2 = Time.new(*t2)
    t1 <=> t2
  end

  def get_asset_path(name)
    if Scriptorium::Repo.testing
      if File.exist?("lib/scriptorium/dev_assets/#{name}")
        return "lib/scriptorium/dev_assets/#{name}"
      else
        raise AssetNotFound(name)
      end
    else  # Production
      raise NoGemPath
      # return "#{Gem.loaded_specs['scriptorium'].full_gem_path}/lib/scriptorium/assets/#{asset_path}"
    end
  end
end

