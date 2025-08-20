class Scriptorium::API
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include Scriptorium::Contract

  attr_reader :repo, :current_view

  # Invariants
  def define_invariants
    invariant { [true, false].include?(@testing) }
    invariant { @repo.nil? || @repo.is_a?(Scriptorium::Repo) }
  end

  def initialize(testmode: false)
    assume { [true, false].include?(testmode) }
    
    @testing = testmode
    @repo = nil
    
    define_invariants
    verify { @testing == testmode }
    check_invariants
  end

  def repo_exists?(path)
    Dir.exist?(path)
  end

  def create_repo(path)
    check_invariants
    assume { path.is_a?(String) && !path.empty? }
    
    raise RepoDirAlreadyExists if repo_exists?(path)
    Scriptorium::Repo.create(path)
    @repo = Scriptorium::Repo.open(path)
    
    verify { @repo.is_a?(Scriptorium::Repo) }
    check_invariants
  end

  def open_repo(path)
    check_invariants
    assume { path.is_a?(String) && !path.empty? }
    
    @repo = Scriptorium::Repo.open(path)
    
    verify { @repo.is_a?(Scriptorium::Repo) }
    check_invariants
  end

  # View management
  def create_view(name, title, subtitle = "", theme: "standard")
    check_invariants
    assume { name.is_a?(String) }
    assume { title.is_a?(String) }
    assume { subtitle.is_a?(String) }
    assume { theme.is_a?(String) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.create_view(name, title, subtitle, theme: theme)
    
    verify { @repo.is_a?(Scriptorium::Repo) }
    check_invariants
    self
  end

  def current_view
    @repo&.current_view
  end

  def root
    @repo.root
  end

  def version
    Scriptorium::VERSION
  end

  def apply_theme(theme)
    @repo.view.apply_theme(theme)
  end

  # Post management
  def view(name = nil)
    if name.nil?
      @repo.current_view
    else
      result = @repo.view(name)
      result
    end
  end

  def views
    @repo&.views || []
  end

  def lookup_view(target)
    @repo&.lookup_view(target)
  end

  def views_for(post_or_id)
    post = post_or_id.is_a?(Integer) ? @repo.post(post_or_id) : post_or_id
    post.views&.split(/\s+/) || []
  end

  # Post creation with convenience defaults
  def create_post(title, body, views: nil, tags: nil, blurb: nil)
    check_invariants
    assume { title.is_a?(String) }
    assume { body.is_a?(String) }
    assume { views.nil? || views.is_a?(String) || views.is_a?(Array) }
    assume { tags.nil? || tags.is_a?(String) || tags.is_a?(Array) }
    assume { blurb.nil? || blurb.is_a?(String) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    views ||= @repo.current_view&.name
    raise "No view specified and no current view set" if views.nil?
    
    post = @repo.create_post(
      title: title,
      body: body,
      views: views,
      tags: tags,
      blurb: blurb
    )
    
    verify { post.is_a?(Scriptorium::Post) }
    check_invariants
    post
  end

  # Draft management
  def draft(title: nil, body: nil, views: nil, tags: nil, blurb: nil)
    views ||= @repo.current_view&.name
    raise "No view specified and no current view set" if views.nil?
    
    @repo.create_draft(
      title: title,
      body: body,
      views: views,
      tags: tags,
      blurb: blurb
    )
  end

  def create_draft(title: nil, body: nil, views: nil, tags: nil, blurb: nil)
    views ||= @repo.current_view&.name
    raise "No view specified and no current view set" if views.nil?
    
    @repo.create_draft(
      title: title,
      body: body,
      views: views,
      tags: tags,
      blurb: blurb
    )
  end

  def finish_draft(draft_path)
    @repo.finish_draft(draft_path)
  end

  # Generation
  def generate_front_page(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    @repo.generate_front_page(view)
  end

  def generate_post_index(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    @repo.generate_post_index(view)
  end

  def generate_post(post_id)
    # Check if the post directory exists first
    post_dir = @repo.root/:posts/d4(post_id)
    if Dir.exist?(post_dir)
      # Post directory exists, proceed with generation
      @repo.generate_post(post_id)
    else
      # Try to find the post through normal means
      post = @repo.post(post_id)
      raise "Post not found" if post.nil?
      
      @repo.generate_post(post_id)
    end
  end

  def lookup_view(view_name)
    @repo.lookup_view(view_name)
  end

  # Publication system
  def publish_post(num)
    check_invariants
    assume { num.is_a?(Integer) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    post = @repo.publish_post(num)
    
    verify { post.is_a?(Scriptorium::Post) }
    check_invariants
    post
  end

  def post_published?(num)
    @repo.post_published?(num)
  end

  def get_published_posts(view = nil)
    view ||= @repo.current_view&.name
    @repo.get_published_posts(view)
  end

  # Post retrieval
  def posts(view = nil)
    view ||= @repo.current_view&.name
    @repo.all_posts(view)
  end

  def post_attrs(post_id, *keys)
    post = post_id.is_a?(Integer) ? @repo.post(post_id) : post_id
    post.attrs(*keys)
  end

  def post(id)
    @repo.post(id)
  end

  # Post management
  def delete_post(id)
    post = @repo.post(id)
    old_path = @repo.root/:posts/post.num
    new_path = @repo.root/:posts/"_#{post.num}"
    FileUtils.mv(old_path, new_path)
    
    # Set the deleted flag in metadata
    post.meta["post.deleted"] = "true"
    post.save_metadata
  end

  def undelete_post(id)
    post = @repo.post(id)
    old_path = @repo.root/:posts/"_#{post.num}"
    new_path = @repo.root/:posts/post.num
    FileUtils.mv(old_path, new_path)
    
    # Clear the deleted flag in metadata
    post.meta["post.deleted"] = "false"
    post.save_metadata
  end

  def unlink_post(id, view = nil)
    # Remove post from a specific view (or current view if none specified)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    post = @repo.post(id)
    raise "Post not found" if post.nil?
    
    # Get current views from metadata (split string into array)
    current_views = post.views.strip.split(/\s+/)
    
    # Remove the specified view
    new_views = current_views - [view]
    
    # Update the post with new views list
    result = update_post(id, {views: new_views})
    
    # Regenerate the post to update metadata
    @repo.generate_post(id) if result
    
    result
  end

  def link_post(id, view = nil)
    # Add post to a specific view (or current view if none specified)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    post = @repo.post(id)
    raise "Post not found" if post.nil?
    
    current_views = post.views.strip.split(/\s+/)
    new_views = current_views.include?(view) ? current_views : current_views + [view]
    result = update_post(id, {views: new_views})
    
    @repo.generate_post(id) if result
    
    result
  end

  def post_add_view(id, view)
    # Add a view to a post (view can be string or View object)
    view_name = view.is_a?(String) ? view : view.name
    link_post(id, view_name)
  end

  def post_remove_view(id, view)
    # Remove a view from a post (view can be string or View object)
    view_name = view.is_a?(String) ? view : view.name
    unlink_post(id, view_name)
  end

  def post_add_tag(id, tag)
    # Add a tag to a post
    post = @repo.post(id)
    raise "Post not found" if post.nil?
    
    # Get current tags from metadata (split comma-separated string into array)
    current_tags = post.tags.strip.split(/,\s*/)
    
    # Add the tag (avoid duplicates)
    new_tags = current_tags.include?(tag) ? current_tags : current_tags + [tag]
    
    # Update the post with new tags list
    result = update_post(id, {tags: new_tags})
    
    # Regenerate the post to update metadata
    @repo.generate_post(id) if result
    
    result
  end

  def post_remove_tag(id, tag)
    # Remove a tag from a post
    post = @repo.post(id)
    raise "Post not found" if post.nil?
    
    # Get current tags from metadata (split comma-separated string into array)
    current_tags = post.tags.strip.split(/,\s*/)
    
    # Remove the tag
    new_tags = current_tags - [tag]
    
    # Update the post with new tags list
    result = update_post(id, {tags: new_tags})
    
    # Regenerate the post to update metadata
    @repo.generate_post(id) if result
    
    result
  end

  # Theme management
  def themes_available
    themes = []
    themes_dir = @repo.root/:themes
    
    if Dir.exist?(themes_dir)
      Dir.children(themes_dir).each do |item|
        next if item == "system.txt" || item.start_with?(".")
        next unless Dir.exist?(themes_dir/item)
        themes << item
      end
    end
    
    themes
  end
  
  def system_themes
    themes = []
    system_file = @repo.root/:themes/"system.txt"
    
    if File.exist?(system_file)
      themes = read_file(system_file, lines: true, chomp: true)
    end
    
    themes
  end
  
  def user_themes
    themes = []
    themes_dir = @repo.root/:themes
    system_themes_list = system_themes
    
    if Dir.exist?(themes_dir)
      Dir.children(themes_dir).each do |item|
        next if item == "system.txt" || item.start_with?(".")
        next unless Dir.exist?(themes_dir/item)
        next if system_themes_list.include?(item)
        themes << item
      end
    end
    
    themes
  end
  
  def theme_exists?(theme_name)
    # Check if theme name exists in themes directory
    themes = themes_available
    themes.include?(theme_name)
  end

  def clone_theme(source_theme, new_name)
    # Validate source theme exists
    unless theme_exists?(source_theme)
      raise "Source theme '#{source_theme}' not found"
    end
    
    # Validate new name doesn't exist
    if theme_exists?(new_name)
      raise "Theme '#{new_name}' already exists"
    end
    
    # Validate new name format (alphanumeric, hyphen, underscore)
    unless new_name.match?(/^[a-zA-Z0-9_-]+$/)
      raise "Theme name must contain only letters, numbers, hyphens, and underscores"
    end
    
    source_dir = @repo.root/:themes/source_theme
    target_dir = @repo.root/:themes/new_name
    
    # Copy theme directory
    require 'fileutils'
    FileUtils.cp_r(source_dir, target_dir)
    
    # Cloned themes become user themes (not system themes)
    # No need to modify system.txt
    
    new_name
  end

  def widgets_available
    widgets_file = @repo.root/:config/"widgets.txt"
    return [] unless File.exist?(widgets_file)
    read_file(widgets_file, lines: true, chomp: true)
  end

  def generate_widget(widget_name)
    # Generate a specific widget for the current view
    # widget_name: string name of the widget (e.g., "links", "news")
    # Returns true on success, raises error on failure
    
    raise "No current view set" if @repo.current_view.nil?
    raise "Widget name cannot be nil" if widget_name.nil?
    raise "Widget name cannot be empty" if widget_name.to_s.strip.empty?
    
    # Validate widget name format
    unless widget_name.to_s.match?(/^[a-zA-Z0-9_]+$/)
      raise "Invalid widget name: #{widget_name} (must be alphanumeric and underscore only)"
    end
    
    # Convert to class name (capitalize first letter)
    widget_class_name = widget_name.to_s.capitalize
    
    # Try to find the widget class
    begin
      widget_class = eval("Scriptorium::Widget::#{widget_class_name}")
    rescue NameError
      raise "Widget class not found: Scriptorium::Widget::#{widget_class_name}"
    end
    
    # Create widget instance and generate
    widget = widget_class.new(@repo, @repo.current_view)
    widget.generate
    
    true
  end

  # Convenience file editing methods
  
  def edit_layout(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    edit_file("views/#{view}/layout.txt")
  end

  def edit_config(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    edit_file("views/#{view}/config.txt")
  end

  def edit_widget_data(view = nil, widget)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    raise "Widget name cannot be nil" if widget.nil?
    edit_file("views/#{view}/widgets/#{widget}/list.txt")
  end

  def edit_repo_config
    edit_file("config/repo.txt")
  end

  def edit_deploy_config
    edit_file("config/deploy.txt")
  end

  def edit_post(post_id)
    post = @repo.post(post_id)
    source_path = "posts/#{post.num}/source.lt3"
    body_path = "posts/#{post.num}/body.html"
    
    if File.exist?(source_path)
      edit_file(source_path)
    else
      edit_file(body_path)
    end
  end

  # File operations
  
  def edit_file(path)
    # Input validation
    raise EditFilePathNil if path.nil?
    raise EditFilePathEmpty if path.to_s.strip.empty?
    
    # Try to use the TUI's editor configuration first
    editor_file = @repo.root/"config/editor.txt"
    editor = if File.exist?(editor_file)
      read_file(editor_file).strip
    else
      ENV['EDITOR'] || 'vim'
    end
    
    system!(editor, path)
  end

  # Post selection and search
  def select_posts(&block)
    # Filter posts using a block
    # Returns array of posts that match the block condition
    # Example: api.select_posts { |post| post.views.include?("alpha") }
    
    all_posts = @repo.all_posts
    all_posts.select(&block)
  end

  def search_posts(**criteria)
    # Search posts using keyword criteria
    # criteria: hash of {field: pattern} where field is :title, :body, :tags, :blurb
    # pattern: string (exact match) or regex (pattern match)
    # Example: api.search_posts(title: /Ruby/, tags: "scriptorium")
    
    all_posts = @repo.all_posts
    matching_posts = []
    
    all_posts.each do |post|
      matches_all_criteria = true
      
      criteria.each do |field, pattern|
        # Get the field value from the post
        field_value = case field
        when :title
          post.title
        when :body
          # Read the body from the source file
          body_file = post.dir/"body.html"
          File.exist?(body_file) ? read_file(body_file) : ""
        when :tags
          post.tags
              when :blurb
        post.blurb
        else
          raise "Unknown search field: #{field}"
        end
        
        # Check if the pattern matches
        if pattern.is_a?(Regexp)
          matches_all_criteria = false unless field_value.match?(pattern)
        else
          matches_all_criteria = false unless field_value.include?(pattern.to_s)
        end
        
        break unless matches_all_criteria
      end
      
      matching_posts << post if matches_all_criteria
    end
    
    matching_posts
  end

  # Generation
  def generate_view(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    @repo.generate_front_page(view)
    true
  end



  # Draft management
  def drafts
    drafts_dir = @repo.root/:drafts
    return [] unless Dir.exist?(drafts_dir)
    
    draft_files = Dir.children(drafts_dir).select { |f| f.end_with?('-draft.lt3') }
    draft_files.map do |filename|
      path = drafts_dir/filename
      # Quick scan for title from the draft file
      title = extract_title_from_draft(path)
      { path: path, title: title }
    end
  end

  def delete_draft(draft_path)
    # Delete a draft file
    # draft_path: path to the draft file (e.g., from drafts() method)
    
    raise "Draft path cannot be nil" if draft_path.nil?
    raise "Draft path cannot be empty" if draft_path.to_s.strip.empty?
    
    # Ensure it's actually a draft file
    unless draft_path.to_s.end_with?('-draft.lt3')
      raise "Not a valid draft file: #{draft_path}"
    end
    
    # Ensure it exists
    unless File.exist?(draft_path)
      raise "Draft file not found: #{draft_path}"
    end
    
    # Delete the file
    File.delete(draft_path)
    true
  end

  private def extract_title_from_draft(draft_path)
    # Quick scan for .title line in draft file
    return "Untitled" unless File.exist?(draft_path)
    
    File.foreach(draft_path) do |line|
      if line.strip.start_with?('.title')
        title = line.strip.split(/\s+/, 2)[1]
        return title || "Untitled"
      end
    end
    "Untitled"
  end

  def update_post(id, fields)
    # Update fields in the post's source.lt3 file
    # fields: hash of {field: value} where field is livetext dotcmd (e.g., :views, :title, :tags)
    # value: string or array of strings
    
    post = @repo.post(id)
    source_file = post.dir/"source.lt3"
    return false unless File.exist?(source_file)
    
    # Read the file
    lines = read_file(source_file, lines: true, chomp: false)
    updated = false
    
    # Process each field
    fields.each do |field, value|
      # Convert value to array
      value_array = Array(value)
      
      # Handle different field types
      case field
      when :tags
        # Tags should be comma-separated
        new_value = value_array.join(", ")
      else
        # Other fields (views, etc.) should be space-separated
        new_value = value_array.join(' ')
      end
      
      lines.map! do |line|
        if line.strip.start_with?(".#{field}")
          # Preserve trailing comments
          comment_match = line.match(/(\s+#.*)$/)
          comment = comment_match ? comment_match[1] : ""
          
          # Add change comment
          timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
          change_comment = " # updated #{field} #{timestamp}"
          
          updated = true
          ".#{field} #{new_value}#{comment}#{change_comment}\n"
        else
          line
        end
      end
    end
    
    return false unless updated
    
    # Write the updated file
    write_file(source_file, lines.join)
    true
  end

  # TODO: Discuss later - complex metadata vs source conflict handling
  # def update_post(id, attributes)
  #   # Need to decide: source of truth, update strategy, concurrency handling
  # end

  # TODO: Discuss later - publish draft workflow
  # def publish_draft(draft_path)
  #   # finish_draft + generate_post combined?
  # end

  # Asset management methods
  
  def list_assets(target: 'global', view: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if target == 'view' && view.nil?
    
    assets = []
    
    case target
    when 'view'
      assets_dir = @repo.root/"views"/view/"assets"
      if Dir.exist?(assets_dir)
        Dir.glob(assets_dir/"*").each do |file|
          next unless File.file?(file)
          assets << build_asset_info(file)
        end
      end
    when 'global'
      assets_dir = @repo.root/"assets"
      if Dir.exist?(assets_dir)
        Dir.glob(assets_dir/"*").each do |file|
          next unless File.file?(file)
          assets << build_asset_info(file)
        end
      end
    when 'library'
      assets_dir = @repo.root/"assets"/"library"
      if Dir.exist?(assets_dir)
        Dir.glob(assets_dir/"*").each do |file|
          next unless File.file?(file)
          assets << build_asset_info(file)
        end
      end
    when 'gem'
      if include_gem
        gem_spec = Gem.loaded_specs['scriptorium']
        if gem_spec
          gem_assets_dir = "#{gem_spec.full_gem_path}/assets"
          if Dir.exist?(gem_assets_dir)
            Dir.glob("#{gem_assets_dir}/**/*").each do |file|
              next unless File.file?(file)
              relative_path = file.sub("#{gem_assets_dir}/", "")
              assets << build_asset_info(file, relative_path)
            end
          end
        end
      end
    else
      raise "Invalid target: #{target}. Use 'view', 'global', 'library', or 'gem'"
    end
    
    assets.sort_by { |asset| asset[:filename] }
  end
  
  def get_asset_info(filename, target: 'global', view: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if target == 'view' && view.nil?
    
    case target
    when 'view'
      asset_path = @repo.root/"views"/view/"assets"/filename
      return build_asset_info(asset_path) if File.exist?(asset_path)
    when 'global'
      asset_path = @repo.root/"assets"/filename
      return build_asset_info(asset_path) if File.exist?(asset_path)
    when 'library'
      asset_path = @repo.root/"assets"/"library"/filename
      return build_asset_info(asset_path) if File.exist?(asset_path)
    when 'gem'
      if include_gem
        gem_spec = Gem.loaded_specs['scriptorium']
        if gem_spec
          gem_asset_path = "#{gem_spec.full_gem_path}/assets/#{filename}"
          return build_asset_info(gem_asset_path, filename) if File.exist?(gem_asset_path)
        end
      end
    else
      raise "Invalid target: #{target}. Use 'view', 'global', 'library', or 'gem'"
    end
    
    nil
  end
  
  def asset_exists?(filename, target: 'global', view: nil, include_gem: true)
    !get_asset_info(filename, target: target, view: view, include_gem: include_gem).nil?
  end
  
  def copy_asset(filename, from: 'global', to: 'view', view: nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if to == 'view' && view.nil?
    
    # Determine source path
    source_path = case from
    when 'gem'
      gem_spec = Gem.loaded_specs['scriptorium']
      if gem_spec
        "#{gem_spec.full_gem_path}/assets/#{filename}"
      else
        # Development environment fallback
        File.expand_path("assets/#{filename}")
      end
    when 'global'
      @repo.root/"assets"/filename
    when 'library'
      @repo.root/"assets"/"library"/filename
    when 'view'
      view ||= @repo.current_view&.name
      raise "No view specified and no current view set" if view.nil?
      @repo.root/"views"/view/"assets"/filename
    else
      raise "Invalid source: #{from}. Use 'gem', 'global', 'library', or 'view'"
    end
    
    # Determine target path
    target_path = case to
    when 'global'
      @repo.root/"assets"/filename
    when 'library'
      @repo.root/"assets"/"library"/filename
    when 'view'
      @repo.root/"views"/view/"assets"/filename
    else
      raise "Invalid target: #{to}. Use 'global', 'library', or 'view'"
    end
    
    # Validate source exists
    unless File.exist?(source_path)
      raise "Source file not found: #{source_path}"
    end
    
    # Create target directory and copy
    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(source_path, target_path)
    
    target_path
  end
  
  def upload_asset(file_path, target: 'global', view: nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if target == 'view' && view.nil?
    
    unless File.exist?(file_path)
      raise "Source file not found: #{file_path}"
    end
    
    filename = File.basename(file_path)
    
    # Determine target directory
    target_dir = case target
    when 'global'
      @repo.root/"assets"
    when 'library'
      @repo.root/"assets"/"library"
    when 'view'
      @repo.root/"views"/view/"assets"
    else
      raise "Invalid target: #{target}. Use 'global', 'library', or 'view'"
    end
    
    # Create target directory if it doesn't exist
    FileUtils.mkdir_p(target_dir)
    
    # Copy the file
    target_file = target_dir/filename
    FileUtils.cp(file_path, target_file)
    
    target_file
  end
  
  def delete_asset(filename, target: 'global', view: nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if target == 'view' && view.nil?
    
    # Determine target file
    target_file = case target
    when 'global'
      @repo.root/"assets"/filename
    when 'library'
      @repo.root/"assets"/"library"/filename
    when 'view'
      @repo.root/"views"/view/"assets"/filename
    else
      raise "Invalid target: #{target}. Use 'global', 'library', or 'view'"
    end
    
    unless File.exist?(target_file)
      raise "File not found: #{target_file}"
    end
    
    # Delete the file
    File.delete(target_file)
    true
  end
  
  def get_asset_path(filename, target: 'global', view: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if target == 'view' && view.nil?
    
    case target
    when 'view'
      asset_path = @repo.root/"views"/view/"assets"/filename
      return asset_path.to_s if File.exist?(asset_path)
    when 'global'
      asset_path = @repo.root/"assets"/filename
      return asset_path.to_s if File.exist?(asset_path)
    when 'library'
      asset_path = @repo.root/"assets"/"library"/filename
      return asset_path.to_s if File.exist?(asset_path)
    when 'gem'
      if include_gem
        gem_spec = Gem.loaded_specs['scriptorium']
        if gem_spec
          gem_asset_path = "#{gem_spec.full_gem_path}/assets/#{filename}"
          return gem_asset_path if File.exist?(gem_asset_path)
        end
      end
    else
      raise "Invalid target: #{target}. Use 'view', 'global', 'library', or 'gem'"
    end
    
    nil
  end
  
  def get_image_dimensions(file_path)
    return nil unless File.exist?(file_path)
    
    # Check if it's an image file
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.svg']
    return nil unless image_extensions.any? { |ext| file_path.downcase.end_with?(ext) }
    
    # Check if FastImage is available
    return nil unless defined?(FastImage)
    
    dimensions = FastImage.size(file_path)
    return dimensions ? "#{dimensions[0]}×#{dimensions[1]}" : nil
  rescue => e
    # If FastImage fails, return nil
    return nil
  end

  def get_asset_dimensions(filename, target: 'global', view: nil, include_gem: true)
    asset_info = get_asset_info(filename, target: target, view: view, include_gem: include_gem)
    asset_info&.dig(:dimensions)
  end
  
  def get_asset_size(filename, target: 'global', view: nil, include_gem: true)
    asset_info = get_asset_info(filename, target: target, view: view, include_gem: include_gem)
    asset_info&.dig(:size)
  end
  
  def get_asset_type(filename)
    return nil if filename.nil?
    
    ext = File.extname(filename).downcase
    case ext
    when '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.svg'
      'image'
    when '.pdf', '.doc', '.docx', '.txt', '.md'
      'document'
    when '.mp4', '.avi', '.mov', '.wmv'
      'video'
    when '.mp3', '.wav', '.flac'
      'audio'
    else
      'other'
    end
  end
  
  def bulk_copy_assets(filenames, from: 'global', to: 'view', view: nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if to == 'view' && view.nil?
    
    results = []
    filenames.each do |filename|
      begin
        target_path = copy_asset(filename, from: from, to: to, view: view)
        results << { filename: filename, success: true, target: target_path }
      rescue => e
        results << { filename: filename, success: false, error: e.message }
      end
    end
    
    results
  end
  
  private def build_asset_info(file_path, relative_path = nil)
    filename = relative_path || File.basename(file_path)
    size = File.size(file_path)
    dimensions = get_image_dimensions(file_path) if get_asset_type(filename) == 'image'
    
    {
      filename: filename,
      size: size,
      path: file_path.to_s,
      dimensions: dimensions,
      type: get_asset_type(filename)
    }
  end

  # Deployment methods
  
  def can_deploy?(view = nil)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    # Check deployment status
    status_file = @repo.root/"views"/view/"config"/"status.txt"
    return false unless File.exist?(status_file)
    
    status_content = read_file(status_file)
    deploy_status = false
    
    status_content.lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      if line.start_with?('deploy ')
        deploy_status = line.split(/\s+/, 2)[1] == 'y'
        break
      end
    end
    
    return false unless deploy_status
    
    # Check if deploy.txt exists and has valid content
    deploy_file = @repo.root/"views"/view/"config"/"deploy.txt"
    return false unless File.exist?(deploy_file)
    
    # Basic validation of deploy.txt content
    deploy_content = read_file(deploy_file)
    required_fields = ['user', 'server', 'docroot', 'path']
    return false unless required_fields.all? { |field| deploy_content.include?(field) }
    
    # Parse deploy config to get server and user for SSH test
    deploy_config = {}
    deploy_content.lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      if line.include?(' ')
        key, value = line.split(/\s+/, 2)
        deploy_config[key.to_sym] = value
      end
    end
    
    # Check SSH connectivity
    return false unless ssh_keys_configured?(deploy_config[:server], deploy_config[:user])
    
    true
  end
  
  private def ssh_keys_configured?(server, user)
    # Try to run a simple command via SSH
    result = system("ssh -o ConnectTimeout=5 -o BatchMode=yes #{user}@#{server} 'echo ok' 2>/dev/null")
    result && $?.exitstatus == 0
  end
  
  def deploy(view = nil, dry_run: false)
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    # Check if deployment is ready
    unless can_deploy?(view)
      raise "View '#{view}' is not ready for deployment. Check status and configuration."
    end
    
    # Read deployment configuration
    deploy_file = @repo.root/"views"/view/"config"/"deploy.txt"
    deploy_config = {}
    
    read_file(deploy_file).lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      if line.include?(' ')
        key, value = line.split(/\s+/, 2)
        deploy_config[key.to_sym] = value
      end
    end
    
    # Validate required fields
    required_fields = [:user, :server, :docroot, :path]
    missing_fields = required_fields - deploy_config.keys
    unless missing_fields.empty?
      raise "Missing required deployment fields: #{missing_fields.join(', ')}"
    end
    
    # Construct paths
    output_dir = @repo.root/"views"/view/"output"
    remote_path = "#{deploy_config[:user]}@#{deploy_config[:server]}:#{deploy_config[:docroot]}/#{deploy_config[:path]}"
    
    # Build rsync command
    cmd = "rsync -r -z -l #{output_dir}/ #{remote_path}/"
    
    if dry_run
      puts "DRY RUN: Would execute: #{cmd}"
      puts "Output directory: #{output_dir}"
      puts "Remote path: #{remote_path}"
      puts "Deployment config: #{deploy_config}"
      return true
    end
    
    # Execute deployment
    puts "Deploying view '#{view}' to #{remote_path}..."
    result = system(cmd)
    
    if result
      puts "Deployment successful!"
      # TODO: Update deployment timestamp in status or metadata
      true
    else
      raise "Deployment failed with exit code #{$?.exitstatus}"
    end
  end

  # Utility methods

#   # Delegate common repo methods
#   def method_missing(method, *args, &block)
#     if @repo.respond_to?(method)
#       @repo.send(method, *args, &block)
#     else
#       super
#     end
#   end
# 
#   def respond_to_missing?(method, include_private = false)
#     @repo.respond_to?(method, include_private) || super
#   end
end 
