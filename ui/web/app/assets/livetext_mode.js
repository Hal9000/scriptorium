// Custom LiveText syntax highlighting mode for CodeMirror
CodeMirror.defineMode("livetext", function() {
  return {
    startState: function() {
      return {
        inRaw: false,
        inCodeBody: false,
        codeLanguage: null,
        inBracket: false,
        bracketDepth: 0
      };
    },
    
    token: function(stream, state) {
      // Skip whitespace
      if (stream.eatSpace()) return null;
      
      // Raw blocks override everything else
      if (state.inRaw) {
        if (stream.match(/^__RAW__/) || stream.match(/^\.end$/)) {
          state.inRaw = false;
          return "keyword";
        }
        stream.skipToEnd();
        return "comment"; // Plain text in raw blocks
      }
      
      // Check for .raw command
      if (stream.match(/^\.raw$/)) {
        state.inRaw = true;
        return "keyword";
      }
      
      // Check for .comment command
      if (stream.match(/^\.comment$/)) {
        state.inRaw = true; // Use same state as raw for plain text
        return "keyword";
      }
      
      // Code body blocks
      if (state.inCodeBody) {
        if (stream.match(/^\.end$/)) {
          state.inCodeBody = false;
          state.codeLanguage = null;
          return "keyword";
        }
        
        // Use appropriate language highlighting
        if (state.codeLanguage === "ruby") {
          // Ruby syntax highlighting
          if (stream.match(/^#/)) {
            stream.skipToEnd();
            return "comment";
          }
          if (stream.match(/^def\b/)) return "def";
          if (stream.match(/^end\b/)) return "keyword";
          if (stream.match(/^class\b/)) return "def";
          if (stream.match(/^module\b/)) return "def";
          if (stream.match(/^require\b/)) return "keyword";
          if (stream.match(/^puts\b/)) return "keyword";
          if (stream.match(/^[A-Z][a-zA-Z0-9_]*/)) return "variable-2"; // Constants
          if (stream.match(/^[a-z_][a-zA-Z0-9_]*/)) return "variable"; // Variables
          if (stream.match(/^[0-9]+/)) return "number";
          if (stream.match(/^["']/)) {
            stream.skipTo(/["']/);
            return "string";
          }
        } else if (state.codeLanguage === "elixir") {
          // Elixir syntax highlighting
          if (stream.match(/^#/)) {
            stream.skipToEnd();
            return "comment";
          }
          if (stream.match(/^def\b/)) return "def";
          if (stream.match(/^end\b/)) return "keyword";
          if (stream.match(/^defmodule\b/)) return "def";
          if (stream.match(/^defp\b/)) return "def";
          if (stream.match(/^IO\.puts\b/)) return "keyword";
          if (stream.match(/^[A-Z][a-zA-Z0-9_]*/)) return "variable-2"; // Modules
          if (stream.match(/^[a-z_][a-zA-Z0-9_]*/)) return "keyword"; // Functions
          if (stream.match(/^[0-9]+/)) return "number";
          if (stream.match(/^["']/)) {
            stream.skipTo(/["']/);
            return "string";
          }
        } else if (state.codeLanguage === "bash") {
          // Bash syntax highlighting
          if (stream.match(/^#/)) {
            stream.skipToEnd();
            return "comment";
          }
          if (stream.match(/^if\b/)) return "keyword";
          if (stream.match(/^then\b/)) return "keyword";
          if (stream.match(/^fi\b/)) return "keyword";
          if (stream.match(/^for\b/)) return "keyword";
          if (stream.match(/^do\b/)) return "keyword";
          if (stream.match(/^done\b/)) return "keyword";
          if (stream.match(/^\$[A-Z_]+/)) return "variable"; // Environment variables
          if (stream.match(/^[0-9]+/)) return "number";
          if (stream.match(/^["']/)) {
            stream.skipTo(/["']/);
            return "string";
          }
        }
        
        stream.next();
        return null;
      }
      
      // Check for code body commands
      if (stream.match(/^\.(def|func)$/)) {
        state.inCodeBody = true;
        state.codeLanguage = "ruby";
        return "keyword";
      }
      
      let codeMatch = stream.match(/^\.code\s+(ruby|elixir|bash)/);
      if (codeMatch) {
        state.inCodeBody = true;
        state.codeLanguage = codeMatch[1];
        return "keyword";
      }
      
      // One-line comments (. comment)
      if (stream.match(/^\.\s/)) {
        stream.skipToEnd();
        return "comment";
      }
      
      // Dot commands (.command or $.command)
      if (stream.match(/^\.\w+/)) {
        return "keyword";
      }
      if (stream.match(/^\s+\$\.[\w.]+/)) {
        return "keyword";
      }
      
      // Variables ($foo, $foo.bar) - stop at invalid characters
      if (stream.match(/^\$/)) {
        let name = "";
        let ch = stream.next();
        if (ch && /[a-zA-Z]/.test(ch)) {
          name += ch;
          while (stream.peek() && /[\w.]/.test(stream.peek())) {
            ch = stream.next();
            name += ch;
          }
          // Check if next character is invalid for a name
          if (stream.peek() && !/[\w.]/.test(stream.peek())) {
            return "variable";
          }
        }
        return "variable";
      }
      
      // Functions ($$foo, $$foo:param, $$foo[param])
      if (stream.match(/^\$\$/)) {
        let name = "";
        let ch = stream.next();
        if (ch && /[a-zA-Z]/.test(ch)) {
          name += ch;
          while (stream.peek() && /[\w.]/.test(stream.peek())) {
            ch = stream.next();
            name += ch;
          }
          // Check for colon parameter
          if (stream.peek() === ":") {
            stream.next();
            stream.skipToEnd();
          }
          return "function";
        }
        return "function";
      }
      
      // Bracketed content [content]
      if (stream.match(/^\[/)) {
        state.inBracket = true;
        state.bracketDepth = 1;
        return "bracket";
      }
      
      if (state.inBracket) {
        if (stream.match(/^\]/)) {
          state.inBracket = false;
          state.bracketDepth = 0;
          return "bracket";
        }
        // Continue reading bracket content
        stream.next();
        return "string";
      }
      
      // Bracketed formatting: *[text] _[text] `[text] ~[text]
      if (stream.match(/^(\*|_|`|~)\[/)) {
        state.inBracket = true;
        state.bracketDepth = 1;
        return "strong"; // All bracketed content gets same treatment for now
      }
      
      // Markers (* _ ` ~) - single and doubled
      // Note: LiveText markers only initiate, never terminate
      if (stream.match(/^\*\*/)) {
        // Doubled marker - read until space, comma, or period
        stream.eatWhile(/[^\s,.]/);
        return "strong";
      }
      if (stream.match(/^__/)) {
        stream.eatWhile(/[^\s,.]/);
        return "em";
      }
      if (stream.match(/^``/)) {
        stream.eatWhile(/[^\s,.]/);
        return "string-2";
      }
      if (stream.match(/^~~/)) {
        stream.eatWhile(/[^\s,.]/);
        return "strikethrough";
      }
      
      // Single markers
      if (stream.match(/^\*/)) {
        stream.eatWhile(/[^\s]/);
        return "strong";
      }
      if (stream.match(/^_/)) {
        stream.eatWhile(/[^\s]/);
        return "em";
      }
      if (stream.match(/^`/)) {
        stream.eatWhile(/[^\s]/);
        return "string-2";
      }
      if (stream.match(/^~/)) {
        stream.eatWhile(/[^\s]/);
        return "strikethrough";
      }
      
      // Continue reading
      stream.next();
      return null;
    }
  };
});
