class Scriptorium::Theme

  include Scriptorium::Helpers
  extend  Scriptorium::Helpers
  include Scriptorium::Exceptions
  include Scriptorium::Contract
  extend  Scriptorium::Contract

  attr_accessor :name

  # Invariants
  def define_invariants
    invariant { @root.is_a?(String) && !@root.empty? }
    invariant { @name.is_a?(String) && !@name.empty? }
  end

  def self.create_standard(root)
    assume { root.is_a?(String) && !root.empty? }
    
    make_tree(root/:themes, <<~EOS)
      standard/
      ├── README.txt
      ├── assets/
      ├── config.txt
      ├── header/
      ├── initial/
      │   └── post.lt3
      ├── layout/
      │   ├── config/
      │   │   ├── footer.txt
      │   │   ├── header.txt
      │   │   ├── left.txt
      │   │   ├── main.txt
      │   │   └── right.txt
      │   ├── gen/
      │   │   └── text.css
      │   └── layout.txt
      └── templates/
          ├── index.lt3
          ├── post.lt3
          ├── index_entry.lt3
          └── widget.lt3
    EOS
    write_file("/tmp/ttree.txt", `tree`)
    predef = Scriptorium::StandardFiles.new
    std = root/:themes/:standard
    write_file(std/:initial/"post.lt3",          predef.initial_post(:raw))
    write_file(std/:templates/"post.lt3",        predef.post_template("standard"))
    write_file(std/:templates/"index_entry.lt3", predef.index_entry)
    layout_text = std/:layout/"layout.txt"
    write_file(layout_text,                      predef.layout_text)
    config, gen = std/:layout/:config, std/:layout/:gen
    write_file(config/"header.txt",              predef.theme_header)
    write_file(config/"footer.txt",              predef.theme_footer)
    write_file(config/"left.txt",                predef.theme_left)
    write_file(config/"right.txt",               predef.theme_right)
    write_file(config/"main.txt",                predef.theme_main)
    
    verify { Dir.exist?(root/:themes/"standard") }
  end

  def file(portion)
    check_invariants
    assume { portion.is_a?(String) && !portion.empty? }
    
    paths = Find.find(@root/:themes/name)
    found = paths.find_all {|x| x.include?(portion) }
    case 
    when found.size == 1
      result = found[0]
      verify { result.is_a?(String) && File.exist?(result) }
      check_invariants
      return result
    when found.size > 1
      # puts "Search for #{portion} found"
      # found.each {|x| puts "  #{x}"}
      raise MoreThanOneResult(portion)
    else 
      raise ThemeFileNotFound(portion)
    end
  end

  def initialize(root, name)
    assume { root.is_a?(String) && !root.empty? }
    assume { name.is_a?(String) && !name.empty? }
    
    @root = root
    @name = name
    
    define_invariants
    verify { @root == root }
    verify { @name == name }
    check_invariants
  end

end
