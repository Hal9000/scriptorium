class Scriptorium::Repo
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  extend  Scriptorium::Helpers

  class << self
    attr_accessor :testing
    attr_reader   :root     # class level
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
      ├── assets/
      ├── config/
      ├── drafts/
      ├── posts/
      ├── themes/
      └── views/
    EOS

    # r.mkdir(@root)
    # make_dirs(*%w[config views posts drafts themes assets], top: @root)
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
    # system("mv #@root deleted.scriptorium")
    system("rm -rf #@root")
  end

  def postnum_file
    "#@root/config/last_post_num.txt"
  end

  def initialize(root)    # repo
    @root = root
    @predef = Scriptorium::StandardFiles.new
    Scriptorium::Repo.class_eval { @root = root }
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
    ├── config/
    │   ├── footer.txt
    │   ├── header.txt
    │   ├── layout.txt
    │   ├── left.txt
    │   ├── main.txt
    │   └── right.txt
    ├── config.txt
    ├── layout/
    ├── output/
    │   ├── panes/
    │   │   ├── footer.html
    │   │   ├── header.html
    │   │   ├── left.html
    │   │   ├── main.html
    │   │   └── right.html
    │   └── posts/
    └── staging/
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
    write_file(cfg/"header.txt", "Specify contents of header")
    write_file(cfg/"footer.txt", "Specify contents of footer")
    write_file(cfg/"left.txt",   "Specify contents of left sidebar")
    write_file(cfg/"right.txt",  "Specify contents of right sidebar")
    view.apply_theme(theme)
    return view
  end

  def open_view(name)
    vhash = getvars(view_dir(name)/"config.txt")
    title, subtitle, theme = vhash.values_at("title", "subtitle", "theme")
    view = Scriptorium::View.new(name, title, subtitle, theme)
    @views -= [view]
    @views << view
    @current_view = view
    write_file(@root/:config/"currentview.txt", view.name)
    view
  end

  def create_draft(title: nil, views: nil, tags: nil)
    ts = Time.now.strftime("%Y%m%d-%H%M%S")
    name = "#@root/drafts/#{ts}-draft.lt3"
    theme = @current_view.theme
    id = incr_post_num
    initial = @predef.initial_post(num: id, title: title, views: views, tags: tags)
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

  def finish_draft(name, view: nil)
    id = d4(last_post_num)
    posts = @root/:posts
    make_dirs(id, id/:assets, top: posts)
    FileUtils.mv(name, posts/id/"draft.lt3")
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
    num, title = data.values_at(:id, :title)
    File.open(@root/:posts/d4(num)/"meta.txt", "w") do |f|
      data.each_pair {|k,v| f.printf "%-12s  %s\n", "post.#{k}", v }
      # FIXME - standardize key names!
    end
  end

  private def write_generated_post(data, view, final)
    num, title = data.values_at(:id, :title)
    slug  = slugify(num, title) + ".html"
    # Write to:
    #   root/posts/0123/body.html  meta.txt  (assets/  draft.lt3)
    top = @root/:posts/d4(num)/"body.html"
    write_file(top, final)  
    write_post_metadata(data, view)
    #   view/.../output/posts/0123-this-is-me.html
    path  = view.dir/:output/:posts/slug    
    write_file(path, final)
    write_file("/tmp"/slug)  # for debugging
  end

  def generate_post(num, view)
    view = lookup_view(view)
    draft = @root/:posts/d4(num)/"draft.lt3"
    live = Livetext.customize(call: ".nopara") # vars??
    theme = view.theme 
    input = @predef.scriptor
    input << File.read(draft)
    write_file("/tmp/test.lt3", input)
    text = live.xform_file("/tmp/test.lt3")
    vars, body = live.vars.vars, live.body
    data = adjust_vars(vars, text)
    template = @predef.post_template("standard")
    data[:pubdate] = Time.now.strftime("%Y-%m-%D")   # write to meta.txt (lt3?)
    final = template % data
tree("/tmp/tree.txt")
    write_generated_post(data, view, final)
  end

end
