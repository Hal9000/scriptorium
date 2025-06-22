class Scriptorium::View

  attr_reader :name, :title, :subtitle, :viewdir

  def initialize(name, title, subtitle = "")
    @name, @title, @subtitle = name, title, subtitle
    root = Scriptorium::Repo.root
    @viewdir = "#{root}/views/#{name}"
  end

end
