" Vim syntax file for LiveText
" Language: LiveText
" Maintainer: Scriptorium Project
" Latest Revision: 2025-01-01

if exists("b:current_syntax")
  finish
endif

" LiveText syntax highlighting
" Based on the custom CodeMirror mode implementation

" Comments - one-line comments starting with ". "
syn match livetextComment /^\.\s.*$/

" Dot commands - commands starting with "." at beginning of line
syn match livetextDotCommand /^\.\w\+/ contains=livetextDotCommandName
syn match livetextDotCommandName /^\.\zs\w\+/ contained

" Indented dot commands - commands starting with "$." (indented)
syn match livetextIndentedCommand /^\s*\$\.\w\+/ contains=livetextIndentedCommandName
syn match livetextIndentedCommandName /\$\.\zs\w\+/ contained

" Block structure keywords
syn keyword livetextBlockEnd .end contained
syn keyword livetextRawEnd __RAW__ contained

" Variables - start with $, followed by letter, then letters/digits/underscores
" Period is legal as separator, but not at beginning/end or consecutive
syn match livetextVariable /\$[a-zA-Z][a-zA-Z0-9_]*\(\.[a-zA-Z][a-zA-Z0-9_]*\)*/ contains=livetextVariableName,livetextVariableSeparator
syn match livetextVariableName /\$[a-zA-Z][a-zA-Z0-9_]*/ contained
syn match livetextVariableSeparator /\./ contained

" Functions - start with $$, followed by letter, then letters/digits/underscores
syn match livetextFunction /\$\$[a-zA-Z][a-zA-Z0-9_]*\(\.[a-zA-Z][a-zA-Z0-9_]*\)*/ contains=livetextFunctionName,livetextFunctionSeparator
syn match livetextFunctionName /\$\$[a-zA-Z][a-zA-Z0-9_]*/ contained
syn match livetextFunctionSeparator /\./ contained

" Function parameters - colon-separated or bracket-enclosed
syn match livetextFunctionParam /:\S\+/ contained
syn match livetextFunctionBracket /\[[^\]]*\]/ contained

" Markers - bold, italic, code, strikethrough
" Single markers (space-terminated)
syn match livetextBold /\*[a-zA-Z0-9_][a-zA-Z0-9_]*\s/ contains=livetextBoldText
syn match livetextBoldText /\*\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextItalic /_[a-zA-Z0-9_][a-zA-Z0-9_]*\s/ contains=livetextItalicText
syn match livetextItalicText /_\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextCode /`[a-zA-Z0-9_][a-zA-Z0-9_]*\s/ contains=livetextCodeText
syn match livetextCodeText /`\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextStrikethrough /~[a-zA-Z0-9_][a-zA-Z0-9_]*\s/ contains=livetextStrikethroughText
syn match livetextStrikethroughText /~\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

" Double markers (comma/period-terminated)
syn match livetextBoldDouble /\*\*[a-zA-Z0-9_][a-zA-Z0-9_]*[,.]/ contains=livetextBoldDoubleText
syn match livetextBoldDoubleText /\*\*\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextItalicDouble /__[a-zA-Z0-9_][a-zA-Z0-9_]*[,.]/ contains=livetextItalicDoubleText
syn match livetextItalicDoubleText /__\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextCodeDouble /``[a-zA-Z0-9_][a-zA-Z0-9_]*[,.]/ contains=livetextCodeDoubleText
syn match livetextCodeDoubleText /``\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

syn match livetextStrikethroughDouble /~~[a-zA-Z0-9_][a-zA-Z0-9_]*[,.]/ contains=livetextStrikethroughDoubleText
syn match livetextStrikethroughDoubleText /~~\zs[a-zA-Z0-9_][a-zA-Z0-9_]*/ contained

" Bracketed formatting - multi-word formatting
syn match livetextBracketedBold /\*\[[^\]]*\]/ contains=livetextBracketedBoldText
syn match livetextBracketedBoldText /\*\[\zs[^\]]*\ze\]/ contained

syn match livetextBracketedItalic /_\[[^\]]*\]/ contains=livetextBracketedItalicText
syn match livetextBracketedItalicText /_\[\zs[^\]]*\ze\]/ contained

