class Scriptorium::Repo
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  extend  Scriptorium::Helpers

  class << self
    attr_accessor :testing
    attr_reader   :root, :repo     # class level
  end

  # instance attrs

  attr_reader   :root, :views, :current_view

  def self.exist?
    dir = Scriptorium::Repo.root
    return false if dir.nil?
    Dir.exist?(dir)
  end

  def self.create(testing = false)
    Scriptorium::Repo.testing = testing
    home = ENV['HOME']
    @predef = Scriptorium::StandardFiles.new
    @root = testing ? "scriptorium-TEST" : "#{home}/.scriptorium"
    parent = testing ? "." : home
    file = testing ? "scriptorium-TEST" : ".scriptorium"
    @root = parent/file
    raise RepoDirAlreadyExists if Dir.exist?(@root)
    make_tree(parent, <<~EOS)
      #@root
      ├── assets/  # Images, etc.
      ├── config/  # Global config files
      ├── drafts/  # Draft posts (global)
      ├── posts/   # Global generated posts (slug.html)
      ├── themes/  # Themes
      └── views/   # Views
    EOS

    postnum_file = "#@root/config/last_post_num.txt"
    write_file(postnum_file, "0")
    Scriptorium::Theme.create_standard(@root)   # Theme: templates, etc.
    repo = self.open(@root)
    Scriptorium::View.create_sample_view(repo)
    return repo
  end

  def self.open(root)
    Scriptorium::Repo.new(root)
  end

  def self.destroy
    raise TestModeOnly unless Scriptorium::Repo.testing
    system("rm -rf #@root")
  end

  def postnum_file
    "#@root/config/last_post_num.txt"
  end

  def initialize(root)    # repo
    @root = root
    @predef = Scriptorium::StandardFiles.new
    Scriptorium::Repo.class_eval { @root, @repo = root, self }
    load_views
  end

  private def load_views
    @views = []
    list = Dir.entries(@root/:views) - %w[. .. config.txt]
    list.each {|dir| open_view(dir) }
    cview_file = @root/:config/"currentview.txt"
    @current_view = nil
    if File.exist?(cview_file)
      @current_view = File.read(cview_file).chomp
    end
  end

  ### View methods...

  def lookup_view(target)
    return target if target.is_a?(Scriptorium::View)
    list = @views.select {|v| v.name == target }
    raise CannotLookupView if list.empty?
    raise MoreThanOneResult if list.size > 1
    return list[0]
  end

  def view(change = nil)   # get/set current view
    return @current_view if change.nil?
    vnew = change.is_a?(Scriptorium::View) ? change : lookup_view(change)
    @current_view = vnew
  end

  def view_exist?(name)
    Dir.exist?("#@root/views/#{name}")
  end

  def create_view(name, title, subtitle = "", theme: "standard")
    raise ViewDirAlreadyExists if view_exist?(name)
    make_tree(@root/:views, <<~EOS)
    #{name}/
    ├── config/              # View-specific config files (FIXME rename?)
    │   ├── layout.txt       # Overall layout for front page
    │   ├── footer.txt       # Content for footer.html
    │   ├── header.txt       # Content for header.html
    │   ├── left.txt         # Content for left.html
    │   ├── main.txt         # Content for main.html
    │   └── right.txt        # Content for right.html
    ├── config.txt           # View-specific config file
    ├── layout/              # Unused?
    ├── output/              # Output files (generated HTML)
    │   ├── panes/           # Containers from layout.txt
    │   │   ├── footer.html  # Generated from footer.txt
    │   │   ├── header.html  # Generated from header.txt
    │   │   ├── left.html    # Generated from left.txt
    │   │   ├── main.html    # Generated from main.txt
    │   │   └── right.html   # Generated from right.txt
    │   └── posts/           # Generated posts for view (slug.html)
    └── staging/             # Staging area prior to deployment
    EOS

    ### 

    dir = "#@root/views/#{name}"
    write_file(dir/"config.txt", 
               "title    #{title}", 
               "subtitle #{subtitle}",
               "theme    #{theme}")
    view = open_view(name)
    @views -= [view]
    @views << view
    @current_view = view
    write_file(@root/:config/"currentview.txt", view.name)
    cfg = dir/:config  # Should these be copied from theme??
    theme_config = @root/:themes/theme/:layout/:config
    containers = %w[header.txt footer.txt left.txt right.txt main.txt]
    containers.each do |container|
      FileUtils.cp(theme_config/container, cfg/container)  # from theme to view
    end
    view.apply_theme(theme)
    return view
  end

  def open_view(name)
    vhash = getvars(view_dir(name)/"config.txt")
    title, subtitle, theme = vhash.values_at(:title, :subtitle, :theme)
    view = Scriptorium::View.new(name, title, subtitle, theme)
    @views -= [view]
    @views << view
    @current_view = view
    write_file(@root/:config/"currentview.txt", view.name)
    view
  end

  def create_draft(title: nil, views: nil, tags: nil, body: nil)
    ts = Time.now.strftime("%Y%m%d-%H%M%S")
    name = "#@root/drafts/#{ts}-draft.lt3"
    theme = @current_view.theme
    id = incr_post_num
    initial = @predef.initial_post(num: id, title: title, views: views, tags: tags, body: body)
    write_file(name, initial)
    # FIXME add boilerplate
    name
  end

  def last_post_num
    File.read(postnum_file).to_i   
  end

  def incr_post_num
    num = last_post_num + 1
    write_file(postnum_file, num)
    num
  end

  def finish_draft(name)
    id = last_post_num
    id4 = d4(id)
    posts = @root/:posts
    Dir.mkdir(posts/id4)
    Dir.mkdir(posts/id4/:assets)
    FileUtils.mv(name, posts/id4/"draft.lt3")
    # FIXME - what about views?
    id
  end

  def tree(file = nil)
    cmd = "tree #@root"
    cmd << " >#{file}" if file
    system(cmd) 
  end

  private def adjust_vars(v1, text)
    keys = v1.keys.select {|k| k.to_s.start_with?("post.") }
    v2 = {}
    keys.each {|k| v2[k] = v1[k] }
    v2[:"post.body"] = text
    data = {}
    v2.each_pair do |k, v| 
      short = k.to_s.sub(/^post./, "").to_sym
      data[short] = v
    end
    data
  end

  private def write_post_metadata(data, view)
    num, title = data.values_at(:"post.id", :"post.title")
    data = data.select {|k,v| k.to_s.start_with?("post.") }
    data.delete(:"post.body")
    data[:"post.slug"] = slugify(num, title) + ".html"
    File.open(@root/:posts/d4(num)/"meta.txt", "w") do |f|
      data.each_pair {|k,v| f.printf "%-12s  %s\n", k, v }
      # FIXME - standardize key names!
    end
  end

  private def write_generated_post(data, view, final)
    num, title = data.values_at(:"post.id", :"post.title")
    id4 = d4(num)
    slug  = slugify(num, title) + ".html"
    # Write to:
    #   root/posts/0123/body.html  meta.txt  (assets/  draft.lt3)
    top = @root/:posts/id4/"body.html"
    write_file(top, final)  
    write_post_metadata(data, view)
    #   view/.../output/posts/0123-this-is-me.html
    path  = view.dir/:output/:posts/slug    
    write_file(path, final)
    write_file("/tmp"/slug)  # for debugging
  end


  def generate_post(num)
    draft = @root/:posts/d4(num)/"draft.lt3"
    live = Livetext.customize(call: ".nopara") # vars??
    input = @predef.scriptor
    input << File.read(draft)
    write_file("/tmp/test.lt3", input)
    text = live.xform_file("/tmp/test.lt3")
    vars, body = live.vars.vars, live.body
    views = vars[:"post.views"].strip.split(/\s+/)
    views.each do |view|  
      view = lookup_view(view)
      theme = view.theme 
      # data = adjust_vars(vars, text)
      vars[:"post.id"] = num
      vars[:"post.body"] = text
      template = @predef.post_template("standard")
      vars[:"post.pubdate"] = Time.now.strftime("%Y-%m-%d") 
      final = substitute(vars, template)
      tree("/tmp/tree.txt")
      write_generated_post(vars, view, final)
    end
  end

  def all_posts(view = nil)
    posts = []
    dirs = Dir.children(@root/:posts)
    dirs.each do |id4|
      posts << getvars(@root/:posts/id4/"meta.txt")
    end
    return posts if view.nil?
    view = lookup_view(view)
    posts.select {|x| x[:"post.views"].include?(view.name) }
  end

  def generate_post_index(view)
    view = lookup_view(view)
    posts = all_posts(view)  # sort by pubdate
    str = ""
    # FIXME - many decisions to make here...
    posts.each do |post|
      num, title, pubdate, blurb = post.values_at(:"post.id", :"post.title", :"post.pubdate", :"post.blurb")
      template = @predef.index_entry
      entry = substitute(post, template)
      str << entry
      # grab index-entry template
      # generate index-entry for each post
      # append to str
    end
    write_file(view.dir/:output/"post_index.html", str)    
  end

  def alter_pubdate(id, ymd)
    raise TestModeOnly unless Scriptorium::Repo.testing
    meta = @root/:posts/d4(id)/"meta.txt"
    change_config(meta, "post.pubdate", ymd)
  end

  def post(id)
    meta = @root/:posts/d4(id)/"meta.txt"
    return nil unless File.exist?(meta)
    Scriptorium::Post.new(self, id)
  end
  
  def generate_front_page(view)
    view = lookup_view(view)
    layout = view.read_layout
    html = +"<html>\n<head>\n  <title>#{view.title}</title>\n</head>\n<body>\n"
  
    layout.each do |pane|
      pane_file = view.dir/:output/:panes/"#{pane}.html"
      content = if File.exist?(pane_file)
                  File.read(pane_file)
                else
                  "<!-- Missing #{pane}.html -->"  # Handle missing sections
                end
      html << "  <div class=\"#{pane}\">\n#{content}\n  </div>\n"
    end
  
    html << "</body>\n</html>\n"
    output_file = view.dir/:output/"index.html"
    File.write(output_file, html)
  end
    
end