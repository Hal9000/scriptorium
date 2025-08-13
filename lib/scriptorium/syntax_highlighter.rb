require 'rouge'

module Scriptorium
  class SyntaxHighlighter
    # Default theme - can be customized
    DEFAULT_THEME = {
      'keyword' => 'color: #07a; font-weight: bold;',
      'string' => 'color: #690;',
      'comment' => 'color: #708090; font-style: italic;',
      'function' => 'color: #dd4a68;',
      'number' => 'color: #905;',
      'symbol' => 'color: #905;',
      'operator' => 'color: #9a6e3a;',
      'class-name' => 'color: #dd4a68;',
      'regex' => 'color: #e90;',
      'variable' => 'color: #e90;',
      'interpolation' => 'color: #690;',  # same as string
      'error' => 'color: #d73a49; font-weight: bold;',
      'whitespace' => 'color: transparent;',
      'other' => 'color: #24292e;'
    }

    def initialize(theme = nil)
      @theme = theme || DEFAULT_THEME
      @formatter = Rouge::Formatters::HTML.new
    end

    # Highlight code with language detection
    def highlight(code, language = nil)
      return escape_html(code) if language.nil? || language.empty?
      
      language = language.downcase.strip
      
      # Map common language names to Rouge lexers
      lexer_name = map_language(language)
      return escape_html(code) unless lexer_name
      
      begin
        lexer = Rouge::Lexer.find(lexer_name)
        puts "DEBUG: Found lexer: #{lexer.class}"
        highlighted = @formatter.format(lexer.lex(code))
        puts "DEBUG: Rouge output length: #{highlighted.length}"
        puts "DEBUG: Raw Rouge output (first 500 chars): #{highlighted[0..500]}"
        puts "DEBUG: HTML contains <div>: #{highlighted.include?('<div')}"
        puts "DEBUG: HTML contains <br>: #{highlighted.include?('<br')}"
        puts "DEBUG: HTML contains \\n: #{highlighted.include?("\n")}"
        
        # Massage the output to use our CSS classes
        massage_output(highlighted, language)
      rescue => e
        # Fallback to escaped HTML if highlighting fails
        puts "DEBUG: Rouge highlighting failed for #{language}: #{e.message}"
        puts "DEBUG: Backtrace: #{e.backtrace.first(3).join(', ')}"
        escape_html(code)
      end
    end

    # Generate CSS for the theme
    def generate_css
      css = []
      css << "/* Syntax highlighting styles */"
      css << "pre {"
      css << "  background: #f5f5f5;"
      css << "  padding: 15px;"
      css << "  border-radius: 5px;"
      css << "  overflow-x: auto;"
      css << "}"
      css << ""
      css << "pre code {"
      css << "  font-family: 'Consolas', 'Monaco', 'Andale Mono', monospace;"
      css << "  font-size: 14px;"
      css << "}"
      css << ""
      css << "/* Override Bootstrap height constraints for syntax highlighting */"
      css << "pre code[class*=\"language-\"] {"
      css << "  height: auto !important;"
      css << "  max-height: none !important;"
      css << "  min-height: auto !important;"
      css << "  overflow: visible !important;"
      css << "}"
      css << ""
      css << "pre:has(code[class*=\"language-\"]) {"
      css << "  height: auto !important;"
      css << "  max-height: none !important;"
      css << "  min-height: auto !important;"
      css << "  overflow: visible !important;"
      css << "}"
      
      @theme.each do |token, style|
        css << ".token.#{token} { #{style} }"
      end
      
      css.join("\n")
    end

    private

    # Map common language names to Rouge lexer names
    def map_language(language)
      language_map = {
        'ruby' => 'ruby',
        'rb' => 'ruby',
        'javascript' => 'javascript',
        'js' => 'javascript',
        'elixir' => 'elixir',
        'python' => 'python',
        'py' => 'python',
        'html' => 'html',
        'css' => 'css',
        'sql' => 'sql',
        'bash' => 'bash',
        'shell' => 'bash',
        'sh' => 'bash',
        'yaml' => 'yaml',
        'yml' => 'yaml',
        'json' => 'json',
        'xml' => 'xml',
        'markdown' => 'markdown',
        'md' => 'markdown',
        'go' => 'go',
        'rust' => 'rust',
        'java' => 'java',
        'cpp' => 'cpp',
        'c' => 'c',
        'csharp' => 'csharp',
        'cs' => 'csharp',
        'php' => 'php',
        'r' => 'r',
        'scala' => 'scala',
        'swift' => 'swift',
        'kotlin' => 'kotlin',
        'dart' => 'dart'
      }
      
      language_map[language]
    end

    # Massage Rouge output to use our CSS classes
    def massage_output(html, language)
      # Rouge outputs classes like 'k' for keyword, 's' for string, etc.
      # We want to map these to our semantic class names
      class_mapping = {
        'k' => 'keyword',      # keyword
        's' => 'string',       # string
        'c' => 'comment',      # comment
        'f' => 'function',     # function
        'n' => 'number',       # number
        'o' => 'operator',     # operator
        'c1' => 'comment',     # comment
        's1' => 'string',      # string
        's2' => 'string',      # string
        'nb' => 'function',    # function name
        'na' => 'function',    # function argument
        'nc' => 'class-name',  # class name
        'nd' => 'function',    # function definition
        'ne' => 'variable',    # variable
        'nf' => 'function',    # function
        'ni' => 'variable',    # variable
        'nl' => 'number',      # number literal
        'nn' => 'class-name',  # class name
        'no' => 'constant',    # constant
        'nt' => 'tag',         # tag name
        'nv' => 'variable',    # variable
        'ow' => 'operator',    # operator
        'p' => 'punctuation',  # punctuation
        'pi' => 'doctype',     # doctype
        # JavaScript-specific mappings
        'kd' => 'keyword',     # keyword declaration (function, var, etc.)
        'nx' => 'variable',    # variable name
        'dl' => 'string',      # string delimiter
        'cm' => 'comment',     # comment
        'cp' => 'comment',     # comment
        'cs' => 'comment',     # comment
        'ge' => 'comment',     # comment
        'gh' => 'comment',     # comment
        'gp' => 'comment',     # comment
        'gs' => 'comment',     # comment
        'gu' => 'comment',     # comment
        'il' => 'number',      # number literal
        'm' => 'number',       # number
        'mf' => 'number',      # number
        'mh' => 'number',      # number
        'mi' => 'number',      # number
        'mo' => 'number',      # number
        'sb' => 'string',      # string
        'sc' => 'string',      # string
        'sd' => 'string',      # string
        'se' => 'string',      # string
        'sh' => 'string',      # string
        'si' => 'string',      # string
        'sr' => 'string',      # string
        'ss' => 'string',      # string
        'vi' => 'variable',    # instance variable (@name)
        'vc' => 'variable',    # class variable (@@name)
        'vg' => 'variable',    # global variable ($name)
        'bp' => 'variable',    # built-in pseudo
        'err' => 'error',      # error
        'w' => 'whitespace',   # whitespace
        'x' => 'other',        # other
        'kc' => 'constant'     # constant (true, false, null)
      }
      
      # Replace Rouge's short class names with our semantic names
      class_mapping.each do |rouge_class, semantic_class|
        html.gsub!(/class="#{rouge_class}"/, "class=\"token #{semantic_class}\"")
        html.gsub!(/class='#{rouge_class}'/, "class='token #{semantic_class}'")
      end
      
      # Add 'token' class to all spans that don't have it
      html.gsub!(/<span class="([^"]*?)">/, '<span class="token \1">')
      html.gsub!(/<span class='([^']*?)'>/, "<span class='token \\1'>")
      
            # Clean up duplicate 'token token' classes
      html.gsub!(/class="token token ([^"]*)"/, 'class="token \1"')
      html.gsub!(/class='token token ([^']*)'/, "class='token \\1'")
      
      html
    end



    # Simple HTML escaping
    def escape_html(text)
      text.to_s
        .gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
        .gsub('"', '&quot;')
        .gsub("'", '&#39;')
    end


  end
end
