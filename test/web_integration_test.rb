#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/scriptorium'
require_relative 'web_test_helper'

class WebIntegrationTest < Minitest::Test
  include Scriptorium::Helpers
  include WebTestHelper
  
  # Test repository path and web server config are now in WebTestHelper
  
  def setup
    cleanup_test_repo
    # Don't create repo here - let the web app create it interactively
    # Disable DBC contracts in tests
    ENV['DBC_DISABLED'] = 'true'
    
    # rbenv hack to ensure correct Ruby version
    ENV['PATH'] = "#{ENV['HOME']}/.rbenv/shims:#{ENV['PATH']}"
    ENV['RBENV_VERSION'] = '3.2.3'
  end

  def teardown
    cleanup_test_repo
    stop_web_server
  end

  # Test basic web app functionality
  def test_001_basic_web_interaction
    start_web_server
    
    # Test that web app starts and responds
    response = get("/status")
    assert_response_success(response, "Status endpoint should work")
    
    # Verify test mode is working
    data = parse_json_response(response)
    assert data, "Should have status data"
    assert_nil data["current_view"], "Should not have current view (test repo empty)"
    assert_equal false, data["repo_loaded"], "Should not have repo loaded (test repo empty)"
    
    # Basic web interaction working
  end

  # Test view creation workflow via web
  def test_002_view_creation_workflow
    start_web_server
    
    # Test view creation form
    response = get("/")
    assert_response_success(response, "Dashboard should load")
    assert_includes response.body, "Create Repository", "Should show create repository option"
    
    # Test repository creation (this would be a POST request in real usage)
    # For now, we'll test that the form elements exist
    assert_includes response.body, "create_repo", "Should have repository creation form"
    
    # View creation workflow accessible
  end

  # Test asset management via web
  def test_003_asset_management_web
    start_web_server
    
    # Setup test environment first
    setup_test_environment
    
    # Test asset management page
    response = get("/asset_management")
    assert_response_success(response, "Asset management page should load")
    assert_includes response.body, "Asset Management", "Should show asset management interface"
    
    # Asset management accessible
  end

  # Test view configuration via web
  def test_004_view_configuration_web
    start_web_server
    
    # Setup test environment first
    setup_test_environment
    
    # Test view configuration page
    response = get("/advanced_config")
    assert_response_success(response, "Advanced config page should load")
    assert_includes response.body, "Advanced Configuration", "Should show configuration interface"
    
    # View configuration accessible
  end

  # Test deployment configuration via web
  def test_005_deployment_configuration_web
    start_web_server
    
    # Setup test environment first
    setup_test_environment
    
    # Test deployment configuration page
    response = get("/deploy_config")
    assert_response_success(response, "Deploy config page should load")
    assert_includes response.body, "Deployment Configuration", "Should show deployment interface"
    
    # Deployment configuration accessible
  end

    private
  # All helper methods are now in WebTestHelper
end
