# require "scriptorium/helpers"

class Scriptorium::Repo
  include Scriptorium::Exceptions
  # extend  Engine
  include Scriptorium::Helpers

  class << self
    attr_accessor :testing
    attr_reader   :root
  end

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
    self.open(@root)
  end

  def self.open(root)
    Scriptorium::Repo.new(root)
  end

  def self.destroy
    raise TestModeOnly unless Scriptorium::Repo.testing
    system("rm -rf #@root")
  end

  ### Instance...

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

  def initialize(root)    # repo
    @root = root
    # Read relevant info...
    Scriptorium::View.class_eval do
      @root = root
      attr_reader :root
    end
  end
end
