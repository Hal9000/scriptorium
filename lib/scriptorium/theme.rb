class Scriptorium::Theme

  include Scriptorium::Helpers
  extend  Scriptorium::Helpers
  include Scriptorium::Exceptions

  attr_accessor :name

  def self.create_standard(root)
    predef = Scriptorium::StandardFiles.new
    make_dirs(:standard, top: root/:themes)
    std = root/:themes/:standard
    make_dirs(:initial, :templates, :layout, :header, :assets, top: std)
    make_empty_file(std/"config.lt3")
    make_empty_file(std/"helper.rb")
    make_empty_file(std/"README.lt3")
    empties = { "templates" => %w[post.lt3 index.lt3 widget.lt3] }
    # banner, navbar: data will live in view
    # banner falls back to rendered title/subtitle
    # navbar falls back to nothing
    empties.each_pair {|dir, files| files.each {|file| make_empty_file(std/dir/file) } }
    write_file(std/:initial/"post.lt3", predef.initial_post(:raw))
    write_file(std/:templates/"post.lt3", predef.post_template("standard"))
    layout_text = std/:layout/"layout.txt"
    write_file(layout_text, predef.layout_text)

    lay = std/:layout
    layout = Scriptorium::Layout.new(layout_text)
    write_file(lay/"layout.html", layout.html)
    write_file(lay/"layout.css", layout.css)
    make_empty_file(lay/"text.css")
    write_file(lay/"header.txt", predef.theme_header)
    write_file(lay/"footer.txt", predef.theme_footer)
    write_file(lay/"left.txt",   predef.theme_left)
    write_file(lay/"right.txt",  predef.theme_right)
    write_file(lay/"main.txt",   predef.theme_main)
  end

  def file(portion)
    paths = Find.find(@root/:themes/name)
    found = paths.find_all {|x| x.include?(portion) }
    case 
    when found.size == 1
      return found[0]
    when found.size > 1
      # puts "Search for #{portion} found"
      # found.each {|x| puts "  #{x}"}
      raise MoreThanOneResult
    else 
      raise ThemeFileNotFound
    end
  end

  def initialize(root, name)
    @root = root
    @name = name
  end

end
