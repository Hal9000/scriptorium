

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

  def testing
    @testing
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
    raise ViewTargetNil if views.nil?
    
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
    raise ViewTargetNil if views.nil?
    
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
    raise ViewTargetNil if views.nil?
    
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
    raise ViewTargetNil if view.nil?
    
    @repo.generate_front_page(view)
  end

  def generate_post_index(view = nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    
    # Get only published posts using the published parameter
    posts = posts(view, published: true)
    
    # Generate the index content
    str = ""
    posts.each { |post| str << post_index_entry(post, view) }
    
    # Write the file
    output_file = @repo.root/"views"/view/"output"/"post_index.html"
    File.write(output_file, str)
  end
  
  private def post_index_entry(post, view)
    # Get the view object to access its predef
    view_obj = @repo.lookup_view(view)
    template = view_obj.predef.index_entry
    substitute(post, template)
  end
  
  private def substitute(post, template)
    # Simple substitution - replace %{post.field} with post.field
    template.gsub(/%\{([^}]+)\}/) { |match| 
      field = $1.strip
      post.respond_to?(field) ? post.send(field) : match
    }
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
      raise CannotGetPost("Post with ID #{post_id} not found") if post.nil?
      
      @repo.generate_post(post_id)
    end
  end

  def lookup_view(view_name)
    @repo.lookup_view(view_name)
  end

  # Publication system
  def publish_post(num, view = nil)
    check_invariants
    assume { num.is_a?(Integer) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    post = @repo.publish_post(num, view)
    
    verify { post.is_a?(Scriptorium::Post) }
    check_invariants
    post
  end
  
  def unpublish_post(num, view = nil)
    check_invariants
    assume { num.is_a?(Integer) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.unpublish_post(num, view)
    
    check_invariants
  end

  def post_published?(num, view = nil)
    @repo.post_published?(num, view)
  end
  
  # Deployment state management
  def mark_post_deployed(num, view = nil)
    check_invariants
    assume { num.is_a?(Integer) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.mark_post_deployed(num, view)
    
    check_invariants
  end
  
  def mark_post_undeployed(num, view = nil)
    check_invariants
    assume { num.is_a?(Integer) }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.mark_post_undeployed(num, view)
    
    check_invariants
  end
  
  def post_deployed?(num, view = nil)
    @repo.post_deployed?(num, view)
  end
  
  def get_deployed_posts(view = nil)
    view ||= @repo.current_view&.name
    @repo.get_deployed_posts(view)
  end
  
  def get_post_states(view = nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    
    # Get normal posts
    posts = @repo.all_posts(view)
    states = {}
    
    # Add normal posts to states
    posts.each do |post|
      published = post_published?(post.id, view)
      deployed = post_deployed?(post.id, view)
      deleted = @repo.post_deleted?(post.id)
      
      # Create concise state representation
      state = ""
      state += "P" if published
      state += "D" if deployed
      state += "X" if deleted
      state = "-" if state.empty?
      
      states[post.id] = {
        id: post.id,
        title: post.title,
        state: state,
        published: published,
        deployed: deployed,
        deleted: deleted
      }
    end
    
    # Add deleted posts that were in this view
    deleted_posts = @repo.all_posts_including_deleted(view)
    deleted_posts.each do |post|
      if @repo.post_deleted?(post.id)
        states[post.id] = {
          id: post.id,
          title: post.title,
          state: "X",
          published: false,
          deployed: false,
          deleted: true
        }
      end
    end
    
    states
  end
  
  def delete_post(num)
    @repo.delete_post(num)
  end
  
  def undelete_post(num)
    @repo.undelete_post(num)
  end
  
  def post_deleted?(num)
    @repo.post_deleted?(num)
  end
  

  
  def undeploy_post(num, view = nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    
    # Check if post is actually deployed
    unless post_deployed?(num, view)
      puts "Post #{num} is not deployed in view '#{view}'"
      return false
    end
    
    # Mark as undeployed
    mark_post_undeployed(num, view)
    
    # Regenerate the post
    @repo.generate_post(num)
    
    # Redeploy to update the server
    deploy(view)
    
    puts "Post #{num} undeployed and redeployed in view '#{view}'"
    true
  end

  # Post retrieval
  def posts(view = nil, include_deleted: false, published: false)
    view ||= @repo.current_view&.name
    if include_deleted
      posts = @repo.all_posts_including_deleted(view)
    else
      posts = @repo.all_posts(view)
    end
    
    # Filter by published status if requested
    if published
      posts = posts.select { |post| post_published?(post.id, view) }
    end
    
    posts
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
    raise ViewTargetNil if view.nil?
    
    post = @repo.post(id)
    raise CannotGetPost("Post with ID #{id} not found") if post.nil?
    
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
    raise ViewTargetNil if view.nil?
    
    post = @repo.post(id)
    raise CannotGetPost("Post with ID #{id} not found") if post.nil?
    
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
    raise CannotGetPost("Post with ID #{id} not found") if post.nil?
    
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
    raise CannotGetPost("Post with ID #{id} not found") if post.nil?
    
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
      raise ThemeNotFound(source_theme)
    end
    
    # Validate new name doesn't exist
    if theme_exists?(new_name)
      raise ThemeAlreadyExists(new_name)
    end
    
    # Validate new name format (alphanumeric, hyphen, underscore)
    unless new_name.match?(/^[a-zA-Z0-9_-]+$/)
      raise ThemeNameInvalid(new_name)
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
    
    raise ViewTargetNil if @repo.current_view.nil?
    raise WidgetNameNil if widget_name.nil?
    raise WidgetsArgEmpty if widget_name.to_s.strip.empty?
    
    # Validate widget name format
    unless widget_name.to_s.match?(/^[a-zA-Z0-9_]+$/)
      raise WidgetNameInvalid(widget_name)
    end
    
    # Convert to class name (capitalize first letter)
    widget_class_name = widget_name.to_s.capitalize
    
    # Try to find the widget class
    begin
      widget_class = eval("Scriptorium::Widget::#{widget_class_name}")
    rescue NameError
      raise CannotBuildWidget("Widget class not found: Scriptorium::Widget::#{widget_class_name}")
    end
    
    # Create widget instance and generate
    widget = widget_class.new(@repo, @repo.current_view)
    widget.generate
    
    true
  end

  # Convenience file editing methods
  
  def edit_layout(view = nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    edit_file("views/#{view}/layout.txt")
  end

  def edit_config(view = nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    edit_file("views/#{view}/config.txt")
  end

  def edit_widget_data(view = nil, widget)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    raise WidgetNameNil if widget.nil?
    edit_file("views/#{view}/widgets/#{widget}/list.txt")
  end

  def edit_repo_config
    edit_file("config/repo.txt")
  end

  def edit_deploy_config
    edit_file("config/deploy.txt")
  end

    def edit_post(post_id, mock: false)
    # Check if post is deleted first
    if post_deleted?(post_id)
      raise PostDeleted, "Post #{post_id} is deleted"
    end
    
    post = @repo.post(post_id)
    source_path = @repo.root/"posts/#{post.num}/source.lt3"
    body_path = @repo.root/"posts/#{post.num}/body.html"
    
    # Save checksum before edit
    if File.exist?(source_path)
      before_checksum = Digest::MD5.file(source_path).hexdigest
      
      if mock.is_a?(Array) && mock.include?(:checksum)
        # Use mock checksum for testing
        after_checksum = mock[mock.index(:checksum) + 1]
      else
        edit_file(source_path) unless mock
        after_checksum = Digest::MD5.file(source_path).hexdigest
      end
    else
      raise "Cannot edit post #{post_id}: source.lt3 file not found"
    end
    
    # Check if file was actually modified
    if before_checksum != after_checksum
      # Mark as unpublished and undeployed in all views
      @repo.views.each do |view|
        if post_deployed?(post_id, view.name)
          mark_post_undeployed(post_id, view.name)
        end
        if post_published?(post_id, view.name)
          unpublish_post(post_id, view.name)
        end
      end
      
      # Regenerate the post
      @repo.generate_post(post_id)
      
      true  # Changes were made
    else
      false # No changes
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
          raise UnknownSearchField(field)
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
    raise ViewTargetNil if view.nil?
    
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
    
    raise DraftPathNil if draft_path.nil?
    raise DraftPathEmpty if draft_path.to_s.strip.empty?
    
    # Ensure it's actually a draft file
    unless draft_path.to_s.end_with?('-draft.lt3')
      raise DraftFileInvalid(draft_path)
    end
    
    # Ensure it exists
    unless File.exist?(draft_path)
      raise DraftFileNotFound(draft_path)
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
    raise ViewTargetNil if target == 'view' && view.nil?
    
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
      raise InvalidFormatError("target", target)
    end
    
    assets.sort_by { |asset| asset[:filename] }
  end
  
  def get_asset_info(filename, target: 'global', view: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if target == 'view' && view.nil?
    
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
        raise InvalidFormatError("target", target)
    end
    
    nil
  end
  
  def asset_exists?(filename, target: 'global', view: nil, include_gem: true)
    !get_asset_info(filename, target: target, view: view, include_gem: include_gem).nil?
  end
  
  def copy_asset(filename, from: 'global', to: 'view', view: nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if to == 'view' && view.nil?
    
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
        raise ViewTargetNil if view.nil?
        @repo.root/"views"/view/"assets"/filename
      else
        raise InvalidFormatError("source", from)
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
      raise InvalidFormatError("target", to)
    end
    
    # Validate source exists
    unless File.exist?(source_path)
      raise FileNotFoundError(source_path)
    end
    
    # Create target directory and copy
    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(source_path, target_path)
    
    target_path
  end
  
  def upload_asset(file_path, target: 'global', view: nil)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if target == 'view' && view.nil?
    
    unless File.exist?(file_path)
      raise FileNotFoundError(file_path)
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
      raise InvalidFormatError("target", target)
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
    raise ViewTargetNil if target == 'view' && view.nil?
    
    # Determine target file
    target_file = case target
    when 'global'
      @repo.root/"assets"/filename
    when 'library'
      @repo.root/"assets"/"library"/filename
    when 'view'
      @repo.root/"views"/view/"assets"/filename
    else
      raise InvalidFormatError("target", target)
    end
    
    unless File.exist?(target_file)
      raise FileNotFoundError(target_file)
    end
    
    # Delete the file
    File.delete(target_file)
    true
  end
  
  def get_asset_path(filename, target: 'global', view: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if target == 'view' && view.nil?
    
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
        raise InvalidFormatError("target", target)
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
    raise ViewTargetNil if to == 'view' && view.nil?
    
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
    raise ViewTargetNil if view.nil?
    # Check deployment status
    status_file = @repo.root/"views"/view/"config"/"status.txt"
    return false unless File.exist?(status_file)
    status_content = read_commented_file(status_file)
    deploy_status = status_content.any? { |line| line.start_with?('deploy ') && line.split(/\s+/, 2)[1] == 'y' }
    return false unless deploy_status
    # Check if deploy.txt exists and has valid content
    deploy_file = @repo.root/"views"/view/"config"/"deploy.txt"
    return false unless File.exist?(deploy_file)
    # Basic validation of deploy.txt content
    deploy_content = read_file(deploy_file)
    required_fields = ['user', 'server', 'docroot', 'path']
    return false unless required_fields.all? { |field| deploy_content.include?(field) }
    # Parse deploy config to get server and user for SSH test
    deploy_config = parse_commented_file(deploy_file)
    # Check SSH connectivity
    server, user = deploy_config[:server], deploy_config[:user]
    ok = ssh_keys_configured?(server, user)
    return false if !ok
    true
  end
  
  private def ssh_keys_configured?(server, user)
    # Try to run a simple command via SSH
    cmd = "ssh -o ConnectTimeout=5 -o BatchMode=yes #{user}@#{server} 'echo' >/dev/null 2>&1"
    result = system(cmd)
    result && $?.exitstatus == 0
  end
  
  def deploy(view = nil, dry_run: false)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if view.nil?
    raise DeploymentNotReady(view) unless can_deploy?(view)
    
    # Get published posts that are not yet deployed
    published_posts = posts(view, published: true)
    undeployed_posts = published_posts.select { |post| !post_deployed?(post.id, view) }
    
    # Always deploy the entire output directory, regardless of post status
    
    # Read deployment configuration
    deploy_file = @repo.root/"views"/view/"config"/"deploy.txt"
    deploy_config = parse_commented_file(deploy_file)
    
    # Validate required fields
    required_fields = [:user, :server, :docroot, :path]
    missing_fields = required_fields - deploy_config.keys
    missing = missing_fields.join(', ')
    raise DeploymentFieldsMissing(missing) unless missing.empty?
    
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
      puts "Posts to deploy: #{undeployed_posts.map(&:id).join(', ')}"
      return true
    end
    
    # Log deployment details to /tmp
    log_file = "/tmp/deployment.log"
    File.open(log_file, 'a') do |f|
      f.puts "=== DEPLOYMENT DEBUG #{Time.now} ==="
      f.puts "  Source directory: #{output_dir}"
      f.puts "  Remote path: #{remote_path}"
      f.puts "  Rsync command: #{cmd}"
      f.puts "  Source directory exists: #{Dir.exist?(output_dir)}"
      f.puts "  Source files: #{Dir.children(output_dir).join(', ')}"
      f.puts "  Current working directory: #{Dir.pwd}"
      f.puts "  Repo root: #{@repo.root}"
    end
    
    # Execute deployment
    result = system(cmd)
    
    # Log rsync result
    File.open("/tmp/deployment.log", 'a') do |f|
      f.puts "  Rsync result: #{result}"
      f.puts "  Exit status: #{$?.exitstatus}"
      f.puts "  Exit success: #{$?.success?}"
    end
    
    if result
      # Mark successfully deployed posts as deployed
      undeployed_posts.each do |post|
        mark_post_deployed(post.id, view)
      end
      
      puts "Successfully deployed #{undeployed_posts.length} posts: #{undeployed_posts.map(&:id).join(', ')}"
      true
    else
      raise DeploymentFailed($?.exitstatus)
    end
  end

  # Parse deployment configuration file
  def parse_deploy_config(config_content)
    lines = config_content.strip.split("\n")
    config = {}
    
    # Parse space-separated key-value format
    lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      if line.match(/^(\w+)\s+(.+)$/)
        key = $1.strip
        value = $2.strip
        config[key] = value
      end
    end
    
    # Return the config hash (or empty hash if no valid entries)
    config
  end

  # Build rsync destination from deployment config
  def build_rsync_destination(config)
    if config['user'] && config['server'] && config['path']
      return "#{config['user']}@#{config['server']}:#{config['path']}"
    end
    nil
  end

  # Validate rsync destination format
  def validate_rsync_destination(destination)
    destination =~ /^[^@]+@[^:]+:.+/
  end

  # Execute deployment rsync with validation
  def execute_deploy_rsync(source_dir, destination)
    # Validate destination format
    unless validate_rsync_destination(destination)
      puts "  ❌ Invalid destination format: #{destination}"
      puts "  Expected format: user@server:path"
      return false
    end
    
    # Log the rsync command
    cmd = "rsync -r -z -l #{source_dir}/ #{destination}/"
    puts "  Executing: #{cmd}"
    
    # Execute rsync
    result = system(cmd)
    puts "  rsync completed with result: #{result}"
    
    result
  end

end 
