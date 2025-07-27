# Scriptorium Test Suite

## Quick Start

### Run All Tests (Unit + Automated Manual Tests)
```bash
ruby test/run_automated_tests.rb
```

### Run Unit Tests Only
```bash
ruby test/all
```

### Run Individual Manual Tests
```bash
# Interactive mode (opens browser)
ruby test/manual/test1.rb

# Automated mode (no browser, just validation)
ruby test/manual/test1.rb --automated
```

## Test Types

### Unit Tests (`test/unit/`)
- **Core functionality tests** - Basic helper methods, file operations
- **Repo tests** - Repository creation, management, post handling
- **Post tests** - Individual post functionality
- **View tests** - View generation and management
- **Banner SVG tests** - SVG banner generation and validation

### Manual Tests (`test/manual/`)
- **Integration tests** - End-to-end workflows
- **Banner feature tests** - Visual verification of SVG banners
- **Widget tests** - Sidebar widgets and functionality
- **Layout tests** - Page layout and styling

## Automated Testing

All manual tests support `--automated` mode for CI/CD:
- No browser interaction required
- Validates file generation
- Returns exit codes for automation
- Use `--automated` as the **last** parameter

## Environment Setup

The test environment is automatically configured:
- PATH is set to include rbenv shims
- Test repositories are created in `test/scriptorium-TEST/`
- Webrick server starts on port 8000 for manual tests
- Cleanup happens automatically

## Examples

```bash
# Run all tests
ruby test/run_automated_tests.rb

# Run specific manual test interactively
ruby test/manual/test_banner_combinations.rb

# Run specific manual test in automated mode
ruby test/manual/test_banner_combinations.rb --automated

# Run test3 with specific view
ruby test/manual/test3.rb blog1 --automated
``` 