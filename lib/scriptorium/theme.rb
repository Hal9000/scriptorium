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
    
    make_tree(root/:themes/:standard, <<~EOS)
      .
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
    copy_support_file('templates/post.lt3', std/:templates/"post.lt3")
    copy_support_file('templates/index_entry.lt3', std/:templates/"index_entry.lt3")
    layout_text = std/:layout/"layout.txt"
    copy_support_file('templates/layout.txt', layout_text)
    config, gen = std/:layout/:config, std/:layout/:gen
    copy_support_file('theme/header.lt3', config/"header.txt")
    copy_support_file('theme/footer.lt3', config/"footer.txt")
    copy_support_file('theme/left.lt3', config/"left.txt")
    copy_support_file('theme/right.lt3', config/"right.txt")
    copy_support_file('theme/main.lt3', config/"main.txt")
    
    # Copy gem assets to standard theme
    copy_gem_assets_to_theme(std)
    
    # Create system.txt to identify system themes
    write_file(root/:themes/"system.txt", "standard\n")
    
    verify { Dir.exist?(root/:themes/"standard") }
  end

  def self.copy_gem_assets_to_theme(theme_dir)
    # Try to find gem assets and copy only theme-specific assets to the theme
    gem_spec = Gem.loaded_specs['scriptorium']
    if gem_spec
      gem_assets_dir = "#{gem_spec.full_gem_path}/assets"
    else
      # Development environment - use the working path
      gem_assets_dir = File.expand_path("assets")
    end
    
    if Dir.exist?(gem_assets_dir)
      # Copy only theme-specific assets to theme assets directory
      theme_assets_dir = theme_dir/"assets"
      FileUtils.mkdir_p(theme_assets_dir) unless Dir.exist?(theme_assets_dir)
      
      # Copy theme-specific assets (themes/ directory)
      theme_gem_dir = "#{gem_assets_dir}/themes"
      if Dir.exist?(theme_gem_dir)
        FileUtils.cp_r("#{theme_gem_dir}/.", theme_assets_dir)
      end
      
      # Copy theme-specific icons (icons/ui/ and icons/social/ - these could be theme-specific)
      icons_gem_dir = "#{gem_assets_dir}/icons"
      if Dir.exist?(icons_gem_dir)
        # Create icons directory in theme assets
        theme_icons_dir = theme_assets_dir/"icons"
        FileUtils.mkdir_p(theme_icons_dir)
        
        # Copy UI icons (could be theme-specific)
        ui_icons_dir = "#{icons_gem_dir}/ui"
        if Dir.exist?(ui_icons_dir)
          theme_ui_dir = theme_icons_dir/"ui"
          FileUtils.mkdir_p(theme_ui_dir)
          FileUtils.cp_r("#{ui_icons_dir}/.", theme_ui_dir)
        end
        
        # Copy social icons (could be theme-specific)
        social_icons_dir = "#{icons_gem_dir}/social"
        if Dir.exist?(social_icons_dir)
          theme_social_dir = theme_icons_dir/"social"
          FileUtils.mkdir_p(theme_social_dir)
          FileUtils.cp_r("#{social_icons_dir}/.", theme_social_dir)
        end
      end
    end
  rescue => e
    # If gem lookup fails, continue without copying gem assets
    # This is expected in development/testing environments
  end

  def self.copy_gem_assets_to_library(root)
    # Try to find gem assets and copy application-wide assets to the library
    gem_spec = Gem.loaded_specs['scriptorium']
    if gem_spec
      gem_assets_dir = "#{gem_spec.full_gem_path}/assets"
    else
      # Development environment - use the working path
      gem_assets_dir = File.expand_path("assets")
    end
    
    if Dir.exist?(gem_assets_dir)
      # Copy application-wide assets to library directory
      library_dir = root/"assets"/"library"
      FileUtils.mkdir_p(library_dir) unless Dir.exist?(library_dir)
      
      # Copy sample assets (application-wide)
      samples_gem_dir = "#{gem_assets_dir}/samples"
      if Dir.exist?(samples_gem_dir)
        FileUtils.cp_r("#{samples_gem_dir}/.", library_dir)
      end
    end
  rescue => e
    # If gem lookup fails, continue without copying gem assets
    # This is expected in development/testing environments
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
