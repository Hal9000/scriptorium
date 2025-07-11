class Scriptorium::View
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  attr_reader :name, :title, :subtitle, :theme, :dir

  def self.create_sample_view(repo)
    repo.create_view("sample", "My first view", "This is just a sample")
    repo.generate_front_page("sample")
  end

  def initialize(name, title, subtitle = "", theme = "standard")
    @name, @title, @subtitle, @theme = name, title, subtitle, theme
    @root = Scriptorium::Repo.root
    @repo = Scriptorium::Repo.repo
    @dir = "#@root/views/#{name}"
    @predef = Scriptorium::StandardFiles.new
  end

=begin
1. The theme provides layout/config/header.txt with default content instructions.
2. When the theme is applied, header.txt is copied to views/VIEW/config/.
3. A placeholder layout/header.html is created in views/VIEW/layout/ with <!-- HEADER CONTENT -->.
4. The file views/VIEW/config/header.txt is parsed to generate actual HTML.
5. That HTML replaces the placeholder and is written to views/VIEW/output/panes/header.html.
6. Later, output/panes/header.html is included when assembling views/VIEW/output/index.html.

That process is clean and logical. I see only minor points worth considering:

Copying header.txt from theme to view config/ is irreversible by design—once copied, 
any theme updates won’t affect the view’s header.txt. That’s good for isolation, but 
it might be worth exposing a way to “reapply” or “sync” a theme’s layout/config/ 
if desired.
Placeholder files like layout/header.html in layout/ may be unnecessary once 
output/panes/header.html is reliably generated. If they exist solely for the 
<!-- CONTENT --> tags, consider templating that in-memory instead.
You may want to enforce (or warn) if config/header.txt is missing or invalid 
at generation time, to catch misconfigured views.
If you add more optional components (like navbars, banners, etc.), consider 
adding light validation or doc comments to header.txt to aid future users/editors.

But overall, the process is robust and well thought-out. No major changes needed.
=end

  def read_layout
    layout_file = @dir/:config/"layout.txt"
    lines = read_commented_file(layout_file)
    lines.map! {|line| line.split(/\s+/, 2).first}
    directives = %w[header footer left right main]
    lines.each {|line| raise LayoutHasUnknownTag unless directives.include?(line)}
    directives.each {|line| raise LayoutHasDuplicateTags if lines.count(line) > 1}
    lines
  end

  private def generate_empty_containers
    layout_file = @dir/:config/"layout.txt"
    return unless File.exist?(layout_file)

    flexing = {
      header: %[class="header" style="background: lightgray; padding: 10px;"],
      footer: %[class="footer" style="background: lightgray; padding: 10px;"],
      left:   %[class="left" style="width: 15%; background: #f0f0f0; padding: 10px; flex-grow: 0; flex-shrink: 0;"],
      right:  %[class="right" style="width: 15%; background: #f0f0f0; padding: 10px; flex-grow: 0; flex-shrink: 0;"],
      main:   %[class="main" style="flex-grow: 1; padding: 10px;"]
    }
    lines = read_layout
    lines.each do |section|
      filename = @dir/:layout/"#{section}.html"
      tag = section   # header, footer, main
      tag = "aside" if section == 'left' || tag == 'right'
    
      content = <<~HTML
        <#{tag} #{flexing[section.to_sym]}>
          <!-- Section: #{section} -->
        </#{tag}>
      HTML

      File.write(filename, content)
    end
  end

  def theme(change = nil)
    return @theme if change.nil?
    # what if it doesn't exist?
    raise ThemeDoesntExist unless Dir.exist?(@root/:themes/change)
    @theme = change
    change_config(@dir/"config.txt", "theme", change)
    apply_theme(change)
  end

  def apply_theme(theme)
    # check to see if ever done before?
    # copy layout.txt to view
    t = Scriptorium::Theme.new(@root, theme)
    FileUtils.cp(t.file("layout.txt"), @dir/:config)
    # copy other .txt to view?  header, footer, ...
    names = %w[header footer left right main]
    lay = @root/:themes/theme/:layout
    names.each do |name|
      f1, f2 = lay/:config/"#{name}.txt", dir/:config
      FileUtils.cp(f1, f2)
    end
    generate_empty_containers
  end

  def content_tag(section)
    "<!-- Section: #{section} -->"
  end

  def placeholder_text(str)
    if str.start_with?("@")
      file = @dir/:config/:text/"#{str[1..]}"
      File.exist?(file) ? File.read(file) : "[Missing: #{file}]"
    else
      str
    end
  end

  def section_append(sec, str)
    file = @dir/:config/"#{sec}.txt"
    text = File.read(file)
    text << str
    write_file(file, text)
  end

  def section_hash(section)
    hash = Hash.new { |hash, key| ->(arg = nil) { "<!-- Not defined for key: #{key} -->\n" } }
    hash["text"] = ->(arg) { "  <p>" + placeholder_text(arg) + "</p>\n" }
    hash
  end

  def section_core(section, hash)
    cfg = @dir/:config
    template = @dir/:layout/"#{section}.html"  # FIXME - what if no template?
    sectxt = cfg/"#{section}.txt"
    section_append(section, "\ntext This is #{section}...") unless section == "main"
    lines = read_commented_file(sectxt)
    result = "<!-- Section: #{section} (output) -->\n"
    lines.each do |line|
      component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
      result << hash[component.downcase].call(arg)
    end
    result
  end

