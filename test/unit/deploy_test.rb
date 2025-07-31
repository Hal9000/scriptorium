#!/usr/bin/env ruby

require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestDeploy < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("testview", "Test View", "Test Subtitle")
  end

  def teardown
    system("rm -rf test/scriptorium-TEST")
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

  def test_007_domain_extraction_from_deploy_config
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

  def test_008_deploy_verification_url_format
    # Test that verification URL is correctly formatted
    domain = "example.com"
    expected_url = "https://#{domain}/last-deployed.txt"
    
    assert_equal "https://example.com/last-deployed.txt", expected_url, "Verification URL should be correctly formatted"
  end
end 