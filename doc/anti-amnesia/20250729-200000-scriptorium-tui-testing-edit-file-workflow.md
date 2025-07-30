# Scriptorium TUI Testing: Edit File Logic Flow

**Date**: 2025-07-29 20:00:00  
**Context**: Continuing development of Scriptorium TUI testing infrastructure

## Objective
Test the complete interactive editing workflow that a real user experiences, including actual file content changes using the `edit_file` method. Focus on testing the logic flow where users select `ed` as the editor and make actual file changes.

## Key Technical Concepts
- **Scriptorium TUI**: Command-line interface with wizard-based setups and interactive workflows
- **`edit_file` method**: API method that opens files in user's chosen editor (determined by `ENV['EDITOR']` or falls back to `vim`)
- **`ed` editor**: Line-oriented text editor chosen for automated testing due to non-interactive nature
- **`Open3.popen3`**: Ruby module for running external processes and interacting with stdin/stdout/stderr
- **`IO.select`**: Ruby method for monitoring I/O readiness, initially misused causing timing issues

## Files Modified

### `bin/scriptorium`
- **Fixed `@@test_repo_path` NameError**: Removed undefined class variable reference in `discover_repo` method
- **Fixed `edit_file` calls**: Changed all instances from `edit_file(...)` to `@api.edit_file(...)` to fix `NoMethodError`
- **Added "Create new repository?" prompt**: Modified main execution block to ask before creating repo
- **Mocked `which` method**: Added test-mode mocking to prevent hanging during editor detection
- **Removed post-setup message**: Removed "You can now use 'create post <title>'..." to ensure "Goodbye!" is final message
- **Added debug statements**: Temporary debug output to troubleshoot hanging issues

### `test/tui_editor_integration_test.rb`
- **Created comprehensive integration test**: `test_links_widget_editing_workflow_part_1`
- **Fixed I/O timing issues**: Added timeout to `read_available_output` method (0.1s → 2.0s)
- **Added conversation-style logging**: `USER:` and `CODE:` prefixes with `@@verbose_output` toggle
- **Created "expecting" approach**: Alternative test method using `expect_output` and `send_command` helpers
- **Fixed command sequence**: Updated to complete editor setup before sending "quit"

## Major Issues Encountered and Resolved

### 1. Hanging During Process Startup
**Problem**: TUI hanging before producing any output  
**Root Cause**: `read_available_output` using blocking I/O with no timeout  
**Solution**: Added timeout to `IO.select` calls

### 2. `NoMethodError: undefined method 'edit_file'`
**Problem**: TUI calling `edit_file` directly instead of `@api.edit_file`  
**Root Cause**: Method calls not updated after API refactoring  
**Solution**: Updated all `edit_file` calls to use `@api.edit_file`

### 3. `RepoDirAlreadyExists` Error
**Problem**: Path mismatch between TUI creating `"test/scriptorium-TEST"` and test cleanup looking for `"scriptorium-TEST"`  
**Solution**: Standardized on `"scriptorium-TEST"` path

### 4. Out-of-Order I/O
**Problem**: Commands sent before TUI ready, causing non-blocking I/O issues  
**Root Cause**: Insufficient waiting between commands  
**Solution**: Increased timeout in `read_available_output`

### 5. Editor Setup Hanging
**Problem**: `which` command calls hanging in test environment  
**Root Cause**: System calls not working properly in `Open3.popen3` context  
**Solution**: Mocked `which` method for test mode

## Current Status
- **Original test approach**: Working but with timing issues (completes in ~1.2s)
- **"Expecting" approach**: Has fundamental issues with process startup
- **Main issue**: Test sending "quit" before TUI completes editor setup
- **System performance**: High memory usage affecting test timing and reliability

## Test Command Sequence
```ruby
commands = [
  "y",  # Create new repository
  "y",  # Want assistance with first view
  "testview",  # View name
  "Test View",  # View title  
  "Test Subtitle",  # Subtitle
  "y",  # Edit layout
  "a", "header", "main", "right", ".", "w", "q",  # ed commands
  "n", "n", "n",  # Skip container configuration
  "1",  # Choose nano editor
  "quit"  # Exit TUI
]
```

## Key Insights
1. **I/O timing is critical**: Non-blocking I/O causes out-of-order command/response
2. **System performance matters**: High memory usage affects test reliability
3. **Mocking system calls essential**: `which` commands hang in test environment
4. **Command sequence must match TUI flow**: Need to complete setup before entering mainloop

## Next Steps
1. Fix command sequence to properly complete editor setup
2. Address system performance issues
3. Refine timing in test infrastructure
4. Complete the edit_file workflow testing with actual file changes

## Technical Debt
- Debug statements need cleanup
- "Expecting" approach needs fundamental rework
- Test infrastructure could benefit from more robust I/O handling
- System performance monitoring needed for reliable testing 