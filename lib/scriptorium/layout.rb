class Scriptorium::Layout
  attr_reader :containers, :params

  def initialize(text)
    @containers = []
    @params = {}

    text.each_line do |line|
      line.strip!
      next if line.empty? || line.start_with?("#")

      name, width = line.split(/\s+/, 2)
      @containers << name
      @params["#{name}_width"] = width if width
    end
  end

  def html
    out = []
    out << "<div class='page'>"

    # Add header if present
    out << "  <div class='header'><!-- header --></div>" if @containers.include?("header")

    if @containers.any? {|r| %w[left main right].include?(r) }
      out << "  <div class='main-row'>"
      out << "    <div class='left' style='width:#{@params['left_width'] || '15%'}'><!-- left --></div>" if @containers.include?("left")
      out << "    <div class='main' style='flex-grow: 1;'><!-- main --></div>" if @containers.include?("main")
      out << "    <div class='right' style='width:#{@params['right_width'] || '15%'}'><!-- right --></div>" if @containers.include?("right")
      out << "  </div>"
    end

    # Add footer if present
    out << "  <div class='footer' style='margin-top: auto;'><!-- footer --></div>" if @containers.include?("footer")

    out << "</div>"
    out.join("\n")
  end

  def css
    <<~CSS
      .page {
        display: flex;
        flex-direction: column;
        width: 100%;
        margin: 0 auto;
      }

      .header, .footer {
        width: 100%;
        padding: 1em;
        background-color: #eee;
        text-align: center;
      }

      .main-row {
        display: flex;
        flex-direction: row;
      }

      .left, .right {
        padding: 1em;
        background-color: #f0f0f0;
      }

      .main {
        flex-grow: 1;
        padding: 1em;
        background-color: #fff;
      }
    CSS
  end
end

# Example usage:


