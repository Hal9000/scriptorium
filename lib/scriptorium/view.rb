class Scriptorium::View

  attr_reader :name, :title, :subtitle, :theme, :dir

  def self.create_sample_view(repo)
    repo.create_view("sample", "My first view", "This is just a sample")
  end

  def initialize(name, title, subtitle = "", theme = "standard")
    @name, @title, @subtitle, @theme = name, title, subtitle, theme
    @root = Scriptorium::Repo.root
    @dir = "#@root/views/#{name}"
  end

private def generate_empty_containers
  layout_file = @dir/:config/"layout.txt"
  return unless File.exist?(layout_file)

  lines = File.readlines(layout_file).map(&:strip)
  lines.reject! { |line| line.empty? || line.start_with?('#') }
  lines.map! {|line| line.sub(/# .*$/, "") }

  lines.each do |section|
    filename = @dir/:output/"#{section}.html"
    tag = section   # header, footer, main
    tag = "aside" if section == 'left' || tag == 'right'
  
    content = <<~HTML
      <#{tag} class="#{section}">
        <!-- #{section.upcase} CONTENT -->
      </#{tag}>
    HTML

    File.write(filename, content)
  end
end


  def apply_theme(theme)
    # check to see if ever done before?
    # copy layout.txt to view
    t = Scriptorium::Theme.new(@root, theme)
    FileUtils.cp(t.file("layout.txt"), @dir/:config)
    # copy other .txt to view?  header, footer, ...
    names = %w[header footer left right main]
    lay = @root/:themes/theme/:layout
    names.each do |name|
      f1, f2 = lay/"#{name}.txt", dir/:config
      FileUtils.cp(f1, f2)
    end
    generate_empty_containers
  end
end
