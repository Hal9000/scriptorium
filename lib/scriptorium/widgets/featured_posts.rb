class Scriptorium::Widget::FeaturedPosts < Scriptorium::Widget::ListWidget
  include Scriptorium::Contract

  Title = "Featured Posts"

  # Invariants
  def define_invariants
    invariant { @lines.is_a?(Array) }
    invariant { Title.is_a?(String) && !Title.empty? }
  end

  def initialize(repo, view)
    assume { repo.is_a?(Scriptorium::Repo) }
    assume { view.is_a?(Scriptorium::View) }
    
    super(repo, view)
    @lines = @data
    
    define_invariants
    verify { @lines == @data }
    check_invariants
  end

  def load_config
    check_invariants
    # No configuration needed for this widget
    check_invariants
  end

  def generate
    check_invariants
    assume { @view.is_a?(Scriptorium::View) }
    
    write_main
    write_card
    result = true
    
    verify { result == true }
    check_invariants
    result
  end

  def widget_title
    check_invariants
    result = Title
    verify { result.is_a?(String) && !result.empty? }
    check_invariants
    result
  end

  def card
    check_invariants
    assume { @view.is_a?(Scriptorium::View) }
    assume { @name.is_a?(String) && !@name.empty? }
    
    file = "#{@view.dir}/widgets/#@name/#@name-card.html"
    result = read_file(file)
    
    verify { result.is_a?(String) }
    check_invariants
    result
  end

  def write_main
    check_invariants
    # Nothing in this case
    check_invariants
  end

  def parse_featured_line(line)
    check_invariants
    assume { line.is_a?(String) }
    
    # Parse line in format: <id> <title>
    # Title is optional, so we need to handle both cases
    parts = line.strip.split(/\s+/, 2)
    if parts.length >= 2
      result = [parts[0], parts[1]]
    else
      result = [parts[0], nil]
    end
    
    verify { result.is_a?(Array) && result.length == 2 }
    check_invariants
    result
  end

  def get_post_title(post_id)
    check_invariants
    assume { post_id.is_a?(String) && !post_id.empty? }
    assume { @repo.is_a?(Scriptorium::Repo) }
    
    # Get the actual post title from metadata
    post = Scriptorium::Post.new(@repo, post_id)
    
    # Check if the post actually exists by looking for the meta file
    if File.exist?(post.meta_file)
      result = post.title || "Untitled Post"
    else
      result = "Error: Post #{post_id} not found"
    end
  rescue => e
    # If post can't be created (invalid ID, etc.), return error message
    result = "Error: Post #{post_id} not found"
  ensure
    verify { result.is_a?(String) && !result.empty? }
    check_invariants
    result
  end

  def featured_post_item(post_id, list_title = nil)
    check_invariants
    assume { post_id.is_a?(String) && !post_id.empty? }
    assume { list_title.nil? || list_title.is_a?(String) }
    
    # Use actual post title from metadata, show error if post doesn't exist
    display_title = get_post_title(post_id)
    
    # Create link to the post (or error message)
    anchor = %[<a href="javascript:void(0)" onclick="load_main('posts/#{post_id}.html')" style="text-decoration: none;">#{display_title}</a>]
    result = %[<li class="list-group-item">#{anchor}</li>]
    
    verify { result.is_a?(String) && result.include?("list-group-item") }
    check_invariants
    result
  end

  def write_card
    check_invariants
    assume { @view.is_a?(Scriptorium::View) }
    assume { @name.is_a?(String) && !@name.empty? }
    assume { @data.is_a?(Array) }
    
    tag = @name
    cardout = "#{@view.dir}/widgets/#@name/#@name-card.html"
    card_title = Title
    content = ""
    
    @data.each do |line|
      next if line.strip.empty?
      
      post_id, list_title = parse_featured_line(line)
      content << featured_post_item(post_id, list_title)
    end
    
    write_file(cardout, html_card(card_title, tag, content))
    check_invariants
  end
end 
