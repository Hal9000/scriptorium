#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/scriptorium'
require_relative 'web_test_helper'

class WebWorkflowTest < Minitest::Test
  include Scriptorium::Helpers
  include WebTestHelper
  
  # Test repository path and web server config are now in WebTestHelper
  
  def setup
    cleanup_test_repo
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

  # Test complete repository setup workflow via web
  def test_001_complete_repository_setup
    start_web_server
    
    # Step 1: Check initial state (no repository)
    response = get("/")
    assert_response_success(response, "Dashboard should load initially")
    assert_includes response.body, "No repository loaded", "Should show no repository message"
    
    # Step 2: Create repository via web form
    response = post("/create_repo", {})
    assert_response_redirect(response, "Repository creation should redirect after success")
    
    # Step 3: Verify repository was created
    response = get("/")
    assert_response_success(response, "Dashboard should load after repo creation")
    assert_includes response.body, "scriptorium-TEST", "Should show repository name"
    
    # Complete repository setup workflow working
  end

  # Test view creation workflow via web
  def test_002_view_creation_workflow
    start_web_server
    
    # Step 1: Create repository first
    post("/create_repo", {})
    
    # Step 2: Create view via web form
    response = post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    assert_response_redirect(response, "View creation should redirect after success")
    
    # Step 3: Verify view was created
    response = get("/")
    assert_response_success(response, "Dashboard should load after view creation")
    assert_includes response.body, "test-view", "Should show created view"
    
    # View creation workflow working
  end

  # Test post creation workflow via web
  def test_003_post_creation_workflow
    start_web_server
    
    # Step 1: Setup repository and view
    post("/create_repo", {})
    post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    
    # Step 2: Create post via web form
    response = post("/create_post", {
      title: "Test Post via Web",
      content: "This is a test post created via the web interface."
    })
    assert_response_redirect(response, "Post creation should redirect after success")
    
    # Step 3: Verify post was created
    response = get("/view/test-view")
    assert_response_success(response, "View dashboard should load")
    assert_includes response.body, "Test Post via Web", "Should show created post"
    
    # Post creation workflow working
  end

  # Test post editing workflow via web
  def test_004_post_editing_workflow
    start_web_server
    
    # Step 1: Create a fresh test repository
    response = post("/create_repo", {})
    assert_response_redirect(response, "Repository creation should redirect after success")
    
    # Step 2: Create a test view
    response = post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    assert_response_redirect(response, "View creation should redirect after success")
    
    # Step 3: Create a post via the web interface
    response = post("/create_post", {
      title: "Test Post for Editing",
      content: "Original content of the test post."
    })
    assert_response_redirect(response, "Post creation should redirect after success")
    
    # Step 4: Get the post ID from the redirect
    # The redirect should be to /edit_post/#{post_num}
    redirect_location = response['Location']
    assert_includes redirect_location, "/edit_post/", "Should redirect to edit page"
    
    # Extract post ID from redirect URL
    post_id = redirect_location.split('/').last.split('?').first
    assert_match(/^\d+$/, post_id, "Post ID should be numeric")
    
    # Step 5: Edit the post content
    edited_content = "Updated content with LiveText syntax.\n\n.h1 Updated Title\n\nThis is *bold text and _italic text.\n\n.raw\nRaw content here\n__RAW__\n\n.def test_function\n  puts 'Hello World'\n.end"
    
    response = post("/save_post/#{post_id}", {
      content: edited_content
    })
    assert_response_redirect(response, "Post saving should redirect after success")
    
    # Step 6: Verify the post was saved by checking the redirect message
    assert_includes response['Location'], "message=Post ##{post_id} saved", "Should show success message"
    
    # Step 7: Verify the content was actually saved by reading the post file
    # This tests the actual file writing functionality
    # The file path uses the 4-digit post number format (e.g., 0001, 0002)
    post_number = sprintf("%04d", post_id.to_i)
    post_file_path = "#{WebTestHelper::TEST_REPO_PATH}/posts/#{post_number}/source.lt3"
    assert File.exist?(post_file_path), "Post source file should exist at #{post_file_path}"
    
    saved_content = File.read(post_file_path)
    
    # The write_file helper adds a trailing newline, so we need to account for that
    expected_content = edited_content + "\n"
    assert_equal expected_content, saved_content, "Saved content should match edited content (with trailing newline)"
    
    # Post editing workflow working
  end

  # Test asset management workflow via web
  def test_005_asset_management_workflow
    start_web_server
    
    # Step 1: Setup repository and view
    post("/create_repo", {})
    post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    
    # Step 2: Access asset management
    response = get("/asset_management")
    assert_response_success(response, "Asset management page should load")
    assert_includes response.body, "Asset Management", "Should show asset management interface"
    
    # Step 3: Test asset upload (simulated)
    # Note: This would require file upload handling in a real test
    assert_includes response.body, "upload", "Should have upload functionality"
    
    # Asset management workflow accessible
  end

  # Test view configuration workflow via web
  def test_006_view_configuration_workflow
    start_web_server
    
    # Step 1: Setup repository and view
    post("/create_repo", {})
    post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    
    # Step 2: Access view configuration
    response = get("/configure_view/test-view")
    assert_response_success(response, "View configuration page should load")
    assert_includes response.body, "Configure View", "Should show configuration interface"
    
    # Step 3: Test configuration saving
    response = post("/save_view_config/test-view", {
      view_title: "Updated Test View",
      view_subtitle: "Updated subtitle",
      view_theme: "standard"
    })
    assert_response_redirect(response, "Configuration save should redirect after success")
    
    # View configuration workflow working
  end

  # Test deployment workflow via web
  def test_007_deployment_workflow
    start_web_server
    
    # Step 1: Setup repository and view
    post("/create_repo", {})
    post("/create_view", {
      name: "test-view",
      title: "Test View",
      subtitle: "A test view for web testing"
    })
    
    # Step 2: Access deployment configuration
    response = get("/deploy_config")
    assert_response_success(response, "Deployment config page should load")
    assert_includes response.body, "Deployment Configuration", "Should show deployment interface"
    
    # Step 3: Test deployment configuration saving
    response = post("/deploy_config", {
      deploy_config: "proto http\nserver localhost\npath /test",
      from_deploy: "0"
    })
    assert_response_redirect(response, "Deployment config save should redirect after success")
    
    # Deployment workflow accessible
  end

  # Test publish/unpublish workflow via web
  def test_008_publish_unpublish_workflow
    start_web_server
    setup_test_environment
    
    # Create a post
    response = post("/create_post", { title: "Test Publish Post", content: "Content for publish test" })
    assert_response_redirect(response, "Should create post successfully")
    
    # Extract post ID from redirect
    redirect_location = response['Location']
    post_id = redirect_location.split('/').last.split('?').first
    
    # Initially post should be unpublished
    post_file = "#{WebTestHelper::TEST_REPO_PATH}/posts/#{sprintf("%04d", post_id.to_i)}/source.lt3"
    assert File.exist?(post_file), "Post file should exist"
    
    # Publish the post via web interface
    response = post("/toggle_post_status/#{post_id}", {})
    assert_equal 200, response.code.to_i, "Should return 200 for publish"
    
    # Parse JSON response
    json_response = JSON.parse(response.body)
    assert json_response['success'], "Publish should succeed"
    assert json_response['published'], "Post should be marked as published"
    
    # Verify the HTML shows the post as published
    response = get("/view/test-view")
    assert_response_success(response, "Should load view dashboard")
    assert_includes response.body, "Published", "HTML should show 'Published' status"
    
    # Unpublish the post via web interface
    response = post("/toggle_post_status/#{post_id}", {})
    assert_equal 200, response.code.to_i, "Should return 200 for unpublish"
    
    # Parse JSON response
    json_response = JSON.parse(response.body)
    assert json_response['success'], "Unpublish should succeed"
    refute json_response['published'], "Post should be marked as unpublished"
    
    # Verify the HTML shows the post as unpublished
    response = get("/view/test-view")
    assert_response_success(response, "Should load view dashboard")
    assert_includes response.body, "unpublished", "HTML should show 'unpublished' status"
  end

  # Test delete/restore workflow via web
  def test_009_delete_restore_workflow
    start_web_server
    setup_test_environment
    
    # Create a post
    response = post("/create_post", { title: "Test Delete Post", content: "Content for delete test" })
    assert_response_redirect(response, "Should create post successfully")
    
    # Extract post ID from redirect
    redirect_location = response['Location']
    post_id = redirect_location.split('/').last.split('?').first
    
    # Initially post should be visible
    response = get("/view/test-view")
    assert_response_success(response, "Should load view dashboard")
    assert_includes response.body, "Test Delete Post", "HTML should show post title"
    refute_includes response.body, "text-decoration: line-through", "Post should not be strikethrough"
    
    # Delete the post via web interface
    response = post("/delete_post/#{post_id}", {})
    assert_response_redirect(response, "Should redirect after delete")
    
    # Verify the HTML shows the post as deleted (strikethrough)
    response = get("/view/test-view")
    assert_response_success(response, "Should load view dashboard")
    assert_includes response.body, "Test Delete Post", "HTML should still show post title"
    assert_includes response.body, "text-decoration: line-through", "Post should be strikethrough when deleted"
    
    # Restore the post via web interface
    response = post("/restore_post/#{post_id}", {})
    assert_response_redirect(response, "Should redirect after restore")
    
    # Verify the HTML shows the post as restored (no strikethrough)
    response = get("/view/test-view")
    assert_response_success(response, "Should load view dashboard")
    assert_includes response.body, "Test Delete Post", "HTML should show post title"
    refute_includes response.body, "text-decoration: line-through", "Post should not be strikethrough when restored"
  end

  # Test error handling and edge cases
  def test_010_error_handling
    start_web_server
    
    # Test 1: Access non-existent view
    response = get("/view/non-existent-view")
    assert_equal "302", response.code, "Should redirect for non-existent view"
    
    # Test 2: Access pages without repository
    response = get("/asset_management")
    assert_equal "302", response.code, "Should redirect without repository"
    
    # Test 3: Access pages without view
    response = get("/configure_view/test-view")
    assert_equal "302", response.code, "Should redirect without view"
    
    # Error handling working correctly
  end

  private
  # All helper methods are now in WebTestHelper
end
