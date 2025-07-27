#!/usr/bin/env ruby

require 'rouge'

def format_ruby(file, theme = "Github")
  theme = theme.capitalize
  css = Rouge::Themes.const_get(theme).render(scope: '.highlight')
  added = ".highlight { font-family: courier; white-space: pre; background-color: black }"
  css = css + "\n" + added
  puts "Writing #{theme} theme to ruby.css"
  File.write("ruby.css", css)

  formatter = Rouge::Formatters::HTML.new
  lexer = Rouge::Lexers::Ruby.new
  source = File.read(file)
  body = formatter.format(lexer.lex(source))

  html_file = file.sub(/.rb/, ".html")
  puts "Writing output to #{html_file}"
  File.open(html_file, "w") do |output|
    output.puts <<~HTML
      <html>
        <head><link rel="stylesheet" href="ruby.css"></head>
        <body>
          <div class=highlight>
#{body}
          </div>
        </body>
      </html>
    HTML
  end
end

#### Main...

if ARGV.empty?
  puts "Parameters: file.rb [theme]\n              where theme defaults to Github"
  puts "Themes: #{Rouge::Themes.constants.map(&:to_s).join(', ')}"
  abort
end

file, theme = *ARGV

theme = "Github" if theme.nil?

format_ruby(file, theme)

