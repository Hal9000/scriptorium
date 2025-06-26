class Scriptorium::View

  attr_reader :name, :title, :subtitle, :theme, :dir

  def self.create_sample_view(repo)
    repo.create_view("sample", "My first view", "This is just a sample")
  end

  def initialize(name, title, subtitle = "", theme = "standard")
    @name, @title, @subtitle, @theme = name, title, subtitle, theme
    root = Scriptorium::Repo.root
    @dir = "#{root}/views/#{name}"
  end

end
