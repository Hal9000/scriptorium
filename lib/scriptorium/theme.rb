class Scriptorium::Theme

  include Scriptorium::Helpers
  extend  Scriptorium::Helpers
  include Scriptorium::Exceptions

  attr_accessor :name

  def self.create_standard(root)
    predef = Scriptorium::StandardFiles.new
    make_dirs(:standard, top: root/:themes)
    std = root/:themes/:standard
    make_dirs(:initial, :templates, :header, :assets, :partials, :helpers, top: std)
    make_empty_file(std/"config.lt3")
    make_empty_file(std/"helper.rb")
    make_empty_file(std/"README.lt3")
    empties = { "templates" => %w[post.lt3 index.lt3 layout.lt3 widget.lt3],
                "partials"  => %w[header.lt3 footer.lt3 sidebar.lt3],
                "header"    => %w[banner.lt3]}
    # banner, navbar: data will live in view
    # banner falls back to rendered title/subtitle
    # navbar falls back to nothingScriptorium
    empties.each_pair {|dir, files| files.each {|file| make_empty_file(std/dir/file) } }
    write_file(std/:initial/"post.lt3", predef.initial_post(:raw))
    write_file(std/:templates/"post.lt3", predef.post_template)
  end

  def file(portion)
    paths = Find.find(@root/:themes/name)
    found = paths.find_all {|x| x.include?(portion) }
    if found.size == 1
      return found[0]
    else
      # puts "Search for #{portion} found"
      # found.each {|x| puts "  #{x}"}
      raise MoreThanOneResult
    end
  end

  def initialize(root, name)
    @root = root
    @name = name
  end

end
