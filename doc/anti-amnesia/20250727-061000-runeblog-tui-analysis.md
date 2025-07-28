# Runeblog TUI Analysis

## Key Patterns from Runeblog TUI

### Auto-Discovery & Setup
- **Repository detection** - checks for existing repo, offers to create if none found
- **Guided initial setup** - "Do you want to do a quick setup?" with editor selection
- **Software-driven questions** - system asks user what they want to do
- **Fast vs. manual setup** - choice between quick defaults or manual configuration

### REPL Structure
- **Main loop** - `mainloop()` with command parsing and error handling
- **Context display** - shows current view in prompt: `[viewname]`
- **Command history** - maintains command history and tab completion
- **Error recovery** - comprehensive error handling with logging

### Command Patterns
- **Simple commands** - `new post`, `new view`, `list posts`, `rebuild`
- **Context-aware** - commands work with current view automatically
- **Menu system** - `show_top_menu()` for complex operations
- **File editing** - integrated editor support with vim parameters

### Key Files Structure
- `bin/blog` - main entry point with auto-discovery
- `lib/repl.rb` - command implementations and REPL logic
- `lib/menus.rb` - menu system and file editing
- `lib/runeblog.rb` - core blog functionality

### Interaction Flow
1. **Startup** - check for repo, create if needed, guided setup
2. **Main loop** - display context, get command, execute, repeat
3. **Commands** - simple text commands with context awareness
4. **Menus** - complex operations via menu system
5. **Error handling** - comprehensive logging and recovery

### Adaptable Patterns for Scriptorium
- **Auto-discovery** - check for Scriptorium repo, offer creation
- **Guided setup** - wizard for initial configuration
- **Context display** - show current view in prompt
- **Simple commands** - `create post`, `switch view`, `generate`
- **Menu system** - for complex operations like configuration
- **Error handling** - robust error recovery and logging

---

**USER:** 
ok, the whole runeblog repo is there, bugs and all

**ASST:** 
[See above content] 