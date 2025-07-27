class Scriptorium::API
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  attr_reader :repo, :current_view

  def initialize(path_or_testing = false)
    # Handle backward compatibility: boolean true means testing mode
    if path_or_testing == true
      path_or_testing = "test/scriptorium-TEST"
    elsif path_or_testing == false
      path_or_testing = nil  # Use default ~/.scriptorium
    end
    
    @testing = path_or_testing
    
    # Determine the repository root path
    if path_or_testing
      @repo_root = path_or_testing
    else
      home = ENV['HOME']
      @repo_root = "#{home}/.scriptorium"
    end
    
    # Check if repository exists and load or create accordingly
    if Dir.exist?(@repo_root)
      @repo = Scriptorium::Repo.open(@repo_root)
    else
      @repo = Scriptorium::Repo.create(path_or_testing)
    end
    
    @current_view = nil
  end

  # View management
  def create_view(name, title, subtitle = "", theme: "standard")
    @current_view = @repo.create_view(name, title, subtitle, theme: theme)
  end

  def create_view_and_use(name, title, subtitle = "", theme: "standard")
    create_view(name, title, subtitle, theme: theme)
    use_view(name)
    self
  end

  def view(name = nil)
    if name
      @current_view = @repo.lookup_view(name)
    else
      @current_view
    end
  end

  # Alias for clarity
  alias_method :use_view, :view

  # Post creation with convenience defaults
  def create_post(title, body, views: nil, tags: nil)
    views ||= @current_view&.name
    raise "No view specified and no current view set" if views.nil?
    
    @repo.create_post(
      title: title,
      body: body,
      views: views,
      tags: tags
    )
  end

  # Draft management
  def draft(title: nil, body: nil, views: nil, tags: nil, blurb: nil)
    views ||= @current_view&.name
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
    view ||= @current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    @repo.generate_front_page(view)
  end

  def generate_post_index(view = nil)
    view ||= @current_view&.name
    raise "No view specified and no current view set" if view.nil?
    
    @repo.generate_post_index(view)
  end

  # Post retrieval
  def posts(view = nil)
    view ||= @current_view&.name
    @repo.all_posts(view)
  end

  def post(id)
    @repo.post(id)
  end

  # Utility methods
  def tree(file = nil)
    @repo.tree(file)
  end

  def destroy
    raise "Cannot destroy non-testing repository" unless @testing
    Scriptorium::Repo.destroy
  end

  # Convenience workflow methods
  def create_view(name, title, subtitle = "", theme: "standard")
    @current_view = @repo.create_view(name, title, subtitle, theme: theme)
    self
  end

  def quick_post(title, body, tags: nil, blurb: nil)
    post(title, body, tags: tags, blurb: blurb)
    generate_front_page
    self
  end

  # Delegate common repo methods
  def method_missing(method, *args, &block)
    if @repo.respond_to?(method)
      @repo.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    @repo.respond_to?(method, include_private) || super
  end
end 