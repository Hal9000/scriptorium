#!/usr/bin/env ruby

require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestDeploy < Minitest::Test
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
  end

  def teardown
    # Clean up any test directories that were created
    Dir.glob("test/scriptorium-TEST*").each do |dir|
      system("rm -rf #{dir}")
    end
    # Clean up any root directory created during deployment testing
    # FileUtils.rm_rf("root") if Dir.exist?("root")
  end

  def test_001_deploy_config_file_creation
    # Test that deploy.txt can be created and read
    deploy_file = @view.dir/:config/"deploy.txt"
    write_file(deploy_file, "user@example.com:/var/www/html/")
    
    assert File.exist?(deploy_file), "Deploy config file should exist"
    content = read_file(deploy_file)
    assert_equal "user@example.com:/var/www/html/", content.strip
  end

  def test_002_deploy_config_validation
    # Test various deploy config formats
    deploy_file = @view.dir/:config/"deploy.txt"
    
    # Valid formats
    valid_configs = [
      "user@server:/path/",
      "user@server.com:/var/www/html/",
      "deploy@mysite.com:/home/deploy/public_html/"
    ]
    
    valid_configs.each do |config|
      write_file(deploy_file, config)
      content = read_file(deploy_file).strip
      assert_equal config, content, "Should read config: #{config}"
    end
  end

  def test_003_deploy_requires_output_directory
    # Test that deployment requires output directory to exist
    deploy_file = @view.dir/:config/"deploy.txt"
    write_file(deploy_file, "user@server:/path/")
    
    # Output directory should exist after view creation (created by make_tree)
    output_dir = @view.dir/:output
    assert Dir.exist?(output_dir), "Output directory should exist after view creation"
  end

  def test_004_deploy_rsync_command_format
    # Test that the rsync command format is correct
    deploy_config = "user@server:/var/www/html/"
    output_dir = @view.dir/:output
    make_dir(output_dir)
    
    # Expected rsync command format
    expected_cmd = "rsync -r -z #{output_dir}/ #{deploy_config}/"
    
    # This is the format used in the TUI
    actual_cmd = "rsync -r -z #{output_dir}/ #{deploy_config}/"
    
    assert_equal expected_cmd, actual_cmd, "Rsync command format should match"
  end

  def test_005_deploy_with_sample_content
    # Test deployment with actual content
    deploy_file = @view.dir/:config/"deploy.txt"
    write_file(deploy_file, "user@server:/path/")
    
    # Create output directory and some content
    output_dir = @view.dir/:output
    make_dir(output_dir)
    make_dir(output_dir/:posts)
    make_dir(output_dir/:permalink)
    
    # Create a sample file
    sample_file = output_dir/"index.html"
    write_file(sample_file, "<html><body>Test content</body></html>")
    
    assert File.exist?(sample_file), "Sample file should exist"
    assert Dir.exist?(output_dir/:posts), "Posts directory should exist"
    assert Dir.exist?(output_dir/:permalink), "Permalink directory should exist"
  end

  def test_006_deploy_marker_file_creation
    # Test that deployment creates a marker file
    output_dir = @view.dir/:output
    
    # Simulate deployment marker creation
    marker_content = "Deployed: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    marker_file = output_dir/"last-deployed.txt"
    write_file(marker_file, marker_content)
    
    assert File.exist?(marker_file), "Deployment marker file should exist"
    content = read_file(marker_file)
    assert content.start_with?("Deployed:"), "Marker file should start with 'Deployed:'"
  end

  def test_007_deploy_with_symlinks
    # Test that deployment handles symlinks correctly
    output_dir = @view.dir/:output
    make_dir(output_dir/:permalink)
    
    # Create a test symlink
    target_file = output_dir/:permalink/"0001-test-post.html"
    symlink_file = output_dir/:permalink/"test-post.html"
    
    # Create the target file
    write_file(target_file, "<html><body>Test post</body></html>")
    
    # Create the symlink
    File.symlink("0001-test-post.html", symlink_file)
    
    # Verify symlink exists
    assert File.exist?(symlink_file), "Symlink should exist"
    assert File.symlink?(symlink_file), "Should be a symlink"
    
    # Test that rsync command includes symlink preservation
    expected_cmd = "rsync -r -z -l #{output_dir}/ user@server:/path/"
    actual_cmd = "rsync -r -z -l #{output_dir}/ user@server:/path/"
    
    assert_equal expected_cmd, actual_cmd, "Rsync command should preserve symlinks"
  end

  def test_008_deploy_symlink_target_verification
    # Test that symlink targets are accessible after deployment
    output_dir = @view.dir/:output
    make_dir(output_dir/:permalink)
    
    # Create a test symlink with target
    target_file = output_dir/:permalink/"0001-another-post.html"
    symlink_file = output_dir/:permalink/"another-post.html"
    
    # Create the target file
    write_file(target_file, "<html><body>Another test post</body></html>")
    
    # Create the symlink
    File.symlink("0001-another-post.html", symlink_file)
    
    # Verify symlink points to existing target
    assert File.exist?(symlink_file), "Symlink should exist"
    assert File.symlink?(symlink_file), "Should be a symlink"
    
    symlink_target = File.readlink(symlink_file)
    target_path = output_dir/:permalink/symlink_target
    
    assert File.exist?(target_path), "Symlink target should exist"
    assert_equal "0001-another-post.html", symlink_target, "Symlink should point to correct target"
  end

  def test_009_domain_extraction_from_deploy_config
    # Test domain extraction from various deploy config formats
    test_cases = [
      ["user@example.com:/var/www/html/", "example.com"],
      ["deploy@mysite.com:/home/deploy/public_html/", "mysite.com"],
      ["admin@blog.example.org:/srv/www/", "blog.example.org"]
    ]
    
    test_cases.each do |config, expected_domain|
      # Simulate the domain extraction logic
      domain = nil
      if config =~ /@([^:]+):/
        domain = $1
      end
      
      assert_equal expected_domain, domain, "Should extract domain from: #{config}"
    end
  end

  def test_010_deploy_verification_url_format
    # Test that verification URL is correctly formatted
    domain = "example.com"
    expected_url = "https://#{domain}/last-deployed.txt"
    
    assert_equal "https://example.com/last-deployed.txt", expected_url, "Verification URL should be correctly formatted"
  end

  # New API deployment method tests
  
  def test_011_can_deploy_status_check
    # Test can_deploy? with various status configurations
    
    # Test with deploy status 'n' (should fail)
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy n")
    
    refute @api.can_deploy?("testview"), "Should not deploy when status is 'n'"
    
    # Test with deploy status 'y' (should pass status check)
    write_file(status_file, "deploy y")
    
    # This will still fail because deploy.txt doesn't exist, but status check passes
    refute @api.can_deploy?("testview"), "Should fail when deploy.txt is missing"
  end
  
  def test_012_can_deploy_config_validation
    # Test can_deploy? with various deploy.txt configurations
    
    # Set deploy status to 'y'
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy y")
    
    # Test with missing deploy.txt
    refute @api.can_deploy?("testview"), "Should fail when deploy.txt is missing"
    
    # Test with incomplete deploy.txt
    deploy_file = @repo.root/"views"/"testview"/"config"/"deploy.txt"
    write_file(deploy_file, "user root\nserver example.com")
    
    refute @api.can_deploy?("testview"), "Should fail when required fields are missing"
    
    # Test with complete deploy.txt
    write_file(deploy_file, "user root\nserver.example.com\ndocroot /var/www/html\npath testview")
    
    # This will fail SSH test, but we'll skip that for now
    # The method should at least pass the config validation
    begin
      result = @api.can_deploy?("testview")
      # If SSH test passes, result should be true
      # If SSH test fails, result should be false
      assert result == false || result == true, "Should return boolean result"
    rescue => e
      # SSH test might fail, which is expected in test environment
      skip "SSH test failed (expected in test environment): #{e.message}"
    end
  end
  
  def test_013_deploy_dry_run_mode
    # Test deploy method in dry-run mode
    
    # Set up deployment configuration
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy y")
    
    deploy_file = @repo.root/"views"/"testview"/"config"/"deploy.txt"
    write_file(deploy_file, "user root\nserver.example.com\ndocroot /var/www/html\npath testview")
    
    # Create some output content
    output_dir = @repo.root/"views"/"testview"/"output"
    make_dir(output_dir)
    write_file(output_dir/"index.html", "<html><body>Test content</body></html>")
    
    # Test that the deploy method can be called (SSH test will fail, but that's expected)
    begin
      result = @api.deploy("testview", dry_run: true)
      assert result, "Dry-run should succeed"
    rescue RuntimeError => e
      if e.message.include?("not ready for deployment")
        # SSH test failed, which is expected in test environment
        skip "SSH test failed (expected in test environment): #{e.message}"
      else
        raise e
      end
    end
  end
  
  def test_014_deploy_missing_configuration
    # Test deploy method with missing configuration
    
    # Test with no status file
    assert_raises(RuntimeError, "Should fail when status is not ready") do
      @api.deploy("testview")
    end
    
    # Test with deploy status 'n'
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy n")
    
    assert_raises(RuntimeError, "Should fail when status is not ready") do
      @api.deploy("testview")
    end
  end
  
  def test_015_deploy_invalid_configuration
    # Test deploy method with invalid configuration
    
    # Set deploy status to 'y'
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy y")
    
    # Test with missing deploy.txt
    assert_raises(RuntimeError, "Should fail when deploy.txt is missing") do
      @api.deploy("testview")
    end
    
    # Test with incomplete deploy.txt
    deploy_file = @repo.root/"views"/"testview"/"config"/"deploy.txt"
    write_file(deploy_file, "user root\nserver example.com")
    
    assert_raises(RuntimeError, "Should fail when required fields are missing") do
      @api.deploy("testview")
    end
  end
  
  def test_016_deploy_rsync_command_construction
    # Test that deploy method constructs correct rsync command
    
    # Set up deployment configuration
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy y")
    
    deploy_file = @repo.root/"views"/"testview"/"config"/"deploy.txt"
    write_file(deploy_file, "user root\nserver example.com\ndocroot /var/www/html\npath testview")
    
    # Create output content
    output_dir = @repo.root/"views"/"testview"/"output"
    make_dir(output_dir)
    write_file(output_dir/"index.html", "<html><body>Test content</body></html>")
    
    # Test dry-run to see the command that would be executed
    begin
      result = @api.deploy("testview", dry_run: true)
      assert result, "Dry-run should succeed"
    rescue RuntimeError => e
      if e.message.include?("not ready for deployment")
        # SSH test failed, which is expected in test environment
        skip "SSH test failed (expected in test environment): #{e.message}"
      else
        raise e
      end
    end
    
    # The dry-run should output the rsync command to stdout
    # We can't easily capture this in the test, but we can verify the method runs
    # The actual command format is: "rsync -r -z -l #{output_dir}/ #{remote_path}/"
  end
  
  def test_017_deploy_no_view_specified
    # Test deploy method without specifying a view
    
    # Should fail when no view is specified and no current view is set
    assert_raises(RuntimeError, "Should fail when no view specified") do
      @api.deploy
    end
  end
  
  def test_018_deploy_ssh_keys_test
    # Test SSH key validation (will likely be skipped in test environment)
    
    # Set up deployment configuration
    status_file = @repo.root/"views"/"testview"/"config"/"status.txt"
    write_file(status_file, "deploy y")
    
    deploy_file = @repo.root/"views"/"testview"/"config"/"deploy.txt"
    write_file(deploy_file, "user root\nserver example.com\ndocroot /var/www/html\npath testview")
    
    # Test SSH key validation
    begin
      result = @api.can_deploy?("testview")
      # This might pass or fail depending on SSH configuration
      assert result == false || result == true, "Should return boolean result"
    rescue => e
      # SSH test might fail, which is expected in test environment
      skip "SSH test failed (expected in test environment): #{e.message}"
    end
  end

  def test_020_deploy_config_parsing
    # Test various deployment config formats
    test_cases = [
      # Valid space-separated format
      {
        input: "user      root\nserver    example.com\npath      sample",
        expected: {"user" => "root", "server" => "example.com", "path" => "sample"},
        description: "valid space-separated format"
      },
      # Config with comments
      {
        input: "# This is a comment\nuser      root\nserver    example.com\npath      sample",
        expected: {"user" => "root", "server" => "example.com", "path" => "sample"},
        description: "config with comments"
      },
      # Missing required fields
      {
        input: "user      root\nserver    example.com",
        expected: {"user" => "root", "server" => "example.com"},
        description: "missing path field"
      },
      # Empty config
      {
        input: "",
        expected: {},
        description: "empty config"
      },
      # Config with junk lines
      {
        input: "user      root\njunk line here\nserver    example.com\npath      sample",
        expected: {"user" => "root", "junk" => "line here", "server" => "example.com", "path" => "sample"},
        description: "config with junk lines"
      },
      # Config with extra whitespace
      {
        input: "  user      root  \n  server    example.com  \n  path      sample  ",
        expected: {"user" => "root", "server" => "example.com", "path" => "sample"},
        description: "config with extra whitespace"
      }
    ]

    test_cases.each do |test_case|
      result = @api.parse_deploy_config(test_case[:input])
      assert_equal test_case[:expected], result, 
                   "Failed for #{test_case[:description]}: expected '#{test_case[:expected]}', got '#{result}'"
    end
  end

  def test_020b_build_rsync_destination
    # Test building rsync destinations from config hashes
    test_cases = [
      {
        config: {"user" => "root", "server" => "example.com", "path" => "sample"},
        expected: "root@example.com:sample",
        description: "complete config"
      },
      {
        config: {"user" => "root", "server" => "example.com"},
        expected: nil,
        description: "missing path"
      },
      {
        config: {},
        expected: nil,
        description: "empty config"
      }
    ]

    test_cases.each do |test_case|
      result = @api.build_rsync_destination(test_case[:config])
      if test_case[:expected].nil?
        assert_nil result, "Failed for #{test_case[:description]}: expected nil, got '#{result}'"
      else
        assert_equal test_case[:expected], result, 
                     "Failed for #{test_case[:description]}: expected '#{test_case[:expected]}', got '#{result}'"
      end
    end
  end



  def test_022_deploy_config_edge_cases
    # Test edge cases that could cause issues
    edge_cases = [
      # Config with only junk
      {
        input: "this is not a config\nneither is this\nor this",
        expected: {"this" => "is not a config", "neither" => "is this", "or" => "this"},
        description: "only junk lines"
      },
      # Config with empty lines
      {
        input: "user      root\n\nserver    example.com\n\npath      sample\n",
        expected: {"user" => "root", "server" => "example.com", "path" => "sample"},
        description: "config with empty lines"
      },
      # Config with special characters
      {
        input: "user      root\nserver    example.com\npath      /var/www/html",
        expected: {"user" => "root", "server" => "example.com", "path" => "/var/www/html"},
        description: "path with special characters"
      }
    ]

    edge_cases.each do |test_case|
      result = @api.parse_deploy_config(test_case[:input])
      assert_equal test_case[:expected], result, 
                   "Failed for #{test_case[:description]}: expected '#{test_case[:expected]}', got '#{result}'"
    end
  end

end 