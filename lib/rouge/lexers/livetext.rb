# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class LiveText < RegexLexer
      title "LiveText"
      desc "LiveText markup language (.lt3 files)"
      tag 'livetext'
      aliases 'lt3'
      filenames '*.lt3', '*.livetext'
      mimetypes 'text/x-livetext'

      # Define token types
      state :root do
        # Comments (## lines) - must come first
        rule %r/##.*$/, Comment::Single
        
        # Dot commands (start with .) - must come before general text
        rule %r/\.([a-zA-Z_][a-zA-Z0-9_]*)\b/, Name::Function
        
        # Code block markers
        rule %r/\.end\b/, Keyword::Reserved
        
        # Variables ($VAR, @blog.view, Livetext::Vars)
        rule %r/\$([A-Z][A-Z0-9_]*)\b/, Name::Variable::Global
        rule %r/@([a-zA-Z_][a-zA-Z0-9_.]*)\b/, Name::Variable::Instance
        rule %r/Livetext::Vars\[:([a-zA-Z_][a-zA-Z0-9_]*)\]/, Name::Variable::Global
        
        # Functions ($$funcname[param])
        rule %r/\$\$([a-zA-Z_][a-zA-Z0-9_]*)\[/, Name::Function, :function_param
        
        # Special syntax (:views, :posts, etc.)
        rule %r/:([a-zA-Z_][a-zA-Z0-9_]*)\b/, Name::Constant
        
        # Path separators (custom PathSep operator)
        rule %r/([a-zA-Z0-9_\/]+)\/([a-zA-Z0-9_\/]+)/, Literal::String::Other
        
        # Strings (quoted text)
        rule %r/"([^"]*)"/, Literal::String::Double
        rule %r/'([^']*)'/, Literal::String::Single
        
        # Numbers
        rule %r/\b(\d+)\b/, Literal::Number::Integer
        rule %r/\b(\d+\.\d+)\b/, Literal::Number::Float
        
        # HTML-like tags in strings
        rule %r/&lt;/, Literal::String::Other
        rule %r/&gt;/, Literal::String::Other
        
        # Operators
        rule %r/[=+\-*\/<>!&|]/, Operator
        
        # Punctuation
        rule %r/[\[\]{}();,.]/, Punctuation
        
        # Whitespace
        rule %r/\s+/, Text::Whitespace
        
        # Everything else as text - must come last
        rule %r/.+/, Text
      end

      # Function parameter state
      state :function_param do
        rule %r/\]/, Name::Function, :pop!
        rule %r/\[/, Punctuation
        rule %r/"([^"]*)"/, Literal::String::Double
        rule %r/'([^']*)'/, Literal::String::Single
        rule %r/[^\]]+/, Text
      end
    end
  end
end
