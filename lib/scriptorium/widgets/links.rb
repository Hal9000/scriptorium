class Scriptorium::Widget::Links < Scriptorium::Widget::ListWidget

  Title = "External links"

  def initialize(repo, view)
    super(repo, view)
    @lines = @data
  end

  def get_list
    @lines.map { |line| line.chomp.split(/, */, 2) }
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

  def link_item(url, title)
    anchor = %[<a href="#{url}" target="_blank" style="text-decoration: none;">#{title}</a>]
    wrapper = %[<li class="list-group-item">#{anchor}</li>]
    wrapper
  end

  def write_card
    tag = @name
    cardout = "#{@view.dir}/widgets/#@name/#@name-card.html"
    url = "../widgets/#@name/#@name-card.html"
    card_title = Title
    content = ""
    @data.each do |line|
      url2, title = line.chomp.split(",")
      content << link_item(url2, title)
    end
    write_file(cardout, html_card(card_title, tag, content))
  end
end