=begin
To build a header, I start with  two things: 
   config/header.txt (which is user-supplied and has things such as "title" in it); and 
   layout/header.html (which is a template with <header> tags enclosing at least a line 
        like "<!-- Section: header -->"

get core:          I process header.txt line by line, gathering the "core" or "guts" of the header.
sub into template: I substitute this into the template contents and 
write output:      write the result to output/panes/header.html
=end

  def build_section(section, hash2 = {})
    config = @dir/:config/"#{section}.txt"
    template = @dir/:layout/"#{section}.html"
    output = @dir/:output/:panes/"#{section}.html"
    hash = section_hash(section)
    hash.merge!(hash2)
    core = section_core(section, hash)
    temp_txt = File.read(template)
    target = content_tag(section)
    temp_txt.sub!(target, core)
    write_file(output, temp_txt)
    html = File.read(output)
    html
  end

  def build_header
    h2 = { 
      "title" => ->(arg = nil) { "  <h1>#{escape_html(@title)}</h1>" },
      "subtitle" => ->(arg = nil) { "  <p>#{escape_html(@subtitle)}</p>" },
      "nav" => ->(arg = nil) { build_nav(arg) },
      "banner" => ->(arg = nil) { build_banner(arg) }
    }

    build_section("header", h2)
  end
  
  ### Helpers for header

  def build_banner(arg)
    image_path = @dir/:assets/"#{arg}"
    if File.exist?(image_path)
      html = %[<img src='#{image_path}' alt='Banner Image' style='width: 100%; height: auto;' />]
      return html
    else
      # warn "[build_banner] Missing banner image: #{arg}"
      html = %[<p>Banner image missing: #{arg}</p>]
      return html
    end
  end

  def build_nav(arg)
    nav_file = @dir/:config/"#{arg}"
    
    # Check if the topmenu.txt file exists
    if File.exist?(nav_file)
      nav_content = File.read(nav_file)
    else
      # If the file does not exist, return a default message or placeholder
      nav_content = "<p>Navigation not available</p>"
    end
  
    # Wrap the nav content in the appropriate container
    html = <<~HTML
      <nav class="topmenu">
        #{nav_content}
      </nav>
    HTML
    
    # Return the generated HTML for the navigation section
    html
  end
  

  ###

  def build_footer
    build_section("footer")
  end
  
  def build_left
    build_section("left")
  end

  def build_right
    build_section("right")
  end

  def build_main
    html = "  <!-- Section: main (output) -->\n"
    html << %[<div id="main" class="main" style="flex-grow: 1; padding: 10px;">\n]
    html << @predef.post_index_style
    if view_posts.empty?
      html << "  <h1>No posts yet!</h1>"
    else
      html << post_index_array.join("\n")
    end
    html << "</div> <!-- end main -->\n"
  end

  def generate_post_index
    posts = @repo.all_posts(self)  # sort by pubdate  # FIXME - move later
    str = ""
    # FIXME - many decisions to make here...
    posts.each do |post|
      str << post_index_entry(post)
    end
    write_file(@dir/:output/"post_index.html", str)    
  end

  def post_index_entry(post)
      # grab index-entry template
      # generate index-entry for each post
      # append to str
    num, title, pubdate, blurb = post.attrs(:id, :title, :pubdate, :blurb)
    template = @predef.index_entry
    entry = substitute(post, template)
    entry
  end

def post_index_array
  posts = view_posts
  posts.map {|post| post_index_entry(post)}
end

def view_posts
  posts = []
  @repo.all_posts(self).sort_by {|post| post.pubdate}
end

def generate_html_head(view = nil)
  # FIXME - view does not yet override global
  global_head = @root/:config/"global-head.txt"
  view_head   = @dir/:config/"global-head.txt"
  head_file = view ? view_head : global_head
  which = view ? "view" : "global"
  line1 = "<!-- head info from #{which} -->"
  lines = read_commented_file(head_file)
  content = "<head>\n#{line1}\n<title>#{@title}</title>\n"
  lines.each do |line|
    component, args = line.split(/\s+/, 2)
    case component.downcase
    when "charset"
      @charset = args
      content << %[<meta charset="#{args}">\n]
    when "desc"
      @desc = args
      content << %[<meta name="description" content="#{args}">\n]
    when "viewport"
      @viewport = args
      str = args.split.join(" ")
      content << %[<meta name="viewport" content="#{str}">\n]
    when "robots"
      @robots = args
      str = args.split.join(", ")  
      content << %[<meta name="robots" content="#{str}">\n]
    when "javascript"
      content = get_common_js(view)
    when "bootstrap"
      content << generate_bootstrap_url(view)
    end
  end
  content << "</head>\n"
  content
end

def get_common_js(view = nil)
  global_js = @root/:config/"common.js"
  view_js   = @dir/:config/"common.js"
  js_file = view ? view_js : global_js
  File.read(js_file)
  return %[<script src="#{js_file}"></script>\n]
end

def generate_bootstrap_url(view = nil)
  global_boot = @root/:config/"bootstrap.txt"
  view_boot   = @dir/:config/"bootstrap.txt"
  bs_file = view ? view_boot : global_boot
  lines = read_commented_file(bs_file)
  href = rel = integrity = crossorigin = nil
  lines.each do |line|
    component, args = line.split(/\s+/, 2)
    case component.downcase
    when "href"
      href = args
    when "rel"
      rel = args
    when "integrity"
      integrity = args
    when "crossorigin"
      crossorigin = args
    end
  end
  content = %[<link rel="#{rel}" href="#{href}" integrity="#{integrity}" crossorigin="#{crossorigin}">\n]
  content
end

def generate_front_page
  layout_file = @dir/:config/"layout.txt"
  index_file  = @dir/:output/"index.html"
  panes       = @dir/:output/:panes

  sections = read_layout
  html_head = generate_html_head(true)

  content = ""
  content << build_header
  content << "<div style='display: flex; flex-grow: 1;'> <!-- before left/main/right -->\n"
  content << build_left
  content << build_main
  content << build_right
  content << "</div> <!-- after left/main/right --></div>\n"
  content << build_footer

  full_html = <<~HTML
    <!DOCTYPE html>
    <html>
    #{html_head}
    <body>
        #{content.strip}
    </body>
    </html>
  HTML

  write_file(index_file, full_html)
  write_file("/tmp/full.html", full_html) # debugging
end


end
