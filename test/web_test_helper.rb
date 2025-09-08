#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'fileutils'

module WebTestHelper
  # Web server configuration
  WEB_SERVER_PORT = 4567
  WEB_SERVER_URL = "http://localhost:#{WEB_SERVER_PORT}"
  
  # Test repository path
  TEST_REPO_PATH = "ui/web/scriptorium-TEST"
  
  # Start web server in test mode
  def start_web_server
    # Check if server is already running
    return if server_running?
    
    # Kill any existing server on the port first
    system("lsof -ti:#{WEB_SERVER_PORT} | xargs kill -9 2>/dev/null")
    sleep(1) # Give it time to release the port
    
    # Start the server
    system("rbenv exec ruby ui/web/bin/scriptorium-web start --test")
    wait_for_server
  end

  # Check if server is already running
  def server_running?
    begin
      response = Net::HTTP.get_response(URI("#{WEB_SERVER_URL}/status"))
      response.code == "200"
    rescue
      false
    end
  end

  # Stop web server
  def stop_web_server
    system("rbenv exec ruby ui/web/bin/scriptorium-web stop")
  end

  # Wait for server to be ready
  def wait_for_server(timeout = 15)
    start_time = Time.now
    last_error = nil
    
    while Time.now - start_time < timeout
      begin
        response = Net::HTTP.get_response(URI("#{WEB_SERVER_URL}/status"))
        if response.code == "200"
          return true
        end
      rescue => e
        last_error = e
        # Server not ready yet
      end
      sleep 0.5
    end
    
    # If we get here, the server didn't start
    error_msg = "Web server did not start within #{timeout} seconds"
    if last_error
      error_msg += " (last error: #{last_error.message})"
    end
    flunk error_msg
  end

  # Make GET request
  def get(path, params = {})
    uri = URI("#{WEB_SERVER_URL}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    
    response = Net::HTTP.get_response(uri)
    response
  rescue => e
    flunk "GET request failed: #{e.message}"
  end

  # Make POST request
  def post(path, data = {})
    uri = URI("#{WEB_SERVER_URL}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(data)
    
    response = http.request(request)
    response
  rescue => e
    flunk "POST request failed: #{e.message}"
  end

  # Make PUT request
  def put(path, data = {})
    uri = URI("#{WEB_SERVER_URL}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri)
    request.set_form_data(data)
    
    response = http.request(request)
    response
  rescue => e
    flunk "PUT request failed: #{e.message}"
  end

  # Make DELETE request
  def delete(path)
    uri = URI("#{WEB_SERVER_URL}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri)
    
    response = http.request(request)
    response
  rescue => e
    flunk "DELETE request failed: #{e.message}"
  end

  # Assert response is successful (200)
  def assert_response_success(response, description)
    assert response, "Response should exist"
    assert_equal "200", response.code, "#{description}: Expected 200, got #{response.code}"
  end

  # Assert response is redirect (302 or 303)
  def assert_response_redirect(response, description)
    assert response, "Response should exist"
    assert ["302", "303"].include?(response.code), "#{description}: Expected 302 or 303, got #{response.code}"
  end

  # Assert response is not found (404)
  def assert_response_not_found(response, description)
    assert response, "Response should exist"
    assert_equal "404", response.code, "#{description}: Expected 404, got #{response.code}"
  end

  # Assert that response body includes text, with concise error message
  def assert_includes_concise(response, text, description)
    unless response.body.include?(text)
      # Show first 200 chars of response for debugging
      snippet = response.body[0, 200].gsub(/\s+/, ' ').strip
      flunk "#{description} - Expected to find '#{text}' in response. Response snippet: #{snippet}..."
    end
  end

  # Parse JSON response
  def parse_json_response(response)
    return nil unless response.body
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    flunk "Failed to parse JSON response: #{e.message}"
  end

  # Clean up test repository
  def cleanup_test_repo
    FileUtils.rm_rf(TEST_REPO_PATH) if Dir.exist?(TEST_REPO_PATH)
    # Also clean up backup directory for test repo
    backup_dir = File.dirname(TEST_REPO_PATH) + "/backup-scriptorium-TEST"
    FileUtils.rm_rf(backup_dir) if Dir.exist?(backup_dir)
  end

  # Setup basic test environment (repo + view)
  def setup_test_environment
    # Create repository
    post("/create_repo", {})
    
    # Create test view
    post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
  end

  # Wait for a specific condition with timeout
  def wait_for_condition(timeout = 10, &block)
    start_time = Time.now
    while Time.now - start_time < timeout
      if block.call
        return true
      end
      sleep 0.5
    end
    flunk "Condition not met within #{timeout} seconds"
  end

  # Check if web app is in test mode
  def assert_test_mode_active
    response = get("/status")
    data = parse_json_response(response)
    assert data, "Should have status data"
    assert_nil data["current_view"], "Should not have current view (test mode active)"
    assert_equal false, data["repo_loaded"], "Should not have repo loaded (test mode active)"
  end

  # Verify test repository path is being used
  def assert_test_repository_path
    # This would require checking the web app's internal state
    # For now, we verify by checking that no production data is visible
    response = get("/")
    assert_response_success(response, "Dashboard should load")
    assert_includes response.body, "No repository found", "Should show no repository (test mode)"
  end
end
