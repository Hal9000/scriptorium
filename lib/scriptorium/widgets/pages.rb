class Scriptorium::Widget::Pages < Scriptorium::Widget::ListWidget

  Title = "Pages"
  attr_reader :data

  def initialize(repo, view)
    super(repo, view)
    @pages_dir = "#{@view.dir}/pages"
  end

  def load_config
  end

  def generate
    write_main
    write_card
    true
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

  def extract_title_from_html(html_content)
    # Try to extract title from <title> tag first
    if match = html_content.match(/<title[^>]*>(.*?)<\/title>/i)
      return match[1].strip
    end
    
    # Fall back to first <h1> tag
    if match = html_content.match(/<h1[^>]*>(.*?)<\/h1>/i)
      return match[1].strip
    end
    
    # Last resort: use filename
    return "Untitled"
  end

  def page_item(filename, title)
    anchor = %[<a href="javascript:void(0)" onclick="load_main('pages/#{filename}.html')" style="text-decoration: none;">#{title}</a>]
    wrapper = %[<li class="list-group-item">#{anchor}</li>]
    wrapper
  end

  def write_card
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
  end
end 