

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
    msg = "testmode must be true or false, got #{testmode}"
    assume(msg) { [true, false].include?(testmode) }
    
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
    msg = "path must be a non-empty String, got #{path.class} (#{path.inspect})"
    assume(msg) { path.is_a?(String) && !path.empty? }
    
    raise RepoDirAlreadyExists if repo_exists?(path)
    Scriptorium::Repo.create(path)
    @repo = Scriptorium::Repo.open(path)
    
    verify { @repo.is_a?(Scriptorium::Repo) }
    check_invariants
  end

  def open_repo(path)
    check_invariants
    msg = "path must be a non-empty String, got #{path.class} (#{path.inspect})"
    assume(msg) { path.is_a?(String) && !path.empty? }
    
    @repo = Scriptorium::Repo.open(path)
    
    verify { @repo.is_a?(Scriptorium::Repo) }
    check_invariants
  end

  # View management
  def create_view(name, title, subtitle = "", theme: "standard")
    check_invariants
    msg = "name must be a String, got #{name.class}"
    assume(msg) { name.is_a?(String) }
    msg = "title must be a String, got #{title.class}"
    assume(msg) { title.is_a?(String) }
    msg = "subtitle must be a String, got #{subtitle.class}"
    assume(msg) { subtitle.is_a?(String) }
    msg = "theme must be a String, got #{theme.class}"
    assume(msg) { theme.is_a?(String) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
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
    msg = "title must be a String, got #{title.class}"
    assume(msg) { title.is_a?(String) }
    msg = "body must be a String, got #{body.class}"
    assume(msg) { body.is_a?(String) }
    msg = "views must be nil, String, or Array, got #{views.class}"
    assume(msg) { views.nil? || views.is_a?(String) || views.is_a?(Array) }
    msg = "tags must be nil, String, or Array, got #{tags.class}"
    assume(msg) { tags.nil? || tags.is_a?(String) || tags.is_a?(Array) }
    msg = "blurb must be nil or String, got #{blurb.class}"
    assume(msg) { blurb.nil? || blurb.is_a?(String) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
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

  def create_page(view_name, page_name, title, content)
    view = @repo.lookup_view(view_name)
    raise ViewTargetNil if view.nil?
    
    page_content = <<~LT3
      .title #{title}
      
      #{content}
    LT3
    
    page_file = "#{@repo.root}/views/#{view_name}/pages/#{page_name}.lt3"
    write_file(page_file, page_content)
    
    page_name
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
    template = support_data('templates/index_entry.lt3')
    substitute(post, template)
  end
  
  private def substitute(post, template)
    # Use the same substitution system as helpers - text % vars
    vars = post.vars
    template % vars
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
    msg = "num must be an Integer, got #{num.class}"
    assume(msg) { num.is_a?(Integer) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
    post = @repo.publish_post(num, view)
    
    verify { post.is_a?(Scriptorium::Post) }
    check_invariants
    post
  end
  
  def unpublish_post(num, view = nil)
    check_invariants
    msg = "num must be an Integer, got #{num.class}"
    assume(msg) { num.is_a?(Integer) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.unpublish_post(num, view)
    
    check_invariants
  end

  def post_published?(num, view = nil)
    @repo.post_published?(num, view)
  end
  
  # Deployment state management
  def mark_post_deployed(num, view = nil)
    check_invariants
    msg = "num must be an Integer, got #{num.class}"
    assume(msg) { num.is_a?(Integer) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
    @repo.mark_post_deployed(num, view)
    
    check_invariants
  end
  
  def mark_post_undeployed(num, view = nil)
    check_invariants
    msg = "num must be an Integer, got #{num.class}"
    assume(msg) { num.is_a?(Integer) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
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
    
    # Check for stale posts and regenerate them before view generation
    regenerate_stale_posts(view)
    
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

  private def regenerate_stale_posts(view)
    # Get all posts for this view
    posts = @repo.all_posts(view)
    
    posts.each do |post|
      source_file = post.dir/"source.lt3"
      body_file = post.dir/"body.html"
      
      # Skip if source file doesn't exist
      next unless File.exist?(source_file)
      
      # Skip if body file doesn't exist (post needs initial generation)
      next unless File.exist?(body_file)
      
      # Compare modification times
      source_mtime = File.mtime(source_file)
      body_mtime = File.mtime(body_file)
      
      # If source is newer than body, regenerate the post
      if source_mtime > body_mtime
        @repo.generate_post(post.id)
      end
    end
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
  
  def list_assets(target = 'global', target_id = nil, include_gem: true, **kwargs)
    # Handle backward compatibility with keyword arguments
    if kwargs.any?
      target = kwargs[:target] || target
      target_id = kwargs[:view] || target_id
    end
    assets = []
    
    case target
    when 'view'
      target_id ||= @repo.current_view&.name
      raise ViewTargetNil if target_id.nil?
      assets_dir = @repo.root/"views"/target_id/"assets"
      if Dir.exist?(assets_dir)
        Dir.glob(assets_dir/"*").each do |file|
          next unless File.file?(file)
          assets << build_asset_info(file)
        end
      end
    when 'post'
      raise ArgumentError, "Post ID required for post assets" if target_id.nil?
      post_id = target_id.to_i
      post_num = d4(post_id)
      assets_dir = @repo.root/"posts"/post_num/"assets"
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
  
  def get_asset_info(filename, target: 'global', view: nil, post: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if target == 'view' && view.nil?
    raise ArgumentError, "Post ID required for post assets" if target == 'post' && post.nil?
    
    case target
    when 'view'
      asset_path = @repo.root/"views"/view/"assets"/filename
      return build_asset_info(asset_path) if File.exist?(asset_path)
    when 'post'
      post_id = post.to_i
      post_num = d4(post_id)
      asset_path = @repo.root/"posts"/post_num/"assets"/filename
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
  
  def copy_asset(filename, from = 'global', to = 'view', from_id = nil, to_id = nil, **kwargs)
    # Handle backward compatibility with keyword arguments
    if kwargs.any?
      from = kwargs[:from] || from
      to = kwargs[:to] || to
      from_id = kwargs[:view] || from_id
      to_id = kwargs[:view] || to_id if to == 'view'
    end
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
      from_id ||= @repo.current_view&.name
      raise ViewTargetNil if from_id.nil?
      @repo.root/"views"/from_id/"assets"/filename
    when 'post'
      raise ArgumentError, "Post ID required for post assets" if from_id.nil?
      post_id = from_id.to_i
      post_num = d4(post_id)
      @repo.root/"posts"/post_num/"assets"/filename
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
      to_id ||= @repo.current_view&.name
      raise ViewTargetNil if to_id.nil?
      @repo.root/"views"/to_id/"assets"/filename
    when 'post'
      raise ArgumentError, "Post ID required for post assets" if to_id.nil?
      post_id = to_id.to_i
      post_num = d4(post_id)
      @repo.root/"posts"/post_num/"assets"/filename
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
  
  def upload_asset(file_path, target = 'global', target_id = nil, **kwargs)
    # Handle backward compatibility with keyword arguments
    if kwargs.any?
      target = kwargs[:target] || target
      target_id = kwargs[:view] || target_id
    end
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
      target_id ||= @repo.current_view&.name
      raise ViewTargetNil if target_id.nil?
      @repo.root/"views"/target_id/"assets"
    when 'post'
      raise ArgumentError, "Post ID required for post uploads" if target_id.nil?
      post_id = target_id.to_i
      post_num = d4(post_id)
      @repo.root/"posts"/post_num/"assets"
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
  
  def delete_asset(filename, target = 'global', target_id = nil, **kwargs)
    # Handle backward compatibility with keyword arguments
    if kwargs.any?
      target = kwargs[:target] || target
      target_id = kwargs[:view] || target_id
    end
    # Determine target file
    target_file = case target
    when 'global'
      @repo.root/"assets"/filename
    when 'library'
      @repo.root/"assets"/"library"/filename
    when 'view'
      target_id ||= @repo.current_view&.name
      raise ViewTargetNil if target_id.nil?
      @repo.root/"views"/target_id/"assets"/filename
    when 'post'
      raise ArgumentError, "Post ID required for post assets" if target_id.nil?
      post_id = target_id.to_i
      post_num = d4(post_id)
      @repo.root/"posts"/post_num/"assets"/filename
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
  
  def get_asset_path(filename, target: 'global', view: nil, post: nil, include_gem: true)
    view ||= @repo.current_view&.name
    raise ViewTargetNil if target == 'view' && view.nil?
    raise ArgumentError, "Post ID required for post assets" if target == 'post' && post.nil?
    
    case target
    when 'view'
      asset_path = @repo.root/"views"/view/"assets"/filename
      return asset_path.to_s if File.exist?(asset_path)
    when 'post'
      post_id = post.to_i
      post_num = d4(post_id)
      asset_path = @repo.root/"posts"/post_num/"assets"/filename
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

  # Backup system methods
  
  def get_backup_directory
    repo_path = Pathname.new(@repo.root)
    repo_parent = repo_path.parent
    repo_name = repo_path.basename.to_s
    if repo_name == "scriptorium-TEST"
      repo_parent/"backup-scriptorium-TEST"
    else
      repo_parent/"backup-scriptorium"
    end
  end
  
  def create_backup(type: :incremental, label: nil)
    check_invariants
    msg = "type must be :full or :incremental, got #{type}"
    assume(msg) { [:full, :incremental].include?(type) }
    msg = "@repo must be a Scriptorium::Repo, got #{@repo.class}"
    assume(msg) { @repo.is_a?(Scriptorium::Repo) }
    
    backup_dir = get_backup_directory
    data_dir = backup_dir/"data"
    FileUtils.mkdir_p(data_dir)
    
    # Sleep 1 second to ensure backup timestamp is clearly after all existing files
    sleep(1)
    
    if type == :full
      # Full backup - copy entire repository
      temp_backup_path = data_dir/"temp-full-backup"
      FileUtils.mkdir_p(temp_backup_path)
      copy_repo_to_backup(temp_backup_path)
    else
      # Incremental backup - copy only changed files since last backup
      temp_backup_path = data_dir/"temp-incr-backup"
      FileUtils.mkdir_p(temp_backup_path)
      copy_changed_files_to_backup(temp_backup_path)
    end
    
    # Record timestamp AFTER backup is created
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    backup_name = "#{timestamp}-#{type == :full ? 'full' : 'incr'}"
    
    # Create final backup directory
    final_backup_path = data_dir/backup_name
    FileUtils.mkdir_p(final_backup_path)
    
    # Create backup info file in final directory
    create_backup_info(final_backup_path, type, backup_name)
    
    # Compress the backup data into data.tar.gz
    compress_backup_data(temp_backup_path, final_backup_path/"data.tar.gz")
    
    # Remove temporary directory
    FileUtils.rm_rf(temp_backup_path)
    
    # Update backup manifest
    update_backup_manifest(backup_name, type, label)
    
    # Cleanup old backups
    cleanup_old_backups
    
    verify { File.exist?(final_backup_path) }
    verify { File.exist?(final_backup_path/"data.tar.gz") }
    check_invariants
    backup_name
  end
  
  def list_backups
    check_invariants
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return [] unless File.exist?(manifest_file)
    
    backups = []
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      timestamp_type = parts[0]
      description = parts.length > 1 ? parts[1..-1].join(' ') : nil
      
      # Parse timestamp-type
      if timestamp_type.match(/^(\d{8}-\d{6})-(full|incr)$/)
        timestamp_str = $1
        type = $2 == 'full' ? :full : :incremental
        
        # Convert timestamp to Time object
        begin
          timestamp = Time.strptime(timestamp_str, "%Y%m%d-%H%M%S")
          backups << {
            name: timestamp_type,
            type: type,
            description: description,
            timestamp: timestamp,
            size: calculate_backup_size(timestamp_type),
            file_count: count_backup_files(timestamp_type)
          }
        rescue ArgumentError
          # Skip invalid timestamps
          next
        end
      end
    end
    
    backups.sort_by { |b| b[:timestamp] }.reverse
  end
  
  def restore_backup(backup_name, strategy: :safe)
    check_invariants
    backup_dir = get_backup_directory
    backup_path = backup_dir/"data"/backup_name
    raise BackupNotFound, "Backup '#{backup_name}' not found" unless File.exist?(backup_path)
    
    case strategy
    when :safe
      # Always create pre-restore backup, then restore
      pre_restore = create_backup(type: :full, label: "pre-restore-#{backup_name}")
      # Small delay to ensure pre-restore backup has different timestamp
      sleep(2)
      restore_from_backup(backup_path)
      verify { File.exist?(@repo.root/"posts") }
      check_invariants
      { restored: backup_name, pre_restore: pre_restore }
      
    when :merge
      # Keep existing files, only restore backup files
      restore_files_from_backup(backup_path)
      verify { File.exist?(@repo.root/"posts") }
      check_invariants
      { restored: backup_name, strategy: :merge }
      
    when :destroy
      # Current behavior - clear everything and restore
      restore_from_backup(backup_path)
      verify { File.exist?(@repo.root/"posts") }
      check_invariants
      { restored: backup_name, strategy: :destroy }
      
    else
      raise ArgumentError, "Invalid restore strategy: #{strategy}. Must be :safe, :merge, or :destroy"
    end
  end
  
  def delete_backup(backup_name)
    check_invariants
    backup_dir = get_backup_directory
    backup_path = backup_dir/"data"/backup_name
    raise BackupNotFound, "Backup '#{backup_name}' not found" unless File.exist?(backup_path)
    
    # Remove backup directory
    FileUtils.rm_rf(backup_path)
    
    # Update manifest
    update_backup_manifest_remove(backup_name)
    
    verify { !File.exist?(backup_path) }
    check_invariants
    true
  end
  
  private def copy_repo_to_backup(backup_path)
    # Copy all repository files except backups directory
    Dir.glob(@repo.root/"**/*").each do |file_path|
      next unless File.file?(file_path)
      next if file_path.to_s.include?("/backups/")
      
      file_pathname = Pathname.new(file_path)
      repo_root_pathname = Pathname.new(@repo.root)
      relative_path = file_pathname.relative_path_from(repo_root_pathname)
      dest_path = backup_path/relative_path
      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp(file_path, dest_path)
    end
  end
  
  private def compress_backup_data(source_dir, tar_gz_path)
    # Ensure target directory exists
    FileUtils.mkdir_p(File.dirname(tar_gz_path))
    
    # Convert to absolute paths
    source_dir = File.absolute_path(source_dir)
    tar_gz_path = File.absolute_path(tar_gz_path)
    
    # Check if source directory has any files
    files = Dir.glob(source_dir/"**/*").select { |f| File.file?(f) }
    if files.empty?
      # Create empty tar.gz if no files
      system("tar -czf '#{tar_gz_path}' -T /dev/null")
    else
      # Change to source directory to create relative paths in tar
      Dir.chdir(source_dir) do
        # Create tar.gz archive with all files in source directory
        system("tar -czf '#{tar_gz_path}' .")
      end
    end
    
    raise "Failed to create compressed backup" unless $?.success?
  end
  
  private def create_backup_info(backup_path, type, backup_name)
    # Get version information
    scriptorium_version = Scriptorium::VERSION
    livetext_version = get_livetext_version
    ruby_version = RUBY_VERSION
    platform = "#{RUBY_PLATFORM} #{RUBY_ENGINE}"
    
    # Calculate backup statistics
    file_count = count_files_in_backup(backup_path)
    total_size = calculate_directory_size(backup_path)
    
    # Get git commit if available
    git_commit = get_git_commit_hash
    
    # Create backup info content
    info_content = <<~INFO
      # Scriptorium Backup Information
      # Generated: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
      scriptorium_version: #{scriptorium_version}
      livetext_version: #{livetext_version}
      ruby_version: #{ruby_version}
      backup_type: #{type}
      backup_name: #{backup_name}
      repository_path: #{@repo.root}
      file_count: #{file_count}
      total_size: #{total_size}
      platform: #{platform}
      git_commit: #{git_commit}
    INFO
    
    # Write backup info file
    info_file = backup_path/"backup-info.txt"
    File.write(info_file, info_content)
  end
  
  private def get_livetext_version
    # Try to get LiveText version from command line
    result = `livetext -v 2>/dev/null`.strip
    result.empty? ? "unknown" : result
  rescue
    "unknown"
  end
  
  private def get_git_commit_hash
    # Try to get git commit hash if in a git repository
    result = `git rev-parse HEAD 2>/dev/null`.strip
    result.empty? ? "unknown" : result[0..7] # First 8 characters
  rescue
    "unknown"
  end
  
  private def count_files_in_backup(backup_path)
    # Check if this is a compressed backup
    tar_gz_path = backup_path/"data.tar.gz"
    if File.exist?(tar_gz_path)
      # Count files in compressed archive using tar -tf
      output = `tar -tf #{tar_gz_path} 2>/dev/null`
      return 0 unless $?.success?
      output.lines.count { |line| !line.strip.empty? }
    else
      # Legacy uncompressed backup
      count = 0
      Dir.glob(backup_path/"**/*").each do |file_path|
        count += 1 if File.file?(file_path)
      end
      count
    end
  end
  
  private def calculate_directory_size(backup_path)
    # Check if this is a compressed backup
    tar_gz_path = backup_path/"data.tar.gz"
    if File.exist?(tar_gz_path)
      # Get size of compressed file plus backup-info.txt
      compressed_size = File.size(tar_gz_path)
      info_size = File.exist?(backup_path/"backup-info.txt") ? File.size(backup_path/"backup-info.txt") : 0
      compressed_size + info_size
    else
      # Legacy uncompressed backup
      size = 0
      Dir.glob(backup_path/"**/*").each do |file_path|
        size += File.size(file_path) if File.file?(file_path)
      end
      size
    end
  end
  
  private def copy_changed_files_to_backup(backup_path)
    last_backup_time = get_last_backup_time
    changed_files = find_changed_files_since(last_backup_time)
    
    changed_files.each do |file_path|
      file_pathname = Pathname.new(file_path)
      repo_root_pathname = Pathname.new(@repo.root)
      relative_path = file_pathname.relative_path_from(repo_root_pathname)
      dest_path = backup_path/relative_path
      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp(file_path, dest_path)
    end
  end
  
  private def find_changed_files_since(since_time)
    return [] unless since_time
    
    # Get the most recent backup to compare against
    last_backup = get_last_backup_name
    return [] unless last_backup
    
    backup_dir = get_backup_directory
    last_backup_path = backup_dir/"data"/last_backup
    last_backup_tar = last_backup_path/"data.tar.gz"
    
    # If no compressed backup exists, fall back to file system comparison
    unless File.exist?(last_backup_tar)
      return find_changed_files_since_filesystem(since_time)
    end
    
    # Get file timestamps from the last backup's tar TOC
    last_backup_files = get_tar_file_timestamps(last_backup_tar)
    
    changed_files = []
    Dir.glob(@repo.root/"**/*").each do |file_path|
      next unless File.file?(file_path)
      next if file_path.to_s.include?("/backups/")
      
      file_pathname = Pathname.new(file_path)
      repo_root_pathname = Pathname.new(@repo.root)
      relative_path = file_pathname.relative_path_from(repo_root_pathname).to_s
      
      current_mtime = File.mtime(file_path)
      # Try both with and without ./ prefix
      last_mtime = last_backup_files[relative_path] || last_backup_files["./#{relative_path}"]
      
      # File is changed if it's new or modified
      if last_mtime.nil? || current_mtime > last_mtime
        changed_files << file_path
      end
    end
    changed_files
  end
  
  private def find_changed_files_since_filesystem(since_time)
    changed_files = []
    Dir.glob(@repo.root/"**/*").each do |file_path|
      next unless File.file?(file_path)
      next if file_path.to_s.include?("/backups/")
      
      if File.mtime(file_path) > since_time
        changed_files << file_path
      end
    end
    
    changed_files
  end
  
  private def get_last_backup_name
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return nil unless File.exist?(manifest_file)
    
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      backup_name = parts[0]
      if backup_name.match(/^\d{8}-\d{6}-(full|incr)$/)
        return backup_name
      end
    end
    
    nil
  end
  
  private def get_tar_file_timestamps(tar_gz_path)
    file_timestamps = {}
    
    # Use tar -tvf to get file list with timestamps
    output = `tar -tvf #{tar_gz_path} 2>/dev/null`
    return file_timestamps unless $?.success?
    
    output.lines.each do |line|
      # Parse tar -tvf output format:
      # -rw-r--r-- user/group size date time filename
      # drwxr-xr-x user/group size date time filename
      # Format: drwxr-xr-x  0 Hal    staff       0 Sep  7 22:06 ./
      if line.match(/^[d-]\S+\s+\d+\s+\S+\s+\S+\s+\d+\s+(\w{3})\s+(\d{1,2})\s+(\d{2}:\d{2})\s+(.+?)\s*$/)
        month_str = $1
        day_str = $2
        time_str = $3
        filename = $4
        
        begin
          # Parse abbreviated month name and day
          timestamp = Time.strptime("#{month_str} #{day_str} #{time_str}", "%b %d %H:%M")
          # Set year to current year (tar doesn't include year)
          timestamp = Time.new(Time.now.year, timestamp.month, timestamp.day, timestamp.hour, timestamp.min)
          file_timestamps[filename] = timestamp
        rescue ArgumentError
          # Skip invalid timestamps
        end
      end
    end
    file_timestamps
  end
  
  private def get_last_backup_time
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return nil unless File.exist?(manifest_file)
    
    last_time = nil
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 2
      
      timestamp_type = parts[0]
      if timestamp_type.match(/^(\d{8}-\d{6})-(full|incr)$/)
        timestamp_str = $1
        begin
          timestamp = Time.strptime(timestamp_str, "%Y%m%d-%H%M%S")
          last_time = timestamp if last_time.nil? || timestamp > last_time
        rescue ArgumentError
          next
        end
      end
    end
    
    last_time
  end
  
  private def update_backup_manifest(backup_name, type, label)
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    FileUtils.mkdir_p(File.dirname(manifest_file))
    
    # Read existing manifest
    existing_lines = []
    if File.exist?(manifest_file)
      existing_lines = File.readlines(manifest_file).map(&:strip)
    end
    
    # Add new backup entry
    timestamp_type = backup_name
    description = label ? "#{label}" : ""
    new_line = "#{timestamp_type} #{description}".strip
    
    # Add to beginning of file (most recent first)
    existing_lines.unshift(new_line)
    
    # Write back to file
    File.write(manifest_file, existing_lines.join("\n") + "\n")
  end
  
  private def update_backup_manifest_remove(backup_name)
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return unless File.exist?(manifest_file)
    
    # Read existing manifest and remove the backup entry
    lines = File.readlines(manifest_file).map(&:strip)
    lines.reject! { |line| line.start_with?("#{backup_name} ") }
    
    # Write back to file
    File.write(manifest_file, lines.join("\n") + "\n")
  end
  
  private def calculate_backup_size(backup_name)
    backup_dir = get_backup_directory
    backup_path = backup_dir/"data"/backup_name
    return 0 unless File.exist?(backup_path)
    
    total_size = 0
    Dir.glob(backup_path/"**/*").each do |file_path|
      total_size += File.size(file_path) if File.file?(file_path)
    end
    total_size
  end

  private def count_backup_files(backup_name)
    backup_dir = get_backup_directory
    backup_path = backup_dir/"data"/backup_name
    return 0 unless File.exist?(backup_path)
    
    Dir.glob(backup_path/"**/*").count { |f| File.file?(f) }
  end
  
  private def restore_from_backup(backup_path)
    # Clear existing content first (except backups)
    clear_repo_content
    
    # Find the most recent full backup before this backup
    full_backup_path = find_full_backup_for_restore(backup_path)
    
    if full_backup_path
      # Restore from full backup first
      restore_files_from_backup(full_backup_path)
      
      # Then apply all incrementals up to the target backup
      apply_incrementals_up_to(backup_path)
    else
      # No full backup found, just restore the files directly
      restore_files_from_backup(backup_path)
    end
  end

  private def clear_repo_content
    # Remove existing content (except backups)
    Dir.glob(@repo.root/"*").each do |item|
      next if File.basename(item) == "backups"
      FileUtils.rm_rf(item)
    end
  end

  private def restore_files_from_backup(backup_path)
    # Check if this is a compressed backup
    tar_gz_path = backup_path/"data.tar.gz"
    if File.exist?(tar_gz_path)
      # Decompress to temporary directory and restore from there
      temp_extract_dir = backup_path/"temp_extract"
      FileUtils.mkdir_p(temp_extract_dir)
      
      begin
        # Extract tar.gz to temporary directory
        system("tar -xzf #{tar_gz_path} -C #{temp_extract_dir}")
        raise "Failed to extract compressed backup" unless $?.success?
        
        # Restore files from extracted directory
        restore_files_from_directory(temp_extract_dir)
      ensure
        # Clean up temporary directory
        FileUtils.rm_rf(temp_extract_dir) if Dir.exist?(temp_extract_dir)
      end
    else
      # Legacy uncompressed backup - restore directly
      restore_files_from_directory(backup_path)
    end
  end
  
  private def restore_files_from_directory(source_dir)
    # Copy all files from source directory to repo
    Dir.glob(source_dir/"**/*").each do |file_path|
      next unless File.file?(file_path)
      
      file_pathname = Pathname.new(file_path)
      source_pathname = Pathname.new(source_dir)
      relative_path = file_pathname.relative_path_from(source_pathname)
      dest_path = @repo.root/relative_path
      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp(file_path, dest_path)
    end
  end

  private def find_full_backup_for_restore(target_backup_path)
    target_name = File.basename(target_backup_path)
    target_timestamp = extract_timestamp_from_backup_name(target_name)
    
    # Find the most recent full backup before the target backup
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return nil unless File.exist?(manifest_file)
    
    latest_full_backup = nil
    latest_full_timestamp = nil
    
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      backup_name = parts[0]
      if backup_name.end_with?('-full')
        # Skip pre-restore backups - they shouldn't be used as base for restore
        next if backup_name.include?('pre-restore')
        
        backup_timestamp = extract_timestamp_from_backup_name(backup_name)
        if backup_timestamp && backup_timestamp < target_timestamp
          if latest_full_timestamp.nil? || backup_timestamp > latest_full_timestamp
            latest_full_backup = backup_name
            latest_full_timestamp = backup_timestamp
          end
        end
      end
    end
    
    return nil unless latest_full_backup
    
    backup_dir = get_backup_directory
    full_backup_path = backup_dir/"data"/latest_full_backup
    File.exist?(full_backup_path) ? full_backup_path : nil
  end

  private def apply_incrementals_up_to(target_backup_path)
    target_name = File.basename(target_backup_path)
    target_timestamp = extract_timestamp_from_backup_name(target_name)
    
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return unless File.exist?(manifest_file)
    
    # Get all incrementals between the full backup and target backup
    incrementals = []
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      backup_name = parts[0]
      if backup_name.end_with?('-incr')
        backup_timestamp = extract_timestamp_from_backup_name(backup_name)
        if backup_timestamp && backup_timestamp <= target_timestamp
          incrementals << backup_name
        end
      end
    end
    
    # Sort incrementals by timestamp and apply them
    incrementals.sort_by { |name| extract_timestamp_from_backup_name(name) }.each do |backup_name|
      backup_dir = get_backup_directory
      incremental_path = backup_dir/"data"/backup_name
      if File.exist?(incremental_path)
        restore_files_from_backup(incremental_path)
      end
    end
  end

  private def extract_timestamp_from_backup_name(backup_name)
    if backup_name.match(/^(\d{8}-\d{6})-(full|incr)$/)
      timestamp_str = $1
      begin
        Time.strptime(timestamp_str, "%Y%m%d-%H%M%S")
      rescue ArgumentError
        nil
      end
    else
      nil
    end
  end


  
  private def cleanup_old_backups
    # Keep backups for 30 days, but always keep the most recent full backup
    cutoff_time = Time.now - (30 * 24 * 60 * 60)
    
    backup_dir = get_backup_directory
    manifest_file = backup_dir/"manifest.txt"
    return unless File.exist?(manifest_file)
    
    # Find the most recent full backup
    most_recent_full_backup = nil
    most_recent_full_timestamp = nil
    
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      backup_name = parts[0]
      if backup_name.end_with?('-full')
        backup_timestamp = extract_timestamp_from_backup_name(backup_name)
        if backup_timestamp && (most_recent_full_timestamp.nil? || backup_timestamp > most_recent_full_timestamp)
          most_recent_full_backup = backup_name
          most_recent_full_timestamp = backup_timestamp
        end
      end
    end
    
    lines_to_keep = []
    lines_to_remove = []
    
    File.readlines(manifest_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(' ', 3)
      next if parts.length < 1
      
      backup_name = parts[0]
      if backup_name.match(/^(\d{8}-\d{6})-(full|incr)$/)
        timestamp_str = $1
        begin
          timestamp = Time.strptime(timestamp_str, "%Y%m%d-%H%M%S")
          
          # Always keep the most recent full backup
          if backup_name == most_recent_full_backup
            lines_to_keep << line
          # Keep all backups newer than cutoff
          elsif timestamp >= cutoff_time
            lines_to_keep << line
          # Keep incrementals that are newer than the most recent full backup
          elsif backup_name.end_with?('-incr') && most_recent_full_timestamp && timestamp > most_recent_full_timestamp
            lines_to_keep << line
          else
            lines_to_remove << backup_name
          end
        rescue ArgumentError
          lines_to_keep << line
        end
      else
        lines_to_keep << line
      end
    end
    
    # Remove old backup directories
    lines_to_remove.each do |backup_name|
      backup_dir = get_backup_directory
      backup_path = backup_dir/"data"/backup_name
      FileUtils.rm_rf(backup_path) if File.exist?(backup_path)
    end
    
    # Update manifest file
    File.write(manifest_file, lines_to_keep.join("\n") + "\n")
  end

end 
