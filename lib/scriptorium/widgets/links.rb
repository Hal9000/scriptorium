class Scriptorium::Widget::Links < Scriptorium::Widget::ListWidget
  include Scriptorium::Contract

  Title = "External links"

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

  def get_list
    check_invariants
    assume { @lines.is_a?(Array) }
    
    result = @lines.map { |line| line.chomp.split(/, */, 2) }
    
    verify { result.is_a?(Array) }
    check_invariants
    result
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

  def link_item(url, title)
    check_invariants
    assume { url.is_a?(String) && !url.empty? }
    assume { title.is_a?(String) && !title.empty? }
    
    anchor = %[<a href="#{url}" target="_blank" style="text-decoration: none;">#{title}</a>]
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
    # url = "../widgets/#@name/#@name-card.html"
    card_title = Title
    content = ""
    @data.each do |line|
      url2, title = line.chomp.split(",")
      content << link_item(url2, title)
    end
    write_file(cardout, html_card(card_title, tag, content))
    check_invariants
  end
end
