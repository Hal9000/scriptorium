class Scriptorium::Widget
  include Scriptorium::Helpers
  attr_reader :repo, :view, :config, :name, :path

  def initialize(repo, view)
    @repo = repo
    @view = view
    @config = load_config
    @name = self.class.to_s.split("::").last.downcase
    @path = "#{@view.dir}/widgets/#@name"
  end

  def generate
    raise NotImplementedError, "Subclasses must implement the 'generate' method"
  end

  def load_config
    raise NotImplementedError, "Subclasses must implement 'load_config'"
  end

  # Common HTML body wrapper for widgets
  def html_body(css = nil)
    "<html>" +
      (css ? "<head><style>#{css}</style></head>" : "") +
      "<body>" + yield + "</body></html>"
  end

    # Common HTML card structure for widgets like Links
    def html_card(card_title = "Widget Card", tag = "widget", content)
      <<~EOS
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
    end
  
    # A generic container for widget content (for those that don't use cards)
    def html_container(content)
      <<~HTML
        <div class="widget-container">
          #{content}
        </div>
      HTML
    end
  end

  
  ####
  
  
class Scriptorium::Widget::ListWidget < Scriptorium::Widget
  def initialize(repo, view)
    super(repo, view)
    @list = "#{@path}/list.txt"
    @data = load_data
  end

    # Method to load the list data from the list.txt file
  def load_data
    read_file(@list, lines: true, chomp: true).map(&:strip)
  end
end