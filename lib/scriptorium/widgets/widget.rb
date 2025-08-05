class Scriptorium::Widget
  include Scriptorium::Helpers
  include Scriptorium::Contract
  attr_reader :repo, :view, :config, :name, :path

  # Invariants
  def define_invariants
    invariant { @repo.is_a?(Scriptorium::Repo) }
    invariant { @view.is_a?(Scriptorium::View) }
    invariant { @name.is_a?(String) && !@name.empty? }
    invariant { @path.is_a?(String) && !@path.empty? }
  end

  def initialize(repo, view)
    assume { repo.is_a?(Scriptorium::Repo) }
    assume { view.is_a?(Scriptorium::View) }
    
    @repo = repo
    @view = view
    @config = load_config
    @name = self.class.to_s.split("::").last.downcase
    @path = "#{@view.dir}/widgets/#@name"
    
    define_invariants
    verify { @repo == repo }
    verify { @view == view }
    check_invariants
  end

  def generate
    raise NotImplementedError, "Subclasses must implement the 'generate' method"
  end

  def load_config
    raise NotImplementedError, "Subclasses must implement 'load_config'"
  end

  # Common HTML body wrapper for widgets
  def html_body(css = nil)
    check_invariants
    assume { css.nil? || css.is_a?(String) }
    
    result = "<html>" +
      (css ? "<head><style>#{css}</style></head>" : "") +
      "<body>" + yield + "</body></html>"
    
    verify { result.is_a?(String) && result.include?("<html>") }
    check_invariants
    result
  end

  # Common HTML card structure for widgets like Links
  def html_card(card_title = "Widget Card", tag = "widget", content)
    check_invariants
    assume { card_title.is_a?(String) }
    assume { tag.is_a?(String) }
    assume { content.is_a?(String) }
    
    result = <<~EOS
      <div class="card mb-3">
        <div class="card-body">
          <h5 class="card-title">
            <button type="button" class="btn btn-primary" data-bs-toggle="collapse" data-bs-target="##{tag}">+</button>
            <a href="javascript:void(0)" onclick="javascript:load_main('#{tag}-main.html')" style="text-decoration: none; color: black">#{card_title}</a>
          </h5>
          <div class="collapse" id="#{tag}">
            #{content}
          </div>
        </div>
      </div>
    EOS
    
    verify { result.is_a?(String) && result.include?("card") }
    check_invariants
    result
  end
  
  # A generic container for widget content (for those that don't use cards)
  def html_container(content)
    check_invariants
    assume { content.is_a?(String) }
    
    result = <<~HTML
      <div class="widget-container">
        #{content}
      </div>
    HTML
    
    verify { result.is_a?(String) && result.include?("widget-container") }
    check_invariants
    result
  end
  end

  
  ####
  
  
class Scriptorium::Widget::ListWidget < Scriptorium::Widget
  include Scriptorium::Contract

  # Invariants
  def define_invariants
    invariant { @list.is_a?(String) && !@list.empty? }
    invariant { @data.is_a?(Array) }
  end

  def initialize(repo, view)
    assume { repo.is_a?(Scriptorium::Repo) }
    assume { view.is_a?(Scriptorium::View) }
    
    super(repo, view)
    @list = "#{@path}/list.txt"
    @data = load_data
    
    define_invariants
    verify { @list.include?("list.txt") }
    verify { @data.is_a?(Array) }
    check_invariants
  end

  # Method to load the list data from the list.txt file
  def load_data
    check_invariants
    assume { @list.is_a?(String) && !@list.empty? }
    
    result = read_file(@list, lines: true, chomp: true).map(&:strip)
    
    verify { result.is_a?(Array) }
    check_invariants
    result
  end
end