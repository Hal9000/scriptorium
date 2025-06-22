class Scriptorium::Repo
  include Scriptorium::Exceptions
  include Scriptorium::Helpers


  class << self
    attr_accessor :testing
    attr_reader   :root     # class level
  end

  attr_reader   :root       # instance

  def self.exist?
    dir = Scriptorium::Repo.root
    return false if dir.nil?
    Dir.exist?(dir)
  end

  def self.create(testing = false)
    Scriptorium::Repo.testing = testing
    home = ENV['HOME']
    @root = testing ? "scriptorium-TEST" : "#{home}/.scriptorium"
    # Test for existence!!  FIXME
    raise RepoDirAlreadyExists if Dir.exist?(@root)
    Dir.mkdir(@root)
    Dir.chdir(@root) do
      subs = %w[config views posts drafts themes assets]
      subs.each {|sub| Dir.mkdir(sub) }
    end
    Dir.mkdir("#@root/posts/meta")
    Dir.mkdir("#@root/themes/standard")
    Dir.mkdir("#@root/views/sample")

    File.open("#@root/config/last_post_num.txt", "w") {|f| f.puts 0 }
    self.open(@root)
  end

  def self.open(root)
    Scriptorium::Repo.new(root)
  end

  def self.destroy
    raise TestModeOnly unless Scriptorium::Repo.testing
    system("rm -rf #@root")
  end

  def initialize(root)    # repo
    @root = root
    Scriptorium::Repo.class_eval { @root = root }
    @postnum_file = "#@root/config/last_post_num.txt"
  end

  ### View methods...

  def view_exist?(name)
    Dir.exist?("#@root/views/#{name}")
  end

  def create_view(name, title, subtitle = "")
    # FIXME finish
    raise ViewDirAlreadyExists if view_exist?(name)
    dir = "#@root/views/#{name}"
    Dir.mkdir(dir)
    Dir.chdir(dir) do 
      File.open("config.txt", "w") do |f|
        f.puts "title #{title}"
        f.puts "subtitle #{subtitle}" unless subtitle.empty?
      end
    end
  end

  def open_view(name)
    vhash = getvars("#@root/views/#{name}/config.txt")
    title, subtitle = vhash.values_at("title", "subtitle")
    Scriptorium::View.new(name, title, subtitle)
  end

  def create_draft
    ts = Time.now.strftime("%Y%m%d-%H%M%S")
    name = "#@root/drafts/#{ts}-draft.lt3"
    File.new(name, "w")
    # FIXME add boilerplate
    name
  end

  def last_post_num
    File.read(@postnum_file).to_i   
  end

  def incr_post_num
    num = last_post_num + 1
    File.open(@postnum_file, "w") {|f| f.puts num }
    num
  end

  def publish_draft(name)
    id = d4(incr_post_num)
    dir = "#@root/posts/#{id}"
    system("find #{@root}/posts")
    Dir.mkdir(dir)
    Dir.mkdir("#{dir}/assets")
    File.new("#{dir}/meta.lt3", "w")
    FileUtils.mv(name, "#{dir}/draft.lt3")
    system("find #{@root}/posts")
  end

end
