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
    assert_includes_concise response, "Create Repository", "Should show create repository option"
    
    # Test repository creation (this would be a POST request in real usage)
    # For now, we'll test that the form elements exist
    assert_includes_concise response, "create_repo", "Should have repository creation form"
    
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
    assert_includes_concise response, "Asset Management", "Should show asset management interface"
    
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
    assert_includes_concise response, "Advanced Configuration", "Should show configuration interface"
    
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
    assert_includes_concise response, "Deployment Configuration", "Should show deployment interface"
    
    # Deployment configuration accessible
  end

  # Test view generation via web
  def test_006_view_generation_web
    start_web_server
    
    # Setup test environment first
    setup_test_environment
    
    # Test view generation
    response = post("/generate_view", { 'view_name' => 'test-view' })
    assert_response_success(response, "View generation should succeed")
    
    # Check that the generated HTML has valid JavaScript
    index_file = "ui/web/scriptorium-TEST/views/test-view/output/index.html"
    assert File.exist?(index_file), "Index file should exist after generation"
    
    html_content = File.read(index_file)
    
    # Check that load_main function is defined
    assert_match /function load_main/, html_content, "load_main function should be defined"
    
    # Check that the SVG script loads properly (functional test)
    assert_match /console\.log\('SVG script loaded'\)/, html_content,
                 "Should have SVG script loaded message"
  end

  # Test generated HTML has clickable posts
  def test_007_generated_html_has_clickable_posts
    start_web_server
    
    # Setup test environment first
    setup_test_environment
    
    # Create a test post
    post("/create_post", {
      title: "Test Post",
      body: "This is a test post body",
      views: "test-view",
      blurb: "Test post blurb"
    })
    
    # Generate the view first
    post("/generate_view", { 'view_name' => 'test-view' })
    
    # Check the generated HTML
    index_file = "ui/web/scriptorium-TEST/views/test-view/output/index.html"
    html_content = File.read(index_file)
    
    # Should have onclick handlers for posts
    assert_match /onclick="load_main\('index\.html\?post=/, html_content,
                 "Should have onclick handlers for posts"
    
    # Should have post files
    posts_dir = "ui/web/scriptorium-TEST/views/test-view/output/posts"
    assert Dir.exist?(posts_dir), "Posts directory should exist"
    
    post_files = Dir.glob("#{posts_dir}/*.html")
    assert post_files.length > 0, "Should have generated post files"
  end

  def test_008_collapsible_create_post_form
    start_web_server
    setup_test_environment
    
    # Get the view dashboard
    response = get("/view/test-view")
    assert_response_success(response, "View dashboard should load")
    
    # Check that the form is hidden by default
    assert_match(/id="createPostSection".*style="[^"]*display: none[^"]*"/, response.body, "Create post form should be hidden by default")
    
    # Check that the Create Post button exists
    assert_match(/id="createPostButton".*Create Post/, response.body, "Create Post button should exist")
    
    # Check that the form has Edit and Cancel buttons
    assert_match(/button.*Edit/, response.body, "Form should have Edit button")
    assert_match(/button.*Cancel/, response.body, "Form should have Cancel button")
    
    # Check that view checkboxes exist
    assert_match(/name="views\[\]"/, response.body, "Form should have view checkboxes")
  end

  def test_009_create_post_with_modal_redirect
    start_web_server
    setup_test_environment
    
    # Create a post with the new form
    response = post("/create_post", {
      title: "Modal Test Post",
      blurb: "Test post for modal",
      tags: "test, modal",
      views: ["test-view"]
    })
    
    # Should redirect to view with edit_post parameter
    assert_response_redirect(response, "Should redirect after creating post")
    assert_match(/edit_post=/, response['Location'], "Should redirect with edit_post parameter")
    assert_match(/view\/test-view/, response['Location'], "Should redirect to view dashboard")
  end

  def test_010_post_content_api_endpoint
    start_web_server
    setup_test_environment
    
    # Create a post first
    create_response = post("/create_post", {
      title: "API Test Post",
      blurb: "Test post for API",
      views: ["test-view"]
    })
    
    # Extract post ID from redirect
    redirect_location = create_response['Location']
    post_id = redirect_location.match(/edit_post=(\d+)/)[1]
    
    # Test the API endpoint
    api_response = get("/api/post_content/#{post_id}")
    assert_response_success(api_response, "API endpoint should work")
    
    # Should return the post content
    assert_match(/API Test Post/, api_response.body, "API should return post content")
  end

    private
  # All helper methods are now in WebTestHelper
end
