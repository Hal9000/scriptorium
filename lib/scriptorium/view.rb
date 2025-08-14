require 'fileutils'
require_relative 'syntax_highlighter'

class Scriptorium::View
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include Scriptorium::Contract

  attr_reader :name, :title, :subtitle, :theme, :dir

  def self.create_sample_view(repo)
    repo.create_view("sample", "My first view", "This is just a sample")
    # repo.generate_front_page("sample")
  end

  # Invariants
  def define_invariants
    invariant { @name.is_a?(String) && !@name.empty? }
    invariant { @title.is_a?(String) && !@title.empty? }
    invariant { @subtitle.is_a?(String) }
    invariant { @theme.is_a?(String) && !@theme.empty? }
    invariant { @root.is_a?(String) && !@root.empty? }
    invariant { @repo.is_a?(Scriptorium::Repo) }
    invariant { @dir.is_a?(String) && !@dir.empty? }
  end

  def initialize(name, title, subtitle = "", theme = "standard")
    assume { name.is_a?(String) }
    assume { title.is_a?(String) }
    assume { subtitle.is_a?(String) }
    assume { theme.is_a?(String) }
    
    validate_name(name)
    validate_title(title)
    
    @name, @title, @subtitle, @theme = name, title, subtitle, theme
    @root = Scriptorium::Repo.root
    @repo = Scriptorium::Repo.repo
    @dir = "#@root/views/#{name}"
    @predef = Scriptorium::StandardFiles.new
    
    define_invariants
    verify { @name == name }
    verify { @title == title }
    check_invariants
  end

  def inspect
    "<View: #@name #{@title.inspect} theme: #@theme>"
  end

  private def validate_name(name)
    raise ViewNameNil if name.nil?
    
    raise ViewNameEmpty if name.to_s.strip.empty?
    
    unless name.match?(/^[a-zA-Z0-9_-]+$/)
      raise ViewNameInvalid(name)
    end
  end

  private def validate_title(title)
    raise ViewTitleNil if title.nil?
    
    raise ViewTitleEmpty if title.to_s.strip.empty?
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
    
    need(:file, layout_file, LayoutFileMissing)
    
    lines = read_commented_file(layout_file)
    containers = {}
    secs = []
    lines.each do |line| 
      sec, args = line.split(/\s+/, 2)
      containers[sec] = (args || "")
      secs << sec
    end
    directives = %w[header footer left right main]
    secs.each {|sec| raise LayoutHasUnknownTag(sec) unless directives.include?(sec)}
    directives.each {|sec| raise LayoutHasDuplicateTags(sec) if lines.count(sec) > 1}
    containers
  end

  def generate_empty_containers
    layout_file = @dir/:config/"layout.txt"
    return unless File.exist?(layout_file)

    flexing = {
      header: %[id="header" class="header" style="padding: 10px;"],
      footer: %[class="footer" style="background: lightgray; padding: 10px;"],
      left:   %[class="left" style="width: %{width}; background: #f0f0f0; padding: 10px; flex-grow: 0; flex-shrink: 0;"],
      right:  %[class="right" style="width: %{width}; background: #f0f0f0; padding: 10px; flex-grow: 0; flex-shrink: 0;"],
      main:   %[class="main" style="flex-grow: 1; padding: 10px;"]
    }
    sections = read_layout
    lines = sections.keys
    # FIXME Pleeeease refactor this.
    lines.each do |section|
      args  = sections[section]  # like 20% for right, left
      filename = @dir/:layout/"#{section}.html"
      tag = section   # header, footer, main
      tag = "aside" if section == 'left' || tag == 'right'
    
      inline = flexing[section.to_sym]
      if section == "left" || section == "right"
        mod = {width: args}
        inline = inline % mod
      end
      content = <<~HTML
        <#{tag} #{inline}>
          <!-- Section: #{section} -->
        </#{tag}>
      HTML

      write_file(filename, content)
    end
  end

  def theme(change = nil)
    return @theme if change.nil?
    # what if it doesn't exist?
    need(:dir, @root/:themes/change, ThemeDoesntExist)
    @theme = change 
    change_config(@dir/"config.txt", "theme", change)
    apply_theme(change)
  end

  def apply_theme(theme)
    check_invariants
    assume { theme.is_a?(String) && !theme.empty? }
    
    # check to see if ever done before?
    # copy layout.txt to view
    t = Scriptorium::Theme.new(@root, theme)
    need(:file, t.file("layout.txt"), ThemeFileNotFound)
    FileUtils.cp(t.file("layout.txt"), @dir/:config)
    # copy other .txt to view?  header, footer, ...
    names = %w[header footer left right main]
    lay = @root/:themes/theme/:layout
    names.each do |name|
      f1, f2 = lay/:config/"#{name}.txt", dir/:config
      need(:file, f1, ThemeFileNotFound)
      FileUtils.cp(f1, f2)
    end
    generate_empty_containers
    
    verify { @theme == theme }
    check_invariants
  end

  def content_tag(section)
    "<!-- Section: #{section} -->"
  end

  def placeholder_text(str)
    if str.start_with?("@")
      file = @dir/:config/:text/"#{str[1..]}"
      read_file(file, missing_fallback: "[Missing: #{file}]")
    else
      str
    end
  end

  def section_append(sec, str)
    file = @dir/:config/"#{sec}.txt"
    text = read_file(file)
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
    sectxt = cfg/"#{section}.txt"
    
    # Only add placeholder if section has no real content
    lines = read_commented_file(sectxt)
    if lines.empty? && section != "main"
      section_append(section, "\ntext This is #{section}...")
      lines = read_commented_file(sectxt)
    end
    
    result = "<!-- Section: #{section} (output) -->\n"
    lines.each do |line|
      component, arg = line.split(/\s+/, 2)
      
      # Handle malformed config lines
      if component.nil? || component.strip.empty?
        result << "<!-- Invalid config line: #{line.inspect} -->\n"
        next
      end
      
      component = component.downcase
      if hash.key?(component)
        result << hash[component].call(arg)
      else
        result << "<!-- Unknown component: #{component} -->\n"
      end
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

  def build_section(section, hash2 = {}, args = "")
    template = @dir/:layout/"#{section}.html"
    output = @dir/:output/:panes/"#{section}.html"
    
    # Ensure output directory exists
    FileUtils.mkdir_p(File.dirname(output))
    
    # Check if template exists
    need(:file, template)
    
    hash = section_hash(section)
    hash.merge!(hash2)
    core = section_core(section, hash)
    
    temp_txt = read_file(template)
    
    target = content_tag(section)
    temp_txt.sub!(target, core)
    
    write_file(output, temp_txt)
    
    html = read_file(output)
    html
  end

  def build_header(sections)
    args = sections["header"]
    return "" unless args
    h2 = { 
      "title"      => ->(arg = nil) { "  <h1>#{escape_html(@title)}</h1>" },
      "subtitle"   => ->(arg = nil) { "  <p>#{escape_html(@subtitle)}</p>" },
      "nav"        => ->(arg = nil) { build_nav(arg) },
      "banner"     => ->(arg = nil) { build_banner(arg) }
    }

    build_section("header", h2, args)
  end
  
  ### Helpers for header

  def build_banner(arg)
    # Check if this is an SVG banner request
    return build_banner_svg_from_file if arg == "svg"
    
    # Otherwise, treat as image filename
    return build_banner_image(arg)
  end

  def build_banner_svg_from_file
    bsvg = Scriptorium::BannerSVG.new(@title, @subtitle)
    
    # Look for svg.txt file in the view's config directory
    svg_config_file = @dir/:config/"svg.txt"
    if File.exist?(svg_config_file)
      bsvg.parse_header_svg(svg_config_file)
    else
      # No svg.txt file, use defaults
      bsvg.parse_header_svg
    end
    
    bsvg.get_svg
  end

  def build_banner_image(image_filename)
    # Search for image in multiple locations
    image_paths = [
      @dir/:assets/image_filename,           # view/assets/
      @repo.root/:assets/image_filename,     # repo/assets/
    ]
    
    # Find the first existing image
    image_path = image_paths.find { |path| File.exist?(path) }
    
    if image_path
      # Use relative path for the img src
      if image_path.to_s.start_with?(@dir.to_s)
        # Image is in view directory, use relative path
        relative_path = image_path.to_s.sub(@dir.to_s + "/", "")
      else
        # Image is in repo directory, use relative path from view
        relative_path = "../assets/#{image_filename}"
      end
      html = %[<img src='#{relative_path}' alt='Banner Image' style='width: 100%; height: auto;' />]
      return html
    else
      # Try to copy from global assets
      global_assets_dir = @repo.root/:assets
      global_image_path = global_assets_dir/image_filename
      
      if File.exist?(global_image_path)
        # Copy to view assets
        view_assets_dir = @dir/:assets
        make_dir(view_assets_dir) unless Dir.exist?(view_assets_dir)
        FileUtils.cp(global_image_path, view_assets_dir/image_filename)
        
        # Use relative path
        relative_path = "assets/#{image_filename}"
        html = %[<img src='#{relative_path}' alt='Banner Image' style='width: 100%; height: auto;' />]
        return html
      else
        # Image not found anywhere
        html = %[<p>Banner image missing: #{image_filename}</p>]
        return html
      end
    end
  end

  def build_banner_svg(arg)
    bsvg = Scriptorium::BannerSVG.new(@title, @subtitle)
    
    # Look for config file in the view's config directory
    config_file = @dir/:config/"config.txt"
    if File.exist?(config_file)
      bsvg.parse_header_svg(config_file)
    else
      # No config file, just use defaults
      bsvg.parse_header_svg
    end
    
    bsvg.get_svg
  end

  def build_nav(arg)
    # Determine navbar file - if no arg, use navbar.txt, otherwise use specified file
    nav_file = if arg.nil? || arg.strip.empty?
      @dir/:config/"navbar.txt"
    else
      @dir/:config/"#{arg}"
    end
    
    # Read navbar content with fallback for missing files
    nav_content = read_file(nav_file, missing_fallback: "<p>Navigation not available</p>")
    
    # Parse and generate Bootstrap navbar
    generate_bootstrap_navbar(nav_content)
  end

  def generate_bootstrap_navbar(nav_content)
    menu_items = parse_navbar_content(nav_content)
    
    # Generate Bootstrap navbar HTML
    html = <<~HTML
      <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="container-fluid">
          <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
          </button>
          <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav">
              #{generate_navbar_items(menu_items)}
            </ul>
          </div>
        </div>
      </nav>
    HTML
    
    html
  end

  def parse_navbar_content(content)
    menu_items = []
    current_dropdown = nil
    
    content.lines.each do |line|
      line = line.rstrip  # Keep leading spaces, remove trailing
      next if line.empty? || line.start_with?('#')
      
      if line.start_with?('=')
        # Top-level dropdown item
        label = line[1..-1].strip
        current_dropdown = { type: :dropdown, label: label, children: [] }
        menu_items << current_dropdown
      elsif line.start_with?(' ')
        # Child of previous dropdown
        if current_dropdown
          # Remove leading spaces and split on multiple spaces
          clean_line = line.strip
          if clean_line.include?('  ')  # Look for multiple spaces
            parts = clean_line.split(/\s{2,}/, 2)  # Split on 2+ spaces
            if parts.length >= 2
              title, filename = parts[0], parts[1]
              current_dropdown[:children] << { type: :child, title: title, filename: filename }
            end
          end
        end
      elsif line.start_with?('-')
        # Top-level item (no children)
        clean_line = line[1..-1].strip
        if clean_line.include?('  ')  # Look for multiple spaces
          parts = clean_line.split(/\s{2,}/, 2)  # Split on 2+ spaces
          if parts.length >= 2
            title, filename = parts[0], parts[1]
            menu_items << { type: :item, title: title, filename: filename }
          end
        end
      end
    end
    
    menu_items
  end

  def generate_navbar_items(menu_items)
    html = ""
    
    menu_items.each do |item|
      case item[:type]
      when :dropdown
        html << generate_dropdown_item(item)
      when :item
        html << generate_nav_item(item)
      end
    end
    
    html
  end

  def generate_dropdown_item(item)
    html = <<~HTML
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
          #{escape_html(item[:label])}
        </a>
        <ul class="dropdown-menu">
    HTML
    
    item[:children].each {|child| html << generate_dropdown_child(child) }
    
    html << <<~HTML
        </ul>
      </li>
    HTML
    
    html
  end

  def generate_dropdown_child(child)
    link_url, warning = get_page_link(child[:filename])
    
    html = <<~HTML
      <li><a class="dropdown-item" href="javascript:void(0)" onclick="load_main('#{link_url}')">#{escape_html(child[:title])}</a></li>
    HTML
    
    html << "<!-- #{warning} -->\n" if warning
    
    html
  end

  def generate_nav_item(item)
    link_url, warning = get_page_link(item[:filename])
    
    html = <<~HTML
      <li class="nav-item">
        <a class="nav-link" href="javascript:void(0)" onclick="load_main('#{link_url}')">#{escape_html(item[:title])}</a>
      </li>
    HTML
    
    html << "<!-- #{warning} -->\n" if warning
    
    html
  end

  def get_page_link(filename)
    # Check if the page file exists
    page_file = @dir/:pages/"#{filename}.html"
    
    if File.exist?(page_file)
      # Page exists, return relative path
      link_url = "pages/#{filename}.html"
      warning = nil
    else
      # Page doesn't exist, still create link but warn
      link_url = "pages/#{filename}.html"
      warning = "Warning: Page file '#{filename}.html' not found in pages directory"
    end
    
    [link_url, warning]
  end
  
  def build_widgets(arg)
    check_invariants
    assume { arg.is_a?(String) }
    validate_widget_arg(arg)
    
    widgets = arg.split
    content = ""
    widgets.each do |widget|
      validate_widget_name(widget)
      
      widget_class = eval("Scriptorium::Widget::#{widget.capitalize}")
      obj = widget_class.new(@repo, self)
      obj.generate
      content << obj.card
    end
    verify { content.is_a?(String) }
    check_invariants
    content
  end

  private def validate_widget_arg(arg)
    raise WidgetsArgNil if arg.nil?
    
    raise WidgetsArgEmpty if arg.to_s.strip.empty?
  end

  private def validate_widget_name(name)
    raise WidgetNameNil if name.nil? || name.strip.empty?
    
    unless name.match?(/^[a-zA-Z0-9_]+$/)
      raise WidgetNameInvalid(name)
    end
  end

  ###

  def build_footer(sections)
    args = sections["footer"]
    return "" unless args
    build_section("footer", {}, args)
  end
  
  def build_left(sections)
    args = sections["left"]
    return "" unless args
    h2 = { "widget" => ->(arg = nil) { build_widgets(arg) } }
    build_section("left", h2, args)
  end

  def build_right(sections)
    args = sections["right"]
    return "" unless args
    h2 = { "widget" => ->(arg = nil) { build_widgets(arg) } }
    build_section("right", h2, args)
  end

  def build_main(sections)
    args = sections["main"]
    return "" unless args
    html = "  <!-- Section: main (output) -->\n"
    html << %[  <div id="main" class="main" style="flex-grow: 1; padding: 10px; overflow-y: auto; position: relative; display: flex; flex-direction: column;">]
    # html << %[<div id="main" class="main" style="position: relative; display: flex; flex-direction: column;">\n]
    html << @predef.post_index_style
    if view_posts.empty?
      html << "  <h1>No posts yet!</h1>"
    else
      paginate_posts
      need(:file, self.dir/:output/"post_index.html")
      html << read_file(self.dir/:output/"post_index.html")
    end
    html << "</div> <!-- end main -->\n"
  end

  def generate_post_index
    posts = @repo.all_posts(self) 
    str = ""
    # FIXME - many decisions to make here...
    posts.each {|post| str << post_index_entry(post) }
    write_file(@dir/:output/"post_index.html", str)    
  end

  def post_index_entry(post)
    template = @predef.index_entry
    entry = substitute(post, template)
    entry
  end

  def post_index_array
    posts = view_posts.sort {|a,b| cf_time(b.pubdate, a.pubdate) }
    posts.map {|post| post_index_entry(post)}
  end

  def view_posts
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
      # when "javascript"
      #   content << get_common_js(view)
      when "bootstrap"
        content << generate_bootstrap_css(view)
      when "social"
        content << generate_social_meta_tags(args)
      when "syntax"
        content << generate_syntax_css
      end
    end
    content << "</head>\n"
    content
  end

  def get_common_js(view = nil)
    global_js = @root/:config/"common.js"
    view_js   = @dir/:config/"common.js"
    js_file = view ? view_js : global_js
    code = read_file(js_file)
    return %[<script>#{code}</script>\n]
  end

  def generate_bootstrap_css(view = nil)
    global_boot = @root/:config/"bootstrap_css.txt"
    view_boot   = @dir/:config/"bootstrap_css.txt"
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
    # content = %[<link rel="#{rel}" href="#{href}" integrity="#{integrity}" crossorigin="#{crossorigin}">\n]
    content = %[<link rel="stylesheet" href="#{href}"></link>\n]
    content
  end



  def generate_bootstrap_js(view = nil)
    global_boot = @root/:config/"bootstrap_js.txt"
    view_boot   = @dir/:config/"bootstrap_js.txt"
    bs_file = view ? view_boot : global_boot
    lines = read_commented_file(bs_file)
    src = integrity = crossorigin = nil
    lines.each do |line|
      component, args = line.split(/\s+/, 2)
      case component.downcase
      when "src"
        src = args
      when "rel"
        # rel = args
      when "integrity"
        integrity = args
      when "crossorigin"
        crossorigin = args
      end
    end
    # content = %[<script src="#{src}" integrity="#{integrity}" crossorigin="#{crossorigin}"></script>\n]
    content = %[<script src="#{src}"></script>\n]
    content
  end

  def generate_social_meta_tags(args = nil, post_data = nil)
    # Check if social is enabled for this view
    social_config_file = @dir/:config/"social.txt"
    return "" unless File.exist?(social_config_file)
    
    # Read social configuration
    social_config = read_commented_file(social_config_file)
    platforms = []
    
    # Each non-comment line is a platform name
    social_config.each do |line|
      platform = line.strip.downcase
      platforms << platform if platform.match?(/^(facebook|twitter|linkedin|reddit)$/)
    end
    
    return "" if platforms.empty?
    
    # Determine if this is for a specific post or the main page
    is_post = !post_data.nil?
    
    # Get the appropriate title, description, and URL
    if is_post
      title = post_data[:"post.title"] || @title
      description = post_data[:"post.blurb"] || (post_data[:"post.body"] ? post_data[:"post.body"][0..200] : nil) || @desc || @subtitle || @title
      slug = post_data[:"post.slug"] || (post_data[:"post.id"] ? slugify(post_data[:"post.id"], title) : 'post')
      url = "posts/#{slug}#{slug.end_with?('.html') ? '' : '.html'}"
      type = "article"
    else
      title = @title
      description = @desc || @subtitle || @title
      url = "index.html"
      type = "website"
    end
    
    # Generate meta tags
    content = ""
    
    # Open Graph meta tags (Facebook, LinkedIn, etc.)
    if platforms.include?("facebook") || platforms.include?("linkedin")
      content << %[<meta property="og:title" content="#{escape_html(title)}">\n]
      content << %[<meta property="og:type" content="#{type}">\n]
      content << %[<meta property="og:url" content="#{url}">\n]
      content << %[<meta property="og:description" content="#{escape_html(description)}">\n]
      content << %[<meta property="og:site_name" content="#{escape_html(@title)}">\n]
      if is_post && post_data[:"post.pubdate"]
        content << %[<meta property="article:published_time" content="#{post_data[:"post.pubdate"]}">\n]
      end
    end
    
    # Twitter Card meta tags
    if platforms.include?("twitter")
      content << %[<meta name="twitter:card" content="summary">\n]
      content << %[<meta name="twitter:title" content="#{escape_html(title)}">\n]
      content << %[<meta name="twitter:description" content="#{escape_html(description)}">\n]
      content << %[<meta name="twitter:url" content="#{url}">\n]
    end
    
    content
  end

  def generate_reddit_button(post_data = nil)
    # Check if Reddit is enabled in social config
    social_config_file = @dir/:config/"social.txt"
    return "" unless File.exist?(social_config_file)
    
    social_config = read_commented_file(social_config_file)
    reddit_enabled = social_config.any? { |line| line.strip.downcase == "reddit" }
    return "" unless reddit_enabled
    
    # Check if Reddit button is enabled
    reddit_config_file = @dir/:config/"reddit.txt"
    return "" unless File.exist?(reddit_config_file)
    
    reddit_config = read_commented_file(reddit_config_file)
    button_enabled = false
    subreddit = ""
    hover_text = ""
    
    reddit_config.each do |line|
      component, args = line.split(/\s+/, 2)
      case component.downcase
      when "button"
        button_enabled = (args&.downcase == "true")
      when "subreddit"
        subreddit = args&.strip || ""
      when "hover_text"
        hover_text = args&.strip || ""
      end
    end
    
    return "" unless button_enabled
    
    # Determine post URL and title
    if post_data
      title = post_data[:"post.title"] || @title
      slug = post_data[:"post.slug"] || slugify(post_data[:"post.id"], title)
      url = "posts/#{slug}#{slug.end_with?('.html') ? '' : '.html'}"
    else
      title = @title
      url = "index.html"
    end
    
    # Build Reddit share URL
    require 'uri'
    encoded_title = URI.encode_www_form_component(title)
    if subreddit.empty?
      reddit_url = "https://reddit.com/submit?url=#{escape_html(url)}&title=#{encoded_title}"
    else
      reddit_url = "https://reddit.com/r/#{subreddit}/submit?url=#{escape_html(url)}&title=#{encoded_title}"
    end
    
    # Determine hover text
    if hover_text.empty?
      hover_text = subreddit.empty? ? "Share on Reddit" : "Share on r/#{subreddit}"
    end
    
    # Generate button HTML
    button_html = %[<a href="#{reddit_url}" target="_blank" title="#{hover_text}" style="text-decoration: none; margin-right: 8px;">
      <img src="assets/reddit-logo.png" width="16" height="16" alt="Share on Reddit" style="vertical-align: middle;">
    </a>]
    
    button_html
  end

  def build_containers
    sections = read_layout
    content = ""
    content << build_header(sections)
    content << "<!-- before left/main/right -->\n"
    content << "<div style='display: flex; flex-grow: 1; height: 100%; flex-direction: row;'>"
    content << build_left(sections)
    content << build_main(sections)
    content << build_right(sections)
    content << "</div> <!-- after left/main/right --></div>\n"
    content << build_footer(sections)
    content
  end

  def pagination_bar(group, count, nth)  # nth group of total 'count'
    str = %[<div style="align-self: flex-end;">Pages: ]
    1.upto(count) do |i|
      if i == nth  # 0-based
        str << "<b>[#{i}]</b>&nbsp;&nbsp;"
      else
        str << %[<a href="javascript:void(0)" style="text-decoration: none;"
                  onclick="load_main('page#{i}.html')">#{i}&nbsp;&nbsp;</a>]
      end
    end
    str << "<br><br></div>"
  end

  def paginate_posts
    posts = @repo.all_posts(self)
    posts.sort! {|a,b| cf_time(b.pubdate, a.pubdate) }
    ppp = 10  # FIXME posts per page
    pages = []
    posts.each_slice(ppp).with_index do |group, i|
      pages << group.map {|post| post_index_entry(post) }
    end
    out = self.dir/:output
    pages.each.with_index do |page, i|
      bar = pagination_bar(page, pages.size, i+1)
      page << %[<div style="position: absolute; bottom: 0; width: 100%;">#{bar}</div>]
      write_file(out/"page#{i+1}.html", page.join)
    end
    # Remove existing link if it exists, then create new one
    post_index_link = out/"post_index.html"
    File.delete(post_index_link) if File.exist?(post_index_link)
    FileUtils.ln(out/"page1.html", post_index_link)
  end

  def generate_front_page
    index_file  = @dir/:output/"index.html"
    FileUtils.mkdir_p(File.dirname(index_file))

    html_head = generate_html_head(true)
    content = build_containers
    common = get_common_js
    boot   = generate_bootstrap_js
    full_html = <<~HTML
      <!DOCTYPE html>
      #{html_head}
      <html style="height: 100%; margin: 0;">
        <body style="height: 100%; margin: 0; display: flex; flex-direction: column;">
          #{content.strip}
          #{boot.strip}
          #{common.strip}
        </body>
      </html>
    HTML

    # Beautify HTML if HtmlBeautifier is available
    begin
      full_html = ::HtmlBeautifier.beautify(full_html)
    rescue NameError, LoadError => e
      # HtmlBeautifier not available, continue without beautification
      # This is not critical for functionality
    end

    # Write the main index file
    write_file(index_file, full_html)

    # Write debug file (optional, don't fail if it doesn't work)
    begin
      write_file("/tmp/full.html", full_html)
    rescue => e
      # Debug file write failed, but this is not critical
    end

    # Copy pages directory to output if it exists
    pages_source = @dir/:pages
    pages_output = @dir/:output/:pages
    if Dir.exist?(pages_source)
      FileUtils.mkdir_p(pages_output)
      Dir.glob(pages_source/"*").each do |file|
        next unless File.file?(file)
        FileUtils.cp(file, pages_output/File.basename(file))
      end
    end
  end

  def generate_syntax_css
    highlighter = Scriptorium::SyntaxHighlighter.new
    "<style>\n#{highlighter.generate_css}\n</style>\n"
  end

  def highlight_code(code, language = nil)
    highlighter = Scriptorium::SyntaxHighlighter.new
    highlighter.highlight(code, language)
  end

end
