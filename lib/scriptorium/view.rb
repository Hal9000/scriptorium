class Scriptorium::View
  include Scriptorium::Exceptions

  attr_reader :name, :title, :subtitle, :theme, :dir

  def self.create_sample_view(repo)
    repo.create_view("sample", "My first view", "This is just a sample")
  end

  def initialize(name, title, subtitle = "", theme = "standard")
    @name, @title, @subtitle, @theme = name, title, subtitle, theme
    @root = Scriptorium::Repo.root
    @repo = Scriptorium::Repo.repo
    @dir = "#@root/views/#{name}"
  end

  def read_layout(file)
    lines = File.readlines(file).map(&:strip)
    lines.reject! { |line| line.empty? || line.start_with?('#') }
    lines.map! {|line| line.sub(/ .*$/, "") }
    diff = lines - %w[header footer left right main]
    raise LayoutHasUnknownTag unless diff.empty?
    raise LayoutHasDuplicateTags if lines.uniq != lines
    lines
  end

  private def generate_empty_containers
    layout_file = @dir/:config/"layout.txt"
    return unless File.exist?(layout_file)

    lines = read_layout(layout_file)
    lines.each do |section|
      filename = @dir/:output/:panes/"#{section}.html"
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

  def theme(change = nil)
    return @theme if change.nil?
    # what if it doesn't exist?
    raise ThemeDoesntExist unless Dir.exist?(@root/:themes/change)
    @theme = change
    change_config(@dir/"config.txt", "theme", change)
    apply_theme(change)
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
      f1, f2 = lay/:config/"#{name}.txt", dir/:config
      FileUtils.cp(f1, f2)
    end
    generate_empty_containers
  end

end
