class View

  attr_reader :name, :title, :subtitle, :viewdir

  def self.root
    Scriptorium.root
  end

  def self.exist?(name)
    Dir.exist?("#{root}/views/#{name}")
  end

  def self.create(name, title, subtitle = "")
    raise ViewDirAlreadyExists if exist?(name)
    Dir.mkdir("#{root}/views/#{name}")
    # write name, title, subtitle
  end

  def self.open(name)
    raise ViewDirDoesntExist unless exist?(name)
    # read name, title, subtitle
    # View.new(name, title, subtitle)
  end

  ### Instance...

  def initialize(name, title, subtitle = "")
    @name, @title, @subtitle = name, title, subtitle
    @viewdir = "#{root}/views/#{name}"
  end

end
