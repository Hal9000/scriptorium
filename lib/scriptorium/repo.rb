class Scriptorium::Repo
  include Scriptorium::Exceptions
  extend  Scriptorium::Exceptions
  include Scriptorium::Helpers
  extend  Scriptorium::Helpers
  include Scriptorium::Contract
  extend  Scriptorium::Contract

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

  def self.create(path = nil, testmode: false)
    assume { path.nil? || path.is_a?(String) }
    # Handle backward compatibility: boolean true means testing mode
    if testmode == true
      Scriptorium::Repo.testing = path
    else
      Scriptorium::Repo.testing = nil
    end
    home = ENV['HOME']
    @predef = Scriptorium::StandardFiles.new
    @root = path || "#{home}/.scriptorium"
    parent = path ? "." : home
    file = path || ".scriptorium"
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
    write_file(@root/:config/"widgets.txt",       @predef.available_widgets)
    Scriptorium::Theme.create_standard(@root)     # Theme: templates, etc.
    
    # Generate OS-specific helper code
    generate_os_helpers(@root)
    
    @repo = self.open(@root)
    Scriptorium::View.create_sample_view(repo)
    verify { @repo.is_a?(Scriptorium::Repo) }
    return repo
  end

  def self.open(root)
    assume { root.is_a?(String) && !root.empty? }
    repo = Scriptorium::Repo.new(root)
    verify { repo.is_a?(Scriptorium::Repo) }
    repo
  end

  def self.destroy
    assume { Scriptorium::Repo.testing }
    raise self.TestModeOnly unless Scriptorium::Repo.testing
    system!("rm -rf #@root", "destroying repository")
    verify { !Dir.exist?(@root) }
  end

  def postnum_file
    "#@root/config/last_post_num.txt"
  end

  # Invariants
  def define_invariants
    invariant { @root.is_a?(String) && !@root.empty? }
    invariant { @views.is_a?(Array) }
    invariant { @current_view.nil? || @current_view.is_a?(Scriptorium::View) }
  end

  def initialize(root)    # repo
    assume { root.is_a?(String) && !root.empty? }
    @root = root
    @predef = Scriptorium::StandardFiles.new
    # Scriptorium::Repo.class_eval { @root, @repo = root, self }
    self.class.instance_variable_set(:@root, root)
    self.class.instance_variable_set(:@repo, self)  
    load_views
    @reddit = nil  # Lazy load Reddit integration
    define_invariants
    verify { @root == root }
    check_invariants
  end

  private def load_views
    @views = []
    list = Dir.entries(@root/:views) - %w[. .. config.txt]
    list.each {|dir| open_view(dir) }
    cview_file = @root/:config/"currentview.txt"
    @current_view = nil
    if File.exist?(cview_file)
      view_name = read_file(cview_file).chomp
      begin
        @current_view = lookup_view(view_name)
      rescue => e
        # If the saved view doesn't exist, just leave current_view as nil
        # It will be set when a view is created or selected
      end
    end
  end

  ### View methods...

  def lookup_view(target)
    return target if target.is_a?(Scriptorium::View)
    
    validate_view_target(target)
    
    list = @views.select {|v| v.name == target }
    raise CannotLookupView(target) if list.empty?
    raise MoreThanOneResult(target) if list.size > 1
    return list[0]
  end

  private def validate_view_target(target)
    raise CannotLookupViewTargetNil if target.nil?
    
    raise CannotLookupViewTargetEmpty if target.to_s.strip.empty?
  end

  def view(change = nil)   # get/set current view
    return @current_view if change.nil?
    vnew = change.is_a?(Scriptorium::View) ? change : lookup_view(change)
    write_file(@root/:config/"currentview.txt", vnew.name)
    @current_view = vnew
    @current_view
  end

  def current_view
    @current_view
  end

  def view_exist?(name)
    Dir.exist?("#@root/views/#{name}")
  end

  def create_view(name, title, subtitle = "", theme: "standard")
    assume { name.is_a?(String) }
    assume { title.is_a?(String) }
    validate_view_name(name)
    validate_view_title(title)
    
    # Validate name format (only allow alphanumeric, hyphen, underscore)
    unless name.match?(/^[a-zA-Z0-9_-]+$/)
      raise CannotCreateViewNameInvalid(name)
    end
    
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
    ├── pages/               # Static pages for view
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
    write_file!(dir/"config.txt", 
               "title    #{title}",
               "subtitle #{subtitle}",
               "theme    #{theme}")
    write_file(dir/:config/"global-head.txt",   @predef.html_head_content(true))  # true = view-specific
    write_file(dir/:config/"bootstrap_js.txt",  @predef.bootstrap_js)
    write_file(dir/:config/"bootstrap_css.txt", @predef.bootstrap_css)
    write_file(dir/:config/"common.js",         @predef.common_js)
    write_file(dir/:config/"social.txt",        @predef.social_config)
    write_file(dir/:config/"reddit.txt",        @predef.reddit_config)
    write_file(dir/:config/"deploy.txt",        @predef.deploy_text % {view: name, domain: "example.com"})
    write_file(dir/:config/"status.txt",        @predef.status_txt)
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
    verify { view.is_a?(Scriptorium::View) }
    return view
  end

  def open_view(name)
    vhash = getvars(view_dir(name)/"config.txt")
    title, subtitle, theme = vhash.values_at(:title, :subtitle, :theme)
    view = Scriptorium::View.new(name, title, subtitle, theme)
    @views -= [view]
    @views << view
    # Remove this line - current view should only be set from currentview.txt
    # @current_view = view
    # write_file(@root/:config/"currentview.txt", view.name)
    view
  end

  def create_draft(title: nil, blurb: nil, views: nil, tags: nil, body: nil)
    ts = Time.now.strftime("%Y%m%d-%H%M%S")
    content_name = "#@root/drafts/#{ts}-draft.lt3"
    metadata_name = "#@root/drafts/#{ts}-draft.meta"
    
    # Whoa - what if different views have different themes??? FIXME 
    # Maybe solution is as simple as: Initial post is not theme-dependent
    theme = @current_view.theme
    views ||= @current_view.name   # initial_post wants a String!
    views, tags = Array(views), Array(tags)
    id = incr_post_num
    
    # Create content file (no ID, no created date)
    content = @predef.initial_post_content(title: title, blurb: blurb, 
                                          views: views, tags: tags, body: body)
    write_file(content_name, content)
    
    # Create metadata file (with ID and created date)
    metadata = @predef.initial_post_metadata(num: id, title: title, blurb: blurb, 
                                            views: views, tags: tags)
    write_file(metadata_name, metadata)
    
    # Return the content file name (for backward compatibility)
    content_name
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
    
    # Move content file
    FileUtils.mv(name, posts/id4/"source.lt3")
    
    # Move metadata file (same timestamp, different extension)
    metadata_name = name.sub('.lt3', '.meta')
    if File.exist?(metadata_name)
      FileUtils.mv(metadata_name, posts/id4/"meta.txt")
    end
    
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
    metadata_file = @root/:posts/d4(num)/"meta.txt"
    
    # Read existing metadata to preserve fields like post.published
    existing_metadata = {}
    if File.exist?(metadata_file)
      existing_metadata = getvars(metadata_file)
    end
    
    # Prepare new metadata from data
    new_metadata = data.select {|k,v| k.to_s.start_with?("post.") }
    new_metadata.delete(:"post.body")
    new_metadata[:"post.slug"] = slugify(num, title) + ".html"
    
    # Merge existing metadata over new metadata to preserve important fields
    # Only preserve fields that should not be overwritten by source file changes
    fields_to_preserve = [:"post.published", :"post.deployed", :"post.created"]
    existing_metadata.each do |key, value|
      if fields_to_preserve.include?(key)
        new_metadata[key] = value
      end
    end
    
    lines = new_metadata.map { |k, v| sprintf("%-18s  %s", k, v) }
    write_file(metadata_file, lines.join("\n"))
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
    #   view/.../output/permalink/0123-this-is-me.html (for direct access)
    permalink_path = view.dir/:output/:permalink/slug
    make_dir(File.dirname(permalink_path))
    # Generate complete HTML document with social meta tags for permalink
    post_html = view.generate_post_html(data)
    # Add "Visit Blog" link only to permalink version
    permalink_content = post_html + "\n<div style=\"text-align: center; margin-top: 20px;\">\n<a href=\"../index.html\">Visit Blog</a>\n</div>"
    write_file(permalink_path, permalink_content)
  end

  def create_post(title: nil, views: nil, tags: nil, body: nil, blurb: nil)
    assume { title.nil? || title.is_a?(String) }
    assume { views.nil? || views.is_a?(Array) || views.is_a?(String) }
    assume { tags.nil? || tags.is_a?(Array) || tags.is_a?(String) }
    assume { body.nil? || body.is_a?(String) }
    assume { blurb.nil? || blurb.is_a?(String) }
    name = create_draft(title: title, views: views, tags: tags, body: body, blurb: blurb)
    num = finish_draft(name)
    generate_post(num)
    post = self.post(num)  # Return the Post object
    verify { post.is_a?(Scriptorium::Post) }
    post
  end

  def publish_post(num)
    validate_post_id(num)
    metadata_file = @root/:posts/d4(num)/"meta.txt"
    
    # Read current metadata if it exists
    metadata = {}
    if File.exist?(metadata_file)
      metadata = getvars(metadata_file)
    end
    
    # Check if already published
    if metadata[:"post.published"] != "no" && metadata[:"post.published"] != nil
      raise "Post #{num} is already published"
    end
    
    # Update published timestamp
    metadata[:"post.published"] = ymdhms
    
    # Write updated metadata
    lines = metadata.map { |k, v| sprintf("%-18s  %s", k, v) }
    write_file(metadata_file, lines.join("\n"))
    
    # Generate the post (this will preserve the updated metadata)
    generate_post(num)
    
    self.post(num)
  end

  def post_published?(num)
    validate_post_id(num)
    metadata_file = @root/:posts/d4(num)/"meta.txt"
        return false unless File.exist?(metadata_file)
    
    metadata = getvars(metadata_file)
    result = metadata[:"post.published"] != "no"
    result
  end

  def get_published_posts(view = nil)
    all_posts = all_posts(view)
    all_posts.select { |post| post_published?(post.id) }
  end

  def generate_post(num)

    content_file = @root/:posts/d4(num)/"source.lt3"
    metadata_file = @root/:posts/d4(num)/"meta.txt"
    
    need(:file, content_file)
    
    # Read content file
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara") # vars??
    text = live.xform_file(content_file)
    vars, body = live.vars.vars, live.body
    
    # Create or update metadata from post content
    if File.exist?(metadata_file)
      # Preserve existing metadata (like post.published timestamp)
      existing_metadata = getvars(metadata_file)
      metadata_vars = create_metadata_from_content(num, vars)
      # Merge existing metadata over defaults
      existing_metadata.each do |key, value|
        metadata_vars[key] = value
      end
    else
      # Create new metadata
      metadata_vars = create_metadata_from_content(num, vars)
    end
    
    # Write metadata file
    lines = metadata_vars.map { |k, v| sprintf("%-18s  %s", k, v) }
    write_file(metadata_file, lines.join("\n"))
    
    # Merge metadata into vars, but don't override content vars
    metadata_vars.each do |key, value|
      vars[key] = value unless vars.key?(key)
    end
    
    views = vars[:"post.views"].strip.split(/\s+/)
    vars[:"post.views"] = views.join(" ")  # Ensure post.views is set in vars
    views.each do |view|  
      view = lookup_view(view)
      theme = view.theme 
      vars[:"post.id"] = num.to_s  # Always use the post number as ID
      vars[:"post.body"] = text
      template = @predef.post_template("standard")
      set_pubdate(vars)
      # Add Reddit button if enabled
      vars[:"reddit_button"] = view.generate_reddit_button(vars)
      final = substitute(vars, template) 
      write_generated_post(vars, view, final)
    end
  end

  private def create_metadata_from_content(num, vars)
    metadata = {}
    
    # Set required fields
    metadata[:"post.id"] = d4(num)
    metadata[:"post.created"] = ymdhms
    metadata[:"post.published"] = "no"  # Default to unpublished
    metadata[:"post.deployed"] = "no"
    
    # Copy fields from content vars
    metadata[:"post.title"] = vars[:"post.title"] || "ADD TITLE HERE"
    metadata[:"post.blurb"] = vars[:"post.blurb"] || "ADD BLURB HERE"
    metadata[:"post.views"] = vars[:"post.views"] || "sample"
    metadata[:"post.tags"] = vars[:"post.tags"] || ""
    
    metadata
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
      # Skip deleted posts (directories starting with underscore)
      next if id4.start_with?('_')
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
    validate_post_id(id)
    
    # Check normal directory first
    meta = @root/:posts/d4(id)/"meta.txt"
    return Scriptorium::Post.new(self, id) if File.exist?(meta)
    
    # Check deleted directory (with underscore prefix)
    deleted_meta = @root/:posts/"_#{d4(id)}"/"meta.txt"
    return Scriptorium::Post.new(self, id) if File.exist?(deleted_meta)
    
    # Post not found in either location
    nil
  end

  private def validate_post_id(id)
    raise CannotGetPostIdNil if id.nil?
    
    raise CannotGetPostIdEmpty if id.to_s.strip.empty?
    
    unless id.to_s.match?(/^\d+$/)
      raise CannotGetPostIdInvalid(id)
    end
  end
  
  def generate_front_page(view)
    view = lookup_view(view)
    view.generate_front_page
  end

  # Reddit integration
  def reddit
    @reddit ||= Scriptorium::Reddit.new(self)
  end

  def autopost_to_reddit(post_data, subreddit = nil)
    reddit.autopost(post_data, subreddit)
  end

  def reddit_configured?
    reddit.configured?
  end

  private def validate_view_name(name)
    raise CannotCreateViewNameNil if name.nil?
    
    raise CannotCreateViewNameEmpty if name.to_s.strip.empty?
  end

  private def validate_view_title(title)
    raise CannotCreateViewTitleNil if title.nil?
    
    raise CannotCreateViewTitleEmpty if title.to_s.strip.empty?
  end

  def self.generate_os_helpers(root)
    os_code = case RbConfig::CONFIG['host_os']
    when /darwin/     # macOS
      <<~RUBY
        # Generated at repo creation for macOS
        def open_file(file_path)
          system("open", file_path)
        end
      RUBY
    when /linux/      # Linux
      <<~RUBY
        # Generated at repo creation for Linux
        def open_file(file_path)
          system("xdg-open", file_path)
        end
      RUBY
    when /mswin|mingw|cygwin/  # Windows
      <<~RUBY
        # Generated at repo creation for Windows
        def open_file(file_path)
          system("start", file_path)
        end
      RUBY
    else
      <<~RUBY
        # Generated at repo creation for unknown OS
        def open_file(file_path)
          puts "  Unable to open file on this OS"
        end
      RUBY
    end
    
    write_file(root/:config/"os_helpers.rb", os_code)
  end
    
end
