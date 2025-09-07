require 'ostruct'
require 'pp'
require 'date'
require 'find'
require 'fileutils' # Added for FileUtils

# require 'pathmagic'
# require 'processing'


####
#### NOTE:  Much of this was salvaged from liveblog.rb (for Runeblog support)
####        Double-commented stuff *may* be useful if ported.
####

=begin
  ChatGPT recommends minimal metadata:

Key	     Purpose
id       Unique numeric or UUID identifier for the post (e.g. 0123)
title    Human-readable title for display and slug generation
date     Original creation date
updated  (Optional) Last modified or published date
slug     URL-safe identifier (usually derived from title, e.g. my-first-post)
views    (Optional) Names of views this post belongs to
status   e.g., draft, published, archived
tags     List of tags or categories
c    (Optional) Short summary or excerpt

Some will go into meta.lt3 - I will use:  id, title, created, views

=end

# Dot commands:

def page_title(args, data)
  setvar("page.title", data)
end

def copyright
  author = Livetext::Vars["author"]
  year   = Time.now.year
  setvar("page.copyright", "&copy; #{author} #{year}")
end

def title(args, data)
  File.open("/tmp/debug_directives.txt", "a") do |f|
    f.puts "DEBUG: title directive called with data: #{data.inspect}"
  end
  setvar("post.title", data)
end

def created(args, data)
  if args.empty?
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  else
    time = data
  end
  setvar("post.created", time)
end

def last_updated
  pub_date = api.vars("post.created")
  api.out "<p><em>Published: #{pub_date}</em></p>"
end

def wordcount
  text = File.read(Livetext::Vars[:File])
  words = text.split
  setvar("wordcount", words.size.to_s)
end

def stats
  text = File.read(api.vars[:File])
  words = text.split
  word_count = words.size
  
  # Calculate reading time (average 200 words per minute)
  reading_time = (word_count / 200.0).ceil
  
  # Calculate character count
  char_count = text.length
  
  # Set all the variables with file. prefix
  setvar("file.wordcount", word_count.to_s)
  setvar("file.readingtime", reading_time.to_s)
  setvar("file.charcount", char_count.to_s)
end

def views(args, data)
  setvar("post.views", data.strip)
end

def tags(args, data)
  setvar("post.tags", data.strip)
end

def blurb(args, data, body)
  # body contains only the content between .blurb and .end
  text = body.join(" ").strip
  File.open("/tmp/debug_blurb.txt", "a") do |f|
    f.puts "DEBUG: blurb function called at #{Time.now}"
    f.puts "DEBUG: blurb function called with body: #{body.inspect}"
    f.puts "DEBUG: blurb text: #{text.inspect}"
    f.puts "---"
  end
  setvar("post.blurb", text)
end

def testblurb(args, data, body)
  File.open("/tmp/debug_testblurb.txt", "w") do |f|
    f.puts "DEBUG: testblurb function called with body: #{body.inspect}"
  end
  setvar("post.testblurb", "test worked")
end

def pin(args, data)
  # Legacy command - just ignore it for now
  # Could be used to pin posts to specific views
end

