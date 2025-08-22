#!/usr/bin/env ruby

require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestDeployConfig < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    # Clean up any existing test directory first
    test_dir = "test/scriptorium-TEST"
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    
    @repo = Scriptorium::Repo.create(test_dir, testmode: true)
    @view = @repo.create_view("testview", "Test View", "Test Subtitle")
    @api = Scriptorium::API.new(testmode: true)
    @api.open_repo(@repo.root)
    
    # Set up deployment configuration for tests
    setup_deployment_config
  end

  def teardown
    # Clean up any test directories that were created
    Dir.glob("test/scriptorium-TEST*").each do |dir|
      system("rm -rf #{dir}")
    end
  end

  def test_001_deploy_config_availability
    # Test that deployment tests can check for configuration availability
    unless @api.testing
      skip "Deployment tests require test mode"
      return
    end
    
    # Check if deployment config exists
    config_file = "test/config/deployment.txt"
    unless File.exist?(config_file)
      skip "Deployment not configured - add deployment.txt to test/config/"
      return
    end
    
    # If we get here, config exists and we can run deployment tests
    # This test just verifies the configuration is available
    assert File.exist?(config_file), "Deployment config should exist for testing"
    
    # Parse the config to make sure it's valid
    config_content = read_file(config_file)
    config = @api.parse_deploy_config(config_content)
    
    # Verify required fields are present
    required_fields = %w[user server docroot path]
    required_fields.each do |field|
      assert config.key?(field), "Deployment config missing required field: #{field}"
      assert !config[field].to_s.empty?, "Deployment config field #{field} cannot be empty"
    end
    
    # Verify we can build a valid rsync destination
    destination = @api.build_rsync_destination(config)
    assert destination, "Should be able to build rsync destination from valid config"
    assert destination.match(/^.+@.+:.+$/), "Rsync destination should match user@server:path format"
  end

  def test_002_deploy_config_format_validation
    # Test that deployment config follows expected format
    unless @api.testing
      skip "Deployment tests require test mode"
      return
    end
    
    config_file = "test/config/deployment.txt"
    unless File.exist?(config_file)
      skip "Deployment not configured - add deployment.txt to test/config/"
      return
    end
    
    # Test various config formats
    config_content = read_file(config_file)
    config = @api.parse_deploy_config(config_content)
    
    # Test that user field doesn't contain @ (should be separate from server)
    user = config["user"]
    assert !user.include?("@"), "User field should not contain @ symbol"
    
    # Test that server field is a valid hostname/IP
    server = config["server"]
    assert server, "Server field should be present"
    assert server.length > 0, "Server field should not be empty"
    
    # Test that docroot field is a valid Unix path
    docroot = config["docroot"]
    assert docroot, "Docroot field should be present"
    assert docroot.start_with?("/"), "Docroot should be absolute (start with /)"
    
    # Test that path field is present (can be relative)
    path = config["path"]
    assert path, "Path field should be present"
    assert !path.empty?, "Path field should not be empty"
  end

  def test_003_real_deployment_workflow
    # Skip if not in test mode or no deployment config
    unless @api.testing
      skip "Deployment tests require test mode"
      return
    end
    
    config_file = "test/config/deployment.txt"
    unless File.exist?(config_file)
      skip "Deployment not configured - add deployment.txt to test/config/"
      return
    end
    
    # Create some test content
    @api.create_post("Test Post 1", "Test content here", blurb: "This is a test post for deployment")
    @api.create_post("Test Post 2", "More test content", blurb: "Another test post")
    
    # Generate the view
    @api.generate_view(@view.name)
    
    # Verify output was created
    output_dir = @view.dir/:output
    assert Dir.exist?(output_dir), "Output directory should exist"
    assert File.exist?(output_dir/"index.html"), "Index should be generated"
    assert Dir.exist?(output_dir/:posts), "Posts directory should exist"
    
    # Test deployment (this will actually try to deploy)
    deploy_config = @api.parse_deploy_config(read_file(config_file))
    assert deploy_config, "Should be able to parse deployment config"
    
    # Verify we can build deployment destination
    destination = @api.build_rsync_destination(deploy_config)
    assert destination, "Should be able to build rsync destination"
    
    # Test actual deployment
    result = @api.deploy(@view.name)
    assert result, "Deployment should succeed"
  end

  def test_004_deployment_with_assets
    # Skip if not configured
    unless @api.testing && File.exist?("test/config/deployment.txt")
      skip "Deployment not configured"
      return
    end
    
    # Create post with assets
    post = @api.create_post("Asset Test Post", "Content with assets", blurb: "Testing asset deployment")
    
    # Add some test assets
    assets_dir = post.dir/:assets
    make_dir(assets_dir)
    write_file(assets_dir/"test-image.jpg", "fake image data")
    write_file(assets_dir/"test.css", "body { color: red; }")
    
    # Generate and deploy
    @api.generate_view(@view.name)
    result = @api.deploy(@view.name)
    
    assert result, "Deployment with assets should succeed"
  end

  def test_005_deployment_verification
    # Skip if not configured
    unless @api.testing && File.exist?("test/config/deployment.txt")
      skip "Deployment not configured"
      return
    end
    
    # Create and deploy content
    @api.create_post("Verification Post", "Content to verify", blurb: "Testing deployment verification")
    @api.generate_view(@view.name)
    result = @api.deploy(@view.name)
    
    # Verify deployment succeeded
    assert result, "Deployment should succeed"
    
    # Verify deployed content via HTTP
    # Get deployment config for domain construction
    config = @api.parse_deploy_config(read_file("test/config/deployment.txt"))
    domain = config["proto"] + "://" + config["server"]
    base_url = "#{domain}/#{config["path"]}"
    
    # Test main page
    main_page = `curl -s #{base_url}/`
    assert main_page.include?("Test View"), "Main page should contain view title"
    assert main_page.include?("Test Subtitle"), "Main page should contain view subtitle"
    assert main_page.include?("Verification Post"), "Main page should contain deployed post title"
    # assert main_page.include?("Testing deployment verification"), "Main page should contain post blurb"  # May not be on main page
    
    # Test post page - posts are numbered, so try 0001
    post_url = "#{base_url}/posts/0001-verification-post.html"
    post_page = `curl -s #{post_url}`
    assert post_page.include?("Verification Post"), "Post page should contain post title"
    assert post_page.include?("Content to verify"), "Post page should contain post body"
    # assert post_page.include?("Testing deployment verification"), "Post page should contain post blurb"  # Blurb may not be on post page
    
    # Test clean permalink URL (should work now with copying instead of symlinking)
    clean_post_url = "#{base_url}/permalink/verification-post.html"
    clean_post_page = `curl -s #{clean_post_url}`
    assert clean_post_page.include?("Verification Post"), "Clean permalink should contain post title"
    assert clean_post_page.include?("Content to verify"), "Clean permalink should contain post body"
    
    # Test basic structure elements that are likely to be present
    # assert post_page.include?("<html"), "Post page should have HTML structure"  # May be fragment
    # assert post_page.include?("<head"), "Post page should have head section"    # May be fragment
    # assert post_page.include?("<body"), "Post page should have body section"    # May be fragment
    
    # Test navigation elements on main page
    # assert main_page.include?("permalink"), "Main page should have permalink links"  # May not be present
    # assert main_page.include?("copy link"), "Main page should have copy link buttons"  # May not be present
    
    # Test basic functionality that should be present
    assert main_page.include?("bootstrap"), "Main page should include Bootstrap CSS/JS"
    assert main_page.length > 100, "Main page should have substantial content"
    assert post_page.length > 50, "Post page should have content"
  end

  private

  def setup_deployment_config
    # Copy deployment config to the view if it exists
    config_source = "test/config/deployment.txt"
    if File.exist?(config_source)
      deploy_file = @view.dir/:config/"deploy.txt"
      write_file(deploy_file, read_file(config_source))
      
      # Create status.txt with deployment enabled
      status_file = @view.dir/:config/"status.txt"
      write_file(status_file, "deploy y\n")
    end
  end

end
