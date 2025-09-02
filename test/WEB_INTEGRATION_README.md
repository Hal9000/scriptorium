# Web Integration Test Framework

This directory contains a comprehensive web integration testing framework for the Scriptorium web application, based on the existing TUI integration test patterns.

## Overview

The web integration tests verify that the web application works correctly in test mode, including:
- Server startup/shutdown in test mode
- HTTP endpoint functionality
- Form submission and redirects
- Test repository isolation
- Complete workflow testing

## Test Files

### 1. `web_test_helper.rb`
**Shared helper module** containing common web testing functionality:
- Web server management (start/stop)
- HTTP request methods (GET, POST, PUT, DELETE)
- Response assertions (success, redirect, not found)
- Test environment setup
- Repository cleanup

### 2. `web_integration_test.rb`
**Basic integration tests** for core web functionality:
- `test_001_basic_web_interaction` - Verifies web app starts and responds
- `test_002_view_creation_workflow` - Tests dashboard and repository creation
- `test_003_asset_management_web` - Tests asset management access
- `test_004_view_configuration_web` - Tests view configuration access
- `test_005_deployment_configuration_web` - Tests deployment configuration access

### 3. `web_workflow_test.rb`
**Comprehensive workflow tests** that mirror TUI functionality:
- `test_001_complete_repository_setup` - Full repository creation workflow
- `test_002_view_creation_workflow` - View creation via web forms
- `test_003_post_creation_workflow` - Post creation via web forms
- `test_004_asset_management_workflow` - Asset management workflow
- `test_005_view_configuration_workflow` - View configuration workflow
- `test_006_deployment_workflow` - Deployment configuration workflow
- `test_007_error_handling` - Error handling and edge cases

## Key Features

### Test Mode Support
- All tests run with `--test` flag
- Uses `ui/web/scriptorium-TEST` repository
- Completely isolated from production data
- Verifies test mode is active

### HTTP Testing
- Tests actual HTTP requests/responses
- Handles redirects (302/303) properly
- Tests form submissions and validations
- Verifies response codes and content

### Workflow Testing
- Tests complete user workflows
- Sets up test environment (repo + view) as needed
- Verifies state changes after operations
- Tests error conditions and edge cases

### Server Management
- Automatic web server startup/shutdown
- Waits for server to be ready
- Cleans up test repositories
- Handles server process management

## Usage

### Running Individual Tests
```bash
# Run basic integration tests
ruby test/web_integration_test.rb

# Run workflow tests
ruby test/web_workflow_test.rb

# Run specific test
ruby test/web_integration_test.rb -n test_001_basic_web_interaction
```

### Running All Web Tests
```bash
# Run all web-related tests
ruby test/web_integration_test.rb
ruby test/web_workflow_test.rb
```

## Test Patterns

### Setup/Teardown
```ruby
def setup
  cleanup_test_repo
  ENV['DBC_DISABLED'] = 'true'
  # rbenv hack for correct Ruby version
end

def teardown
  cleanup_test_repo
  stop_web_server
end
```

### HTTP Requests
```ruby
# GET request
response = get("/status")

# POST request with form data
response = post("/create_view", {
  name: "test-view",
  title: "Test View"
})
```

### Assertions
```ruby
# Success response
assert_response_success(response, "Should succeed")

# Redirect response
assert_response_redirect(response, "Should redirect")

# Content verification
assert_includes response.body, "Expected text"
```

### Test Environment Setup
```ruby
# Setup basic test environment (repo + view)
setup_test_environment

# Or manually
post("/create_repo", {})
post("/create_view", { name: "test-view", title: "Test" })
```

## Architecture

### Helper Module Design
- **WebTestHelper** - Shared functionality across all web tests
- **HTTP Methods** - GET, POST, PUT, DELETE with error handling
- **Assertions** - Response code and content verification
- **Server Management** - Start, stop, wait, cleanup

### Test Class Structure
- **Include Helpers** - `Scriptorium::Helpers` and `WebTestHelper`
- **Setup/Teardown** - Repository cleanup and server management
- **Test Methods** - Individual workflow tests
- **Private Methods** - Test-specific helper methods

### Test Isolation
- Each test starts with clean state
- Test repository is created/destroyed per test
- Web server is started/stopped per test
- No cross-test contamination

## Comparison with TUI Tests

| Aspect | TUI Tests | Web Tests |
|--------|-----------|-----------|
| **Interface** | PTY/terminal | HTTP endpoints |
| **Input** | `send_and_expect` | HTTP requests |
| **Output** | Terminal output | HTTP responses |
| **Setup** | Create test repo | Create test repo + start web server |
| **Isolation** | `--test` flag | `--test` flag |
| **Speed** | Fast | Medium (HTTP overhead) |
| **Realism** | Terminal interaction | Web browser interaction |

## Benefits

1. **Real HTTP Testing** - Tests actual web requests/responses
2. **End-to-End Validation** - Tests complete web stack
3. **Browser-Like Behavior** - Simulates real user interactions
4. **Test Mode Verification** - Ensures test isolation works
5. **Workflow Coverage** - Tests complete user journeys
6. **Error Handling** - Verifies proper error responses
7. **Integration Testing** - Tests web app + API working together

## Future Enhancements

- **File Upload Testing** - Test asset upload functionality
- **Session Management** - Test user sessions and authentication
- **AJAX Testing** - Test dynamic content loading
- **Performance Testing** - Response time and load testing
- **Browser Testing** - Integration with headless browsers
- **API Testing** - Direct API endpoint testing

## Dependencies

- **Minitest** - Testing framework
- **Net::HTTP** - HTTP client for testing
- **JSON** - Response parsing
- **FileUtils** - File system operations
- **Scriptorium::Helpers** - Project helper functions
