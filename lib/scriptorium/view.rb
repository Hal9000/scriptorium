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

    lines = read_layout
    lines.each do |section|
      filename = @dir/:layout/"#{section}.html"
      tag = section   # header, footer, main
      tag = "aside" if section == 'left' || tag == 'right'
    
      content = <<~HTML
        <#{tag} class="#{section}">
          <!-- #{section.upcase} CONTENT -->
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
    "<!-- #{section.upcase} CONTENT -->"
  end

  def build_section(section)
    cfg = @dir/:config
    template = @dir/:layout/"#{section}.html"
    sectxt = cfg/"#{section}.txt"
    output = @dir/:output/:panes/"#{section}.html"
    unless File.exist?(sectxt)
      warn "[build_section] Missing file: #{sectxt}"
      return
    end    
    lines = read_commented_file(sectxt)
    html = yield(lines)
    text = html.join("\n")
    target = content_tag(section)
    content = File.read(template)
    content.sub!(target, text)
    write_file(output, content)
    content
  end

  def placeholder_text(str)
    if str.start_with?("@")
      file = @dir/:config/:text/"#{str[1..]}"
      File.exist?(file) ? File.read(file) : "[Missing: #{file}]"
    else
      str
    end
  end

  def build_header
    result = ["<!-- Section: header -->\n"]
    build_section("header") do |lines|
      html = lines.map do |line|
        component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
        case component.downcase
        when "title"
          "  <h1>#{escape_html(@title)}</h1>"
        when "text"
          "  <p>" + placeholder_text(arg) + "</p>"
        else
          warn "Unknown header component: #{component.inspect}"
          nil
        end
      end
      result << html.compact  
    end
  end
  
  def build_footer
    result = ["<!-- Section: footer -->\n"]
    build_section("footer") do |lines|
      html = lines.map do |line|
        component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
        case component.downcase
        when "text"
          "  <p>" + placeholder_text(arg) + "</p>"
        else
          warn "Unknown footer component: #{component.inspect}"
          nil
        end
      end
      result << html.compact
    end
  end
  
  def build_left
    result = ["<!-- Section: left -->\n"]
    build_section("left") do |lines|
      html = lines.map do |line|
        component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
        case component.downcase
        when "text"
          "  <p>" + placeholder_text(arg) + "</p>"
        else
          warn "Unknown left component: #{component.inspect}"
          nil
        end
      end
      result << html.compact
    end
  end

  def build_right
    result = ["<!-- Section: right -->\n"]
    build_section("right") do |lines|
      html = lines.map do |line|
        component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
        case component.downcase
        when "text"
          "  <p>" + placeholder_text(arg) + "</p>"
        else
          warn "Unknown right component: #{component.inspect}"
          nil
        end
      end
      result << html.compact
    end
  end

  def build_main
    result = ["<!-- Section: main -->\n"]
    if view_posts.empty?
      result << "  <h1>No posts yet!</h1>"
    else
      result += post_index_array
    end
    build_section("main") do |lines|
      html = lines.map do |line|
        component, arg = line.split(/\s+/, 2)  # FIXME - what if no arg?
        case component.downcase
        when "text"
          "  <p>" + placeholder_text(arg) + "</p>"
        else
          warn "Unknown main component: #{component.inspect}"
          nil
        end
      end
      result << html.compact
    end
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
    num, title, pubdate, blurb = post.values_at(:"post.id", :"post.title", :"post.pubdate", :"post.blurb")
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
  @repo.all_posts(self).sort_by {|post| post[:"post.pubdate"]}
end

def generate_front_page
  layout_file = @dir/:config/"layout.txt"
  index_file  = @dir/:output/"index.html"
  panes       = @dir/:output/:panes

  sections = read_layout

  content = ""

  %w[header left main right footer].each do |section|
    next unless sections.include?(section)
    send("build_#{section}")
    file_path = panes / "#{section}.html"
    content << File.read(file_path) << "\n\n"
  end

  full_html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>#{@title}</title>
      <link rel="stylesheet" href="layout.css">
    </head>
    <body>
    #{content.strip}
    </body>
    </html>
  HTML

  write_file(index_file, full_html)
end


end
