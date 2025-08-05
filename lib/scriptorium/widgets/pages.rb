class Scriptorium::Widget::Pages < Scriptorium::Widget::ListWidget
  include Scriptorium::Contract

  Title = "Pages"
  attr_reader :data

  # Invariants
  def define_invariants
    invariant { @pages_dir.is_a?(String) && !@pages_dir.empty? }
    invariant { @data.is_a?(Array) }
    invariant { Title.is_a?(String) && !Title.empty? }
  end

  def initialize(repo, view)
    assume { repo.is_a?(Scriptorium::Repo) }
    assume { view.is_a?(Scriptorium::View) }
    
    super(repo, view)
    @pages_dir = "#{@view.dir}/pages"
    
    define_invariants
    verify { @pages_dir.include?("pages") }
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

  def extract_title_from_html(html_content)
    check_invariants
    assume { html_content.is_a?(String) }
    
    # Try to extract title from <title> tag first
    if match = html_content.match(/<title[^>]*>(.*?)<\/title>/i)
      result = match[1].strip
    elsif match = html_content.match(/<h1[^>]*>(.*?)<\/h1>/i)
      # Fall back to first <h1> tag
      result = match[1].strip
    else
      # Last resort: use filename
      result = "Untitled"
    end
    
    verify { result.is_a?(String) && !result.empty? }
    check_invariants
    result
  end

  def page_item(filename, title)
    check_invariants
    assume { filename.is_a?(String) && !filename.empty? }
    assume { title.is_a?(String) && !title.empty? }
    
    anchor = %[<a href="javascript:void(0)" onclick="load_main('pages/#{filename}.html')" style="text-decoration: none;">#{title}</a>]
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
    assume { @pages_dir.is_a?(String) && !@pages_dir.empty? }
    
    tag = @name
    cardout = "#{@view.dir}/widgets/#@name/#@name-card.html"
    card_title = Title
    content = ""
    
    @data.each do |filename|
      html_file = "#{@pages_dir}/#{filename}.html"
      
      if File.exist?(html_file)
        html_content = read_file(html_file)
        title = extract_title_from_html(html_content)
        content << page_item(filename, title)
      else
        # Page doesn't exist, skip it
        next
      end
    end
    
    write_file(cardout, html_card(card_title, tag, content))
    check_invariants
  end
end 