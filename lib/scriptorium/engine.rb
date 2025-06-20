module Scriptorium::Engine

  attr_reader :root   # FIXME  Confusing class with instance

  include Scriptorium::Exceptions

  def exist?
    dir = Scriptorium.root
    return false if dir.nil?
    Dir.exist?(dir)
  end

  def create(testing = false)
    Scriptorium.testing = testing
    home = ENV['HOME']
    @root = testing ? "#{home}/.scriptorium" : "scriptorium-TEST"
    # Test for existence!!  FIXME
    raise RepoDirAlreadyExists if Dir.exist?(@root)
    Dir.mkdir(@root)
    Dir.chdir(@root) do
      subs = %w[config views]
      subs.each {|sub| Dir.mkdir(sub) }
    end
    self.open(@root)
  end

  def open(root)
    Scriptorium.new(root)
  end

  def destroy
    raise TestModeOnly unless Scriptorium.testing
    system("rm -rf #@root")
  end

end
