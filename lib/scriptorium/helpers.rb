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
  def getvars(file)
    lines = File.readlines(file).map(&:chomp)
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
    # dir = file.sub(/\/[a-zA-Z_\.]+$/, "") rescue "."
    File.open(file, "w") do |f|
      lines.each {|line| f.puts line }
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
  
    lines = File.readlines(file_path)
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
  
    File.write(file_path, updated_lines.join)
  end
  
  def slugify(id, title)
    slug = title.downcase.strip
               .gsub(/[^a-z0-9\s_-]/, '')  # remove punctuation
               .gsub(/[\s_-]+/, '-')       # replace spaces and underscores with hyphen
               .gsub(/^-+|-+$/, '')        # trim leading/trailing hyphens
    format("%04d-%s", id, slug)
  end
  
  def ymdhms
    Time.now.strftime("%Y-%m-%d-%H-%M-%S")
  end

  def see_file(file)   # Really from TestHelpers
    puts "----- File: #{file}"
    system("cat #{file}")
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
    Dir.mkdir(root_path) unless File.exist?(root_path)
  
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
        Dir.mkdir(full_path) unless File.exist?(full_path)
        stack << full_path
      else
        File.write(full_path, "Empty file generated at #{Time.now}\n")
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
  
    lines = File.readlines(file_path).map(&:chomp)  # Read file and remove newline characters
  
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

