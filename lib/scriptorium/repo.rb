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
    # Test for existence!!  FIXME
    raise RepoDirAlreadyExists if Dir.exist?(@root)
    Dir.mkdir(@root)
    make_dirs(*%w[config views posts drafts themes assets], top: @root)
    make_dirs("posts/meta", top: @root)
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
    # FIXME finish
    raise ViewDirAlreadyExists if view_exist?(name)
    dir = "#@root/views/#{name}"
    Dir.mkdir(dir)
    make_dirs("config", "layout", "output", top: dir)
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
    write_file(cfg/"header.txt", "# Specify contents of header")
    write_file(cfg/"footer.txt", "# Specify contents of footer")
    write_file(cfg/"left.txt",   "# Specify contents of left sidebar")
    write_file(cfg/"right.txt",  "# Specify contents of right sidebar")
    view.apply_theme(theme)
    view
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
    initial = @predef.initial_post(title: title, views: views, tags: tags)
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
    id = d4(incr_post_num)
    posts = @root/:posts
    make_dirs(id, id/:assets, top: posts)
    make_empty_file(posts/id/"meta.lt3")
    FileUtils.mv(name, posts/id/"draft.lt3")
    # FIXME now must generate
    # adds meta.lt3 incl pubdate, etc.
  end

end
