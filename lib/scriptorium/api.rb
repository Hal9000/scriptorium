class Scriptorium::API
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  attr_reader :repo, :current_view

  def initialize(testmode: false)
    @testing = testmode
    @repo = nil
  end

  def repo_exists?(path)
    Dir.exist?(path)
  end

  def create_repo(path)
    raise RepoDirAlreadyExists if repo_exists?(path)
    Scriptorium::Repo.create(path)
    @repo = Scriptorium::Repo.open(path)
  end

  def open_repo(path)
    @repo = Scriptorium::Repo.open(path)
  end

  # View management
  def create_view(name, title, subtitle = "", theme: "standard")
    @repo.create_view(name, title, subtitle, theme: theme)
    self
  end

  def current_view
    @repo.current_view
  end

  def apply_theme(theme)
    @repo.view.apply_theme(theme)
  end

  # Post management
  def view(name = nil)
    if name.nil?
      @repo.current_view
    else
      @repo.view(name)
    end
  end

  def views
    @repo.views
  end

  def views_for(post_or_id)
    post = post_or_id.is_a?(Integer) ? @repo.post(post_or_id) : post_or_id
    post.views&.split(/\s+/) || []
  end

  # Post creation with convenience defaults
  def create_post(title, body, views: nil, tags: nil, blurb: nil)
    views ||= @repo.current_view&.name
    raise "No view specified and no current view set" if views.nil?
    
    @repo.create_post(
      title: title,
      body: body,
      views: views,
      tags: tags,
      blurb: blurb
    )
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
    if result
      @repo.generate_post(id)
    end
    
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
    
    if result
      @repo.generate_post(id)
    end
    
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
    if result
      @repo.generate_post(id)
    end
    
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
    if result
      @repo.generate_post(id)
    end
    
    result
  end

  # Theme management
  def themes_available
    themes_dir = @repo.root/:themes
    return [] unless Dir.exist?(themes_dir)
    Dir.children(themes_dir).select { |d| Dir.exist?(themes_dir/d) }
  end

  # Widget management
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

  # File operations
  
  def edit_file(path)
    # Input validation
    raise CannotEditFilePathNil if path.nil?
    raise CannotEditFilePathEmpty if path.to_s.strip.empty?
    
    editor = ENV['EDITOR'] || 'vim'
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
  end

  def generate_all
    # Generate all content for the current view
    # This is currently a simple wrapper around generate_front_page
    # TODO: Later implement "makefile" type checking to avoid unnecessary work
    
    view ||= @repo.current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    generate_front_page(view)
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
    write_file(source_file, *lines)
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

  # Utility methods

  # Convenience workflow methods

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
