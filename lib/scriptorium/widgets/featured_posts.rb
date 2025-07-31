class Scriptorium::Widget::FeaturedPosts < Scriptorium::Widget::ListWidget

  Title = "Featured Posts"

  def initialize(repo, view)
    super(repo, view)
    @lines = @data
  end

  def load_config
  end

  def generate
    write_main
    write_card
  end

  def widget_title
    Title
  end

  def card
    file = "#{@view.dir}/widgets/#@name/#@name-card.html"
    read_file(file)
  end

  def write_main
    # Nothing in this case
  end

  def parse_featured_line(line)
    # Parse line in format: <id> <title>
    # Title is optional, so we need to handle both cases
    parts = line.strip.split(/\s+/, 2)
    if parts.length >= 2
      [parts[0], parts[1]]
    else
      [parts[0], nil]
    end
  end

  def get_post_title(post_id)
    # Get the actual post title from metadata
    post = Scriptorium::Post.new(@repo, post_id)
    
    # Check if the post actually exists by looking for the meta file
    if File.exist?(post.meta_file)
      post.title || "Untitled Post"
    else
      "Error: Post #{post_id} not found"
    end
  rescue => e
    # If post can't be created (invalid ID, etc.), return error message
    "Error: Post #{post_id} not found"
  end

  def featured_post_item(post_id, list_title = nil)
    # Use actual post title from metadata, show error if post doesn't exist
    display_title = get_post_title(post_id)
    
    # Create link to the post (or error message)
    anchor = %[<a href="javascript:void(0)" onclick="load_main('posts/#{post_id}.html')" style="text-decoration: none;">#{display_title}</a>]
    wrapper = %[<li class="list-group-item">#{anchor}</li>]
    wrapper
  end

  def write_card
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
  end
end 