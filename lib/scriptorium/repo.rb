class Scriptorium::Repo
  include Scriptorium::Exceptions
  extend  Scriptorium::Exceptions
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
    file = testing ? "test/scriptorium-TEST" : ".scriptorium"
    @root = parent/file
    raise self.RepoDirAlreadyExists(@root) if Dir.exist?(@root)
    make_tree(parent, <<~EOS)
      #@root
      ├── config/       # Global config files
      ├── views/        # Views
      ├── drafts/       # Draft posts (global)
      ├── posts/        # Global generated posts (slug.html)
      ├── assets/       # Images, etc.
      │   └── library/  # Common images, icons, etc.
      └── themes/       # Themes
    EOS

    postnum_file = "#@root/config/last_post_num.txt"
    write_file(postnum_file, "0")
    write_file(@root/:config/"global-head.txt",   @predef.html_head_content)
    write_file(@root/:config/"bootstrap_js.txt",  @predef.bootstrap_js)
    write_file(@root/:config/"bootstrap_css.txt", @predef.bootstrap_css)
    write_file(@root/:config/"common.js",         @predef.common_js)
    Scriptorium::Theme.create_standard(@root)     # Theme: templates, etc.
    @repo = self.open(@root)
    Scriptorium::View.create_sample_view(repo)
    return repo
  end

  def self.open(root)
    Scriptorium::Repo.new(root)
  end

  def self.destroy
    raise self.TestModeOnly unless Scriptorium::Repo.testing
    system!("rm -rf #@root", "destroying repository")
  end

  def postnum_file
    "#@root/config/last_post_num.txt"
  end

  def initialize(root)    # repo
    @root = root
    @predef = Scriptorium::StandardFiles.new
    # Scriptorium::Repo.class_eval { @root, @repo = root, self }
    self.class.instance_variable_set(:@root, root)
    self.class.instance_variable_set(:@repo, self)  
    load_views
  end

  private def load_views
    @views = []
    list = Dir.entries(@root/:views) - %w[. .. config.txt]
    list.each {|dir| open_view(dir) }
    cview_file = @root/:config/"currentview.txt"
    @current_view = nil
    if File.exist?(cview_file)
      @current_view = read_file(cview_file).chomp
    end
  end

  ### View methods...

  def lookup_view(target)
    return target if target.is_a?(Scriptorium::View)
    
    # Input validation
    if target.nil?
      raise "Cannot lookup view: target is nil"
    end
    
    if target.to_s.strip.empty?
      raise "Cannot lookup view: target is empty or whitespace-only"
    end
    
    list = @views.select {|v| v.name == target }
    raise CannotLookupView(target) if list.empty?
    raise MoreThanOneResult(target) if list.size > 1
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
    raise ViewDirAlreadyExists(name) if view_exist?(name)
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
    ├── assets/              # Images, etc. (view-specific)
    ├── output/              # Output files (generated HTML)
    │   ├── panes/           # Containers from layout.txt
    │   │   ├── footer.html  # Generated from footer.txt
    │   │   ├── header.html  # Generated from header.txt
    │   │   ├── left.html    # Generated from left.txt
    │   │   ├── main.html    # Generated from main.txt
    │   │   └── right.html   # Generated from right.txt
    │   └── posts/           # Generated posts for view (slug.html)
    ├── widgets/             # Widgets for view
    └── staging/             # Staging area prior to deployment
    EOS

    ### 

    dir = "#@root/views/#{name}"
    write_file(dir/"config.txt", 
               "title    #{title}", 
               "subtitle #{subtitle}",
               "theme    #{theme}")
    write_file(dir/:config/"global-head.txt", @predef.html_head_content(true))  # true = view-specific
    write_file(dir/:config/"bootstrap_js.txt", @predef.bootstrap_js)
    write_file(dir/:config/"bootstrap_css.txt", @predef.bootstrap_css)
    write_file(dir/:config/"common.js",       @predef.common_js)
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

  def create_draft(title: nil, blurb: nil, views: nil, tags: nil, body: nil)
    ts = Time.now.strftime("%Y%m%d-%H%M%S")
    name = "#@root/drafts/#{ts}-draft.lt3"
    # Whoa - what if different views have different themes??? FIXME 
    # Maybe solution is as simple as: Initial post is not theme-dependent
    theme = @current_view.theme
    views ||= @current_view.name   # initial_post wants a String!
    views, tags = Array(views), Array(tags)
    id = incr_post_num
    initial = @predef.initial_post(num: id, title: title, blurb: blurb, 
                                   views: views, tags: tags, body: body)
    write_file(name, initial)
    name
  end

  def last_post_num
    read_file(postnum_file).to_i
  end

  def incr_post_num
    num = last_post_num + 1
    write_file(postnum_file, num.to_s)
    num
  end

  def finish_draft(name)
    id = last_post_num
    id4 = d4(id)
    posts = @root/:posts
    make_dir(posts/id4)
    make_dir(posts/id4/:assets)
    FileUtils.mv(name, posts/id4/"draft.lt3")
    # FIXME - what about views?
    id
  end

  def tree(file = nil)
    cmd = "tree #@root"
    cmd << " >#{file}" if file
    system!(cmd, "generating tree structure")
  end


  private def write_post_metadata(data, view)
    num, title = data.values_at(:"post.id", :"post.title")
    data = data.select {|k,v| k.to_s.start_with?("post.") }
    data.delete(:"post.body")
    data[:"post.slug"] = slugify(num, title) + ".html"
    lines = data.map { |k, v| sprintf("%-12s  %s", k, v) }
    write_file(@root/:posts/d4(num)/"meta.txt", *lines)
    # FIXME - standardize key names!
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

  def create_post(title: nil, views: nil, tags: nil, body: nil)
    name = create_draft(title: title, views: views, tags: tags, body: body)
    num = finish_draft(name)
    generate_post(num)
    self.post(num)  # Return the Post object
  end

  def generate_post(num)
    draft = @root/:posts/d4(num)/"draft.lt3"
    need(:file, draft)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara") # vars??
    text = live.xform_file(draft)
    vars, body = live.vars.vars, live.body
    views = vars[:"post.views"].strip.split(/\s+/)
    views.each do |view|  
      view = lookup_view(view)
      theme = view.theme 
      vars[:"post.id"] = num
      vars[:"post.body"] = text
      template = @predef.post_template("standard")
      set_pubdate(vars)
      final = substitute(vars, template) 
      tree("/tmp/tree.txt")
      write_generated_post(vars, view, final)
    end
  end

  private def set_pubdate(vars)    # Not Post#set_pubdate 
    t = Time.now
    vars[:"post.pubdate"] = t.strftime("%Y-%m-%d %H:%M:%S") 
    vars[:"post.pubdate.month"] = t.strftime("%B") 
    vars[:"post.pubdate.day"] = t.strftime("%d") 
    vars[:"post.pubdate.year"] = t.strftime("%Y") 
  end

  def all_posts(view = nil)
    posts = []
    dirs = Dir.children(@root/:posts)
    dirs.each do |id4|
      posts << Scriptorium::Post.read(self, id4)
    end
    return posts if view.nil?
    view = lookup_view(view)
    posts.select {|x| x.views.include?(view.name) }
  end

  def generate_post_index(view)
    view = lookup_view(view)
    view.generate_post_index
  end

  def post(id)
    meta = @root/:posts/d4(id)/"meta.txt"
    return nil unless File.exist?(meta)
    Scriptorium::Post.new(self, id)
  end
  
  def generate_front_page(view)
    view = lookup_view(view)
    view.generate_front_page
  end
    
end