syn match livetextBracketedCode /`\[[^\]]*\]/ contains=livetextBracketedCodeText
syn match livetextBracketedCodeText /`\[\zs[^\]]*\ze\]/ contained

syn match livetextBracketedStrikethrough /~\[[^\]]*\]/ contains=livetextBracketedStrikethroughText
syn match livetextBracketedStrikethroughText /~\[\zs[^\]]*\ze\]/ contained

" Block structures
" .raw ... __RAW__ (plain text)
syn region livetextRawBlock start=/^\.raw\s*$/ end=/^__RAW__\s*$/ contains=livetextRawBlockStart,livetextRawBlockEnd
syn match livetextRawBlockStart /^\.raw\s*$/ contained

" .comment ... .end (plain text)
syn region livetextCommentBlock start=/^\.comment\s*$/ end=/^\.end\s*$/ contains=livetextCommentBlockStart,livetextBlockEnd
syn match livetextCommentBlockStart /^\.comment\s*$/ contained

" .def ... .end (Ruby code)
syn region livetextDefBlock start=/^\.def\s*$/ end=/^\.end\s*$/ contains=livetextDefBlockStart,livetextBlockEnd
syn match livetextDefBlockStart /^\.def\s*$/ contained

" .func ... .end (Ruby code)
syn region livetextFuncBlock start=/^\.func\s*$/ end=/^\.end\s*$/ contains=livetextFuncBlockStart,livetextBlockEnd
syn match livetextFuncBlockStart /^\.func\s*$/ contained

" .code lang ... .end (language-specific)
syn region livetextCodeBlock start=/^\.code\s\+\(ruby\|elixir\|bash\)\s*$/ end=/^\.end\s*$/ contains=livetextCodeBlockStart,livetextBlockEnd
syn match livetextCodeBlockStart /^\.code\s\+\(ruby\|elixir\|bash\)\s*$/ contained

" Special dot commands
syn keyword livetextSpecialCommand .h1 .h2 .h3 .h4 .h5 .h6 .list .banner .index contained

" Define highlighting
hi def link livetextComment Comment
hi def link livetextDotCommand Statement
hi def link livetextDotCommandName Statement
hi def link livetextIndentedCommand Statement
hi def link livetextIndentedCommandName Statement
hi def link livetextBlockEnd Statement
hi def link livetextRawEnd Statement

hi def link livetextVariable Identifier
hi def link livetextVariableName Identifier
hi def link livetextVariableSeparator Delimiter
hi def link livetextFunction Function
hi def link livetextFunctionName Function
hi def link livetextFunctionSeparator Delimiter
hi def link livetextFunctionParam String
hi def link livetextFunctionBracket Delimiter

hi def link livetextBold Bold
hi def link livetextBoldText Bold
hi def link livetextItalic Italic
hi def link livetextItalicText Italic
hi def link livetextCode String
hi def link livetextCodeText String
hi def link livetextStrikethrough Underlined
hi def link livetextStrikethroughText Underlined

hi def link livetextBoldDouble Bold
hi def link livetextBoldDoubleText Bold
hi def link livetextItalicDouble Italic
hi def link livetextItalicDoubleText Italic
hi def link livetextCodeDouble String
hi def link livetextCodeDoubleText String
hi def link livetextStrikethroughDouble Underlined
hi def link livetextStrikethroughDoubleText Underlined

hi def link livetextBracketedBold Bold
hi def link livetextBracketedBoldText Bold
hi def link livetextBracketedItalic Italic
hi def link livetextBracketedItalicText Italic
hi def link livetextBracketedCode String
hi def link livetextBracketedCodeText String
hi def link livetextBracketedStrikethrough Underlined
hi def link livetextBracketedStrikethroughText Underlined

hi def link livetextRawBlock Comment
hi def link livetextRawBlockStart Statement
hi def link livetextCommentBlock Comment
hi def link livetextCommentBlockStart Statement
hi def link livetextDefBlock PreProc
hi def link livetextDefBlockStart Statement
hi def link livetextFuncBlock PreProc
hi def link livetextFuncBlockStart Statement
hi def link livetextCodeBlock PreProc
hi def link livetextCodeBlockStart Statement

hi def link livetextSpecialCommand Statement

let b:current_syntax = "livetext"
