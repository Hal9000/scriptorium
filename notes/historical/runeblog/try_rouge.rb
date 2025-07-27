require 'rouge'

lines = File.readlines(__FILE__)
source = lines.join

formatter = Rouge::Formatters::HTML.new
lexer = Rouge::Lexers::Ruby.new

css = Rouge::Themes::Github.render(scope: '.highlight')
added = ".highlight { font-family: courier; white-space: pre }"
File.write("github.css", css + added)

body = formatter.format(lexer.lex(source))

html_file = "output.html"
File.open(html_file, "w") do |output|
  output.puts <<~HTML
    <html>
      <head><link rel="stylesheet" href="github.css"></head>
      <body>
      <div class="highlight">
#{body}
      </div>
      </body>
    </html>
  HTML
end