def mono(args, data, body)
  # Wrap body in <pre> tags for monospace display
  code_content = body.join("\n")
  api.out %[<pre>#{code_content}</pre>]
  api.optional_blank_line
end

def ruby(args, data, body)
  # Show Ruby code for client-side highlighting
  code_content = body.join("\n")
  api.out %[<pre><code class="language-ruby">#{code_content}</code></pre>]
  api.optional_blank_line
end

# Old liveblog code:


##################
# "dot" commands
##################
  
def dropcap(args, data, body)
  content = body.join(" ")
  api.out %[<p class="dropcap">#{content}</p>]
  api.optional_blank_line
end
  
def faq(args, data, body)
  @faq_count ||= 0
  api.out "<br>" if @faq_count == 0
  @faq_count += 1
  ques = data.chomp
  ans  = body.join("\n")
  id = "faq#@faq_count"
  api.out %[&nbsp;<a data-toggle="collapse" href="##{id}" role="button" aria-expanded="false" aria-controls="collapseExample"><font size=+3>&#8964;</font></a>]
  api.out %[&nbsp;<b>#{ques}</b>]
  api.out %[<div class="collapse" id="#{id}"><br><font size=+1>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#{ans}</font></div>\n]
  api.out "<br>" # unless @faq_count == 1
  api.optional_blank_line
end

def quote(args, data, body)
  # was _passthru??? via runeblog
  api.out "<blockquote>"
  api.out body.join(" ")
  api.out "</blockquote>"
  api.optional_blank_line
end

# Move elsewhere later!
# was _passthru??? via runeblog
def h1(args, data); api.out "<h1>#{data}</h1>"; end
def h2(args, data); api.out "<h2>#{data}</h2>"; end
def h3(args, data); api.out "<h3>#{data}</h3>"; end
def h4(args, data); api.out "<h4>#{data}</h4>"; end
def h5(args, data); api.out "<h5>#{data}</h5>"; end
def h6(args, data); api.out "<h6>#{data}</h6>"; end
def hr(args, data); api.out "<hr>"; end

def nlist(args, data, body)
  api.out "<ol>"
  body.each {|line| api.out "<li>#{line}</li>" }
  api.out "</ol>"
  api.optional_blank_line
end

def list(args, data, body)
  api.out "<ul>"
  body.each {|line| api.out "<li>#{line}</li>" }
  api.out "</ul>" 
  api.optional_blank_line
end

def list!(args, data, body)
  api.out "<ul>"
  lines = body.each 
  loop do 
    line = lines.next
    line = api.format(line)
    if line[0] == " "
      api.out line
    else
      api.out "<li>#{line}</li>"
    end
  end
  api.out "</ul>"
  api.optional_blank_line
end

### inset

def inset(args, data, body)
  lines = body
  box = ""
  output = []
  lines.each do |line| 
    line = line
    case line[0]
      when "/"  # Only into inset
        line[0] = ' '
        box << line
        line.replace(" ")
      when "|"  # Into inset and body
        line[0] = ' '
        box << line
        output << line
    else  # Only into body
      output << line 
    end
  end
  lr = args.first
  wide = args[1] || "25"
  stuff = "<div style='float:#{lr}; width: #{wide}%; padding:8px; padding-right:12px'>"
  stuff << '<b><i>' + box + '</i></b></div>'
  api.out "</p>"   #  kludge!! nopara
  0.upto(2) {|i| api.out output[i] }
  api.out stuff
  3.upto(output.length-1) {|i| _passthru output[i] }
  api.out "<p>"  #  kludge!! para
  api.optional_blank_line
end

def image(args, data)   # primitive so far
  fname, alt = data.split(" ", 2)
  path = "assets/#{fname}"
  api.out "<img src=#{path} alt='#{alt}'></img>"
  api.optional_blank_line
end

def image!(args, data)
  fname, w, h, factor, alt = data.split(" ", 5)
  path = "assets/#{fname}"
  alt.gsub!("'", "&apos;")
  alt.gsub!("\"", "&quot;")
  api.out <<-HTML
    <a href=#{path} target=_blank
       title='#{alt} (click to open)'>
      <img src=#{path} width=#{w.to_i/factor.to_i}
        height=#{h.to_i/factor.to_i}
        alt='#{alt}'>
      </img>
    </a>
  HTML
  api.optional_blank_line
end

### Functions

class Livetext::Functions

  def nbsp(param)
    "&nbsp;" * param.to_i
  end

  def asset(param)
    begin
      # Get view and post information
      vname = @live.vars.to_h[:View]
      postid = @live.vars.to_h[:"post.id"]   # search post first
      num = d4(postid)
      root = Scriptorium::Repo.root
      search_paths = []
      search_paths << ["#{root}/posts/#{num}/assets/#{param}", "assets/#{num}/#{param}"]
      search_paths << ["#{root}/views/#{vname}/assets/#{param}", "assets/#{param}"]
      search_paths << ["#{root}/assets/#{param}", "assets/#{param}"]
      search_paths << ["#{root}/assets/library/#{param}", "assets/#{param}"]
      
      begin
        gem_spec = Gem.loaded_specs['scriptorium']
        if gem_spec
          gem_asset_path = "#{gem_spec.full_gem_path}/assets/#{param}"
          search_paths << [gem_asset_path, "assets/#{param}"]
        else
          dev_gem_path = File.expand_path("assets/#{param}")
          if File.exist?(dev_gem_path)
            search_paths << [dev_gem_path, "assets/#{param}"]
          end
        end
      rescue => e
      end
      
      search_paths.each do |source_path, output_path|
        if File.exist?(source_path)
          return output_path
        end
      end
      
      return "assets/missing/#{param}.svg"
    rescue => e
      return "[Asset error: #{e.message}]"
    end
  end

  def image_asset(param)
    asset_path = asset(param)
    "<img src=\"#{asset_path}\" alt=\"#{param}\">"
  end

  def generate_missing_asset_svg(filename, width: 200, height: 150)
    # Truncate filename if too long for display
    display_name = filename.length > 20 ? filename[0..16] + "..." : filename
    
    # Generate SVG with broken image icon and filename
    svg = <<~SVG
      <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
        <!-- Background -->
        <rect fill="#f8f9fa" stroke="#ddd" stroke-width="1" width="#{width}" height="#{height}" rx="4"/>
        
        <!-- Broken image icon -->
        <g transform="translate(#{width/2}, #{height/2 - 20})">
          <!-- Image frame -->
          <rect x="-15" y="-10" width="30" height="20" fill="none" stroke="#999" stroke-width="1"/>
          <!-- Broken corner -->
          <path d="M 15 -10 L 25 -20 M 15 -10 L 25 0" stroke="#999" stroke-width="1" fill="none"/>
          <!-- Image icon -->
          <rect x="-12" y="-7" width="24" height="14" fill="#e9ecef"/>
          <circle cx="-5" cy="-2" r="2" fill="#999"/>
          <polygon points="-8,8 -2,2 2,6 8,0" fill="#999"/>
        </g>
        
        <!-- Filename -->
        <text x="#{width/2}" y="#{height/2 + 15}" text-anchor="middle" fill="#666" font-family="Arial, sans-serif" font-size="11">
          #{display_name}
        </text>
        
        <!-- "Asset not found" message -->
        <text x="#{width/2}" y="#{height/2 + 30}" text-anchor="middle" fill="#999" font-family="Arial, sans-serif" font-size="9">
          Asset not found
        </text>
      </svg>
    SVG
    
    svg.strip
  end

  public def d4(num)
    "%04d" % num.to_i
  end

  def br(n="1")
    # Thought: Maybe make a way for functions to "simply" call the
    #   dot command of the same name?? Is this trivial??
    n = n.empty? ? 1 : n.to_i
    "<br>"*n
  end

  def h1(param); "<h1>#{param}</h1>"; end
  def h2(param); "<h2>#{param}</h2>"; end
  def h3(param); "<h3>#{param}</h3>"; end
  def h4(param); "<h4>#{param}</h4>"; end
  def h5(param); "<h5>#{param}</h5>"; end
  def h6(param); "<h6>#{param}</h6>"; end

  def image(param)
    "<img src='#{param}'></img>"
  end
end

# Removed old wordcount function - replaced with dot command below

def _passthru(line)
  return if line.nil?
  line = _format(line)
  api.out line + "\n"
  api.out "<p>" if line.empty? && ! api.nopara
end

def _passthru_noline(line)
  return if line.nil?
  line = _format(line)
  api.out line
  api.out "<p>" if line.empty? && ! api.nopara
end

def code(args, data, body)
  language = args.first
  code_content = body.join("\n")
  
  # Use Rouge syntax highlighting if language is supported
  if language && !language.empty?
    begin
      highlighter = Scriptorium::SyntaxHighlighter.new
      highlighted_code = highlighter.highlight(code_content, language)
      api.out %q[<pre><code class="language-#{language}">#{highlighted_code}</code></pre>]
    rescue => e
      # Fallback to unhighlighted code if highlighting fails
      api.out %[<pre><code class="language-#{language}">#{code_content}</code></pre>]
    end
  else
    # No language specified, output as plain text
    api.out %[<pre><code>#{code_content}</code></pre>]
  end
  
  api.optional_blank_line
end

##  def backlink
##    log!(enter: __method__)
##    api.out %[<br><a href="javascript:history.go(-1)">[Back]</a>]
##  end
##  
##  def code
##    log!(enter: __method__)
##    lines = api.body # _text
##    api.out "<font size=+1><pre>\n#{lines}\n</pre></font>"
##  end
##  
##  def _read_navbar_data
##    log!(enter: __method__)
##    vdir = @blog.root/:views/@blog.view
##    dir = vdir/"themes/standard/banner/navbar/"
##    datafile = dir/"list.data"
##    _get_data(datafile)
##  end
##  
##  def banner
##    log!(enter: __method__)
##    count = 0
##    bg = "white"  # outside loop
##    wide = nil
##    high = 250
##    str2 = ""
##    navbar = nil
##    # vdir = @blog.root/:views/@blog.view
##    lines = api.body.to_a
##  
##    lines.each do |line|
##      count += 1
##      tag, *data = line.split
##      data ||= []
##      deps = [@blog.view.globals[:ViewDir]/"global.lt3"]
##      case tag
##        when "width";   wide = data[0]
##        when "height";  high = data[0]
##        when "bgcolor"; bg = data[0] || "white"
##        when "image"
##          image = data[0] || "banner.jpg"
##          image = "banner"/image
##          wide = data[0]
##          width = wide ? "width=#{wide}" : "" 
##          str2 << "      <td><img src=#{image} #{width} height=#{high}></img></td>" + "\n"
##        when "svg_title"
##          stuff, hash = _svg_title(*data)
##          wide = hash["width"]
##          str2 << "      <td width=#{wide}>#{stuff}</td>" + "\n"
##        when "text"
##          data[0] ||= "top.html"
##          file = "banner"/data[0]
##          if ! File.exist?(file) 
##            src = file.sub(/html$/, "lt3")
##            if File.exist?(src)
##              preprocess src: src, dst: file, deps: deps, call: ".nopara", vars: @blog.view.globals
##            else
##              raise FoundNeither(file, src)
##            end
##          end
##          str2 << "<td>" + File.read(file) + "</td>" + "\n"
##        when "navbar"
##          navbar = _make_navbar  # horiz is default
##        when "vnavbar"
##          navbar = _make_navbar(:vert)
##        when "break"
##           str2 << "  </tr>\n  <tr>"  + "\n"
##      else
##        str2 << "        '#{tag}' isn't known" + "\n"
##      end
##    end
##    api.out <<~HTML
##      <table width=100% bgcolor=#{bg}>
##        <tr>
##          #{str2}
##        </tr>
##      </table>
##    HTML
##    api.out navbar if navbar
##  rescue => err
##    STDERR.puts "err = #{err}"
##    STDERR.puts err.backtrace.join("\n") if err.respond_to?(:backtrace)
##  end
##  
##  def _svg_title(*args)
##    log!(enter: __method__)
##    width    = "95%"
##    height   = 90
##    # bgcolor  = "black"
##    style    = nil
##    size     = ""
##    font     = "sans-serif"
##    color    = "white"
##    xy       = "5,5"
##    align    = "center"
##    style2   = nil
##    size2    = ""
##    font2    = "sans-serif"
##    color2   = "white"
##    xy2      = "5,5"
##    align2   = "center"
##  
##    e = args.each
##    hash = {}  # TODO get rid of hash??
##  
##    valid = %w[width height bgcolor style size font color xy 
##               align style2 size2 font2 color2 xy2 align2]
##    os = OpenStruct.new
##    loop do
##      arg = e.next
##      arg = arg.chop
##      raise "Don't know '#{arg}'" unless valid.include?(arg)
##      os.send(arg+"=", e.next)
##    end
##    x, y = xy.split(",")
##    x2, y2 = xy2.split(",")
##    names = %w[x y x2 y2] + valid
##    names.each {|name| hash[name] = os.send(name) }
##    result = <<~HTML
##      <svg width="#{width}" height="#{height}"
##           viewBox="0 0 #{width} #{height}">
##        <defs>
##          <linearGradient id="grad1" x1="100%" y1="100%" x2="0%" y2="100%">
##            <stop offset="0%" style="stop-color:rgb(198,198,228);stop-opacity:1" />
##            <stop offset="100%" style="stop-color:rgb(30,30,50);stop-opacity:1" />
##          </linearGradient>
##        </defs>
##        <style>
##          .title    { font: #{style} #{size} #{font}; fill: #{color} }
##          .subtitle { font: #{style2} #{size2} #{font2}; fill: #{color2} }
##        </style>
##        <rect x="10" y="10" rx="10" ry="10" width="#{width}" height="#{height}" fill="url(#grad1)"/>
##        <text text-anchor="#{align}"  x="#{x}" y="#{y}" class="title">#{Livetext::Vars["view.title"]} </text>
##        <text text-anchor="#{align2}" x="#{x2}" y="#{y2}" class="subtitle">#{Livetext::Vars["view.subtitle"]} </text>
##      </svg> 
##      <!-- ^ how does syntax highlighting get messed up? </svg> -->
##    HTML
##    [result, hash]
##  end
##  def categories   # does nothing right now
##    log!(enter: __method__)
##  end
##  
##  def style
##    log!(enter: __method__)
##    fname = api.args[0]
##    _passthru %[<link rel="stylesheet" href="???/etc/#{fname}')">]
##  end


##  def pin
##    log!(enter: __method__)
##    raise NoPostCall unless @meta
##    api.debug "args = #{api.args}"  # verify only valid views?
##    pinned = api.args
##    @meta.pinned = pinned
##    pinned.each do |pinview|
##      dir = @blog.root/:views/pinview/"widgets/pinned/"
##      datafile = dir/"list.data"
##      pins = _get_data?(datafile)
##      pins << "#{@meta.num} #{@meta.title}\n"
##      pins.uniq!
##      File.open(datafile, "w") {|out| pins.each {|pin| out.puts pin } }
##    end
##    api.optional_blank_line
##  rescue => err
##    STDERR.puts "err = #{err}"
##    STDERR.puts err.backtrace.join("\n") if err.respond_to?(:backtrace)
##  end
##  
##  def write_post
##    log!(enter: __method__)
##    raise NoPostCall unless @meta
##    @meta.views = @meta.views.join(" ") if @meta.views.is_a? Array
##    @meta.tags  = @meta.tags.join(" ") if @meta.tags.is_a? Array
##    _write_metadata
##  rescue => err
##    puts "err = #{err}"
##    puts err.backtrace.join("\n") if err.respond_to?(:backtrace)
##  end
##  
##  def teaser
##    log!(enter: __method__)
##    raise NoPostCall unless @meta
##    text = api.body.join("\n")
##    @meta.teaser = text
##    setvar :teaser, @meta.teaser
##    if api.args[0] == "dropcap"
##      letter, remain = text[0], text[1..-1]
##      api.out %[<div class='mydrop'>#{letter}</div>]
##      api.out %[<div style="padding-top: 1px">#{remain}] + "\n"
##    else
##      api.out @meta.teaser + "\n"
##    end
##  end
##  
##  def finalize
##    log!(str: "Now exiting livetext processing...")
##    return unless @meta
##    return @meta if @blog.nil?
##  
##    @slug = @blog.make_slug(@meta)
##    slug_dir = @slug
##    @postdir = @blog.view.dir/:posts/slug_dir
##    write_post
##    @meta
##  end
##   
##  def head  # Does NOT output <head> tags
##    log!(enter: __method__)
##    args = api.args
##    args.each do |inc|
##      self.data = inc
##      dot_include
##    end
##  
##    # Depends on vars: title, desc, host
##    defaults = { "charset"        => %[<meta charset="utf-8">],
##                 "http-equiv"     => %[<meta http-equiv="X-UA-Compatible" content="IE=edge">],
##                 "title"          => %[<title>\n  #{_var("view.title")} | #{_var("view.subtitle")}\n  </title>],
##                 "generator"      => %[<meta name="generator" content="Runeblog v #@version">],
##                 "og:title"       => %[<meta property="og:title" content="#{_var("view.title")}">],
##                 "og:locale"      => %[<meta property="og:locale" content="#{_var(:locale)}">],
##                 "description"    => %[<meta name="description" content="#{_var("view.subtitle")}">],
##                 "og:description" => %[<meta property="og:description" content="#{_var("view.subtitle")}">],
##                 "linkc"          => %[<link rel="canonical" href="#{_var(:host)}">],
##                 "og:url"         => %[<meta property="og:url" content="#{_var(:host)}">],
##                 "og:site_name"   => %[<meta property="og:site_name" content="#{_var("view.title")}">],
##  #              "style"          => %[<link rel="stylesheet" href="etc/blog.css">],
##                 "feed"           => %[<link type="application/atom+xml" rel="alternate"] +
##                                     %[href="#{_var(:host)}/feed.xml" title="#{_var("view.title")}">],
##                 "favicon"        => %[<link rel="shortcut icon" type="image/x-icon" href="etc/favicon.ico">\n ] + 
##                                     %[<link rel="apple-touch-icon" href="etc/favicon.ico">]
##               }
##  
##    result = {}
##    lines = api.body
##    lines.each do |line|
##      line.chomp
##      word, remain = line.split(" ", 2)
##      case word
##        when "viewport"
##          result["viewport"] = %[<meta name="viewport" content="#{remain}">]
##        when "script" 
##          file = remain
##          text = File.read(file)
##          result["script"] = Livetext.new.transform(text)
##        when "style"
##          result["style"] = %[<link rel="stylesheet" href="etc/#{remain}">]
##        # Later: allow other overrides
##        when ""; break
##      else
##        if defaults[word]
##          result[word] = %[<meta property="#{word}" content="#{remain}">]
##        else
##          puts "Unknown tag '#{word}'"
##        end
##      end
##    end
##    hash = defaults.dup.update(result) 
##  
##    hash.each_value {|x| api.out "  " + x }
##  end
##  
##  ########## newer stuff...
##  
##  def meta
##    log!(enter: __method__)
##    args = api.args
##    enum = args.each
##    str = "<meta"
##    arg = enum.next
##    loop do 
##      if arg.end_with?(":")
##        str << " " << arg[0..-2] << "="
##        a2 = enum.next
##        str << %["#{a2}"]
##      else
##        STDERR.puts "=== meta error?"
##      end
##      arg = enum.next
##    end
##    str << ">"
##    api.out str
##  end
##  
##  def _make_class_name(app)
##    log!(enter: __method__)
##    if app =~ /[-_]/
##      words = app.split(/[-_]/)
##      name = words.map(&:capitalize).join
##    else
##      name = app.capitalize
##    end
##    return name
##  end
##  
##  def _load_local(widget)
##    log!(enter: __method__)
##    rclass = _make_class_name(widget)
##    found = require("./#{widget}")
##    code = found ? ::RuneBlog::Widget.class_eval(rclass) : nil
##    code
##  rescue => err
##    STDERR.puts err.to_s
##    STDERR.puts err.backtrace.join("\n") if err.respond_to?(:backtrace)
##    sleep 6; RubyText.stop
##    exit
##  end
##  
##  def _handle_standard_widget(tag)
##    log!(enter: __method__)
##    wtag = "../../widgets"/tag
##    Dir.chdir(wtag) do 
##      code = _load_local(tag)
##      if code 
##        widget = code.new(@blog)
##        widget.build
##      end
##    end
##  end
##  
##  def sidebar
##    log!(enter: __method__)
##    api.debug "--- handling sidebar\r"
##    $debug = true
##    if api.args.include? "off"
##      api.body { }  # iterate, do nothing
##      return 
##    end
##  
##    api.out %[<div class="col-lg-3 col-md-3 col-sm-3 col-xs-12">]
##  
##    standard = %w[pinned pages links news]
##  
##    lines = api.body.to_a
##    lines.each do |token|
##      tag = token.chomp.strip.downcase
##      wtag = "../../widgets"/tag
##      raise CantFindWidgetDir(wtag) unless Dir.exist?(wtag)
##      tcard = "#{tag}-card.html"
##      case
##        when standard.include?(tag)
##          _handle_standard_widget(tag)
##        else
##          raise "Nonstandard widget?"
##      end
##  
##      api.include_file wtag/tcard
##    end
##    api.out %[</div>]
##  rescue => err
##    puts "err = #{err}"
##    puts err.backtrace.join("\n") if err.respond_to?(:backtrace)
##    if RubyText.started?
##      puts "Sleeping 6..."
##      sleep 6; RubyText.stop
##    end
##    puts "Exiting.\n "
##    exit
##  end
##  
##  def stylesheet
##    log!(enter: __method__)
##    lines = api.body
##    url = lines[0]
##    integ = lines[1]
##    cross = lines[2] || "anonymous"
##    api.out %[<link rel="stylesheet" href="#{url}" integrity="#{integ}" crossorigin="#{cross}"></link>]
##  end
##  
##  def script
##    log!(enter: __method__)
##    lines = api.body
##    url = lines[0]
##    integ = lines[1]
##    cross = lines[2] || "anonymous"
##    api.out %[<script src="#{url}" integrity="#{integ}" crossorigin="#{cross}"></script>]
##  end

##  ###### experimental...
##  
##  class Livetext::Functions
##    def _var(name)
##      ::Livetext::Vars[name] || "[:#{name} is undefined]"
##    end
##  end
##  
##  ###
##  
##  
##  def tag_cloud
##    log!(enter: __method__)
##    title = api.data
##    title = "Tag Cloud" if title.empty?
##    open = <<-HTML
##          <div class="card mb-3">
##            <div class="card-body">
##              <h5 class="card-title">
##                <button type="button" class="btn btn-primary" data-toggle="collapse" data-target="#tag-cloud">+</button>
##                #{title}
##              </h5>
##              <div class="collapse" id="tag-cloud">
##    HTML
##    api.out open
##    api.body do |line|
##      line.chomp!
##      url, classname, cdata = line.split(",", 3)
##      main = _main(url)
##      api.out %[<a #{main} class="#{classname}">#{cdata}</a>]
##    end
##    close = %[       </div>\n    </div>\n  </div>]
##    api.out close
##  end
##  
##  def vnavbar
##    log!(enter: __method__)
##    return _make_navbar(:vert)
##  end
##  
##  def hnavbar
##    log!(enter: __method__)
##    return _make_navbar  # horiz is default
##  end
##  
##  def navbar
##    log!(enter: __method__)
##    return _make_navbar  # horiz is default
##  end
##  
##  def _make_navbar(orient = :horiz)
##    log!(enter: __method__)
##    vdir = @root/:views/@blog.view
##    # title = _var("view.title")
##  
##    if orient == :horiz
##      name = "navbar.html"
##      li1, li2 = "", ""
##      extra = "navbar-expand-lg" 
##      list1 = list2 = ""
##    else
##      name = "vnavbar.html"
##      li1, li2 = '<li class="nav-item">', "</li>"
##      extra = ""
##      list1, list2 = '<l class="navbar-nav mr-auto">', "</ul>"
##    end
##    
##    start = <<-HTML
##     <table><tr><td>
##     <nav class="navbar #{extra} navbar-light bg-light">
##        #{list1}
##    HTML
##    finish = <<-HTML
##        #{list2}
##      </nav>
##      </td></tr></table>
##    HTML
##  
##    html_file = @blog.root/:views/@blog.view/"themes/standard/banner/navbar"/name
##    output = File.new(html_file, "w")
##    output.puts start
##    lines = _read_navbar_data
##    lines = ["index  Home"] + lines  unless api.args.include?("nohome")
##    lines.each do |line|
##      basename, cdata = line.chomp.strip.split(" ", 2)
##      full = :banner/:navbar/basename+".html"
##      href_main = _main(full)
##      if basename == "index"  # special case
##        output.puts %[#{li1} <a class="nav-link" href="index.html">#{cdata}<span class="sr-only">(current)</span></a> #{li2}]
##      else
##        dir = @blog.root/:views/@blog.view/"themes/standard/banner/navbar"
##        dest = vdir/"remote/banner/navbar"/basename+".html"
##        preprocess cwd: dir, src: basename, dst: dest, call: ".nopara", vars: @blog.view.globals # , debug: true
##        output.puts %[#{li1} <a class="nav-link" #{href_main}>#{cdata}</a> #{li2}]
##      end
##    end
##    output.puts finish
##    output.close
##    return File.read(html_file)
##  end
##  
##  
##  ##################
##  # helper methods
##  ##################
##  
##  def _html_body(file, css = nil)
##    log!(enter: __method__)
##    file.puts "<html>"
##    if css
##      file.puts "    <head>"  
##      file.puts "        <style>\n#{css}\n          </style>"
##      file.puts "    </head>"  
##    end
##    file.puts "  <body>"
##    yield
##    file.puts "  </body>\n</html>"
##  end
##  
##  def _errout(*args)
##    log!(enter: __method__)
##    ::STDERR.puts args
##  end
##  def _post_lookup(postid)    # side-effect
##    log!(enter: __method__)
##    # .. = templates, ../.. = views/thisview
##  
##    view = @blog.view
##    vdir = view.dir rescue "NONAME"
##    setvar("View", view.name)
##    setvar("ViewDir", @blog.root/:views/view.name)
##  tmp = File.new("/tmp/PL-#{Time.now.to_i}.txt", "w")
##  tmp.puts "_post_lookup: blog.view = #{@blog.view.inspect}"
##  tmp.puts "_post_lookup: vdir = #{vdir}"
##    dir_posts = @vdir/:posts
##    posts = Dir.entries(dir_posts).grep(/^\d\d\d\d/).map {|x| dir_posts/x }
##    posts.select! {|x| File.directory?(x) }
##  
##  tmp.puts "_post_lookup: postid = #{postid}"
##  tmp.puts "_post_lookup: posts  = \n#{posts.inspect}"
##  tmp.close
##    posts = posts.select {|x| File.basename(x).to_i == postid }
##    postdir = exactly_one(posts, posts.inspect)
##    vp = RuneBlog::ViewPost.new(@blog.view, postdir)
##    vp
##  end
##  
##  def _card_generic(card_title:, middle:, extra: "")
##    log!(enter: __method__)
##    front = <<-HTML
##      <div class="card #{extra} mb-3">
##        <div class="card-body">
##          <h5 class="card-title">#{card_title}</h5>
##    HTML
##  
##    tail = <<-HTML
##        </div>
##      </div>
##    HTML
##    text = front + middle + tail
##    api.out text + "\n "
##  end
##  
##  def _var(name)
##    log!(enter: __method__)
##    ::Livetext::Vars[name] || "[:#{name} is undefined]"
##  end
##  
##  def _main(url)
##    log!(enter: __method__)
##    %[href="javascript: void(0)" onclick="javascript:open_main('#{url}')"]
##  end
##  
##  def _blank(url)
##    log!(enter: __method__)
##    %[href='#{url}' target='blank']
##  end
##  

def syntax_css
  log!(enter: __method__)
  highlighter = Scriptorium::SyntaxHighlighter.new
  css = highlighter.generate_css
  api.out %[<style>\n#{css}\n</style>]
rescue => e
  # Fallback to basic CSS if highlighting fails
  basic_css = <<~CSS
    <style>
    /* Basic syntax highlighting styles */
    pre code {
      font-family: 'Consolas', 'Monaco', 'Andale Mono', monospace;
      font-size: 14px;
      line-height: 1.4;
      background: #f5f2f0;
      padding: 1em;
      border-radius: 4px;
      overflow-x: auto;
    }
    </style>
  CSS
  api.out basic_css
end
