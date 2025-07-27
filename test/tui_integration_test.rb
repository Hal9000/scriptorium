#!/usr/bin/env ruby

require 'open3'
require 'tmpdir'
require 'fileutils'
require 'timeout'
require 'test/unit'
require_relative '../lib/scriptorium'
require_relative 'test_helpers'

class TUIIntegrationTest < Test::Unit::TestCase
  include TestHelpers
  
  def setup
    @test_repo_path = "test/tui-test-repo"
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def test_basic_tui_interaction
    # Test TUI interaction with existing scriptorium-TEST repo
    commands = [
      "h\n",
      "lsv\n", 
      "cv sample\n",
      "view\n",
      "v\n",
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    assert_match(/Available commands:/, output)
    assert_match(/Scriptorium/, output)
    assert_match(/sample/, output)  # Should show sample view
  end

  def test_view_management
    commands = [
      "lsv\n",  # List views
      "cv sample\n",  # Change to sample view
      "view\n",  # Show current view
      "create view testview123 This is just a test...\n",  # Create new view
      "cv testview123\n",  # Change to new view
      "view\n",  # Show current view
      "cv nonexistent\n",  # Try to change to non-existent view
      "q\n"  # Quit
    ]
    
    output = run_tui_commands(commands)
    
    # Check that views are listed
    assert_match(/sample/, output)
    assert_match(/testview123/, output)
    assert_match(/Current view: sample/, output)
    assert_match(/Current view: testview123/, output)
    assert_match(/Cannot lookup view: nonexistent/, output)
  end

  def test_command_abbreviations
    commands = [
      "h\n",
      "v\n",
      "lsv\n",
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    assert_match(/Available commands:/, output)
    assert_match(/Scriptorium/, output)
    assert_match(/sample/, output)  # Should show sample view
  end

  def test_interactive_create_view
    # Delete existing scriptorium-TEST if it exists
    if Dir.exist?("scriptorium-TEST")
      FileUtils.rm_rf("scriptorium-TEST")
    end
    
    # Create test repo
    api = Scriptorium::API.new("scriptorium-TEST")
    api.create_view("existing", "Existing View", "An existing view")
    
    # Test fully interactive create view (no arguments)
    commands = [
      "create view\n",  # Start interactive create view
      "interactiveview\n",  # Enter view name
      "Interactive View\n",  # Enter view title
      "Interactive Subtitle\n",  # Enter subtitle
      "lsv\n",  # List views to verify
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Verify the interactive prompts appeared
    assert_match(/Enter view name:/, output)
    assert_match(/Enter view title:/, output)
    assert_match(/Enter subtitle \(optional\):/, output)
    
    # Verify the view was created
    assert_match(/Created view 'interactiveview'/, output)
    assert_match(/interactiveview.*Interactive View/, output)
    
    # Test legacy create view (with arguments)
    commands = [
      "create view legacyview Legacy View\n",  # Create with arguments
      "Legacy Subtitle\n",  # Enter subtitle
      "lsv\n",  # List views to verify
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Verify only subtitle was prompted
    assert_match(/Enter subtitle \(optional\):/, output)
    refute_match(/Enter view name:/, output)
    refute_match(/Enter view title:/, output)
    
    # Verify the view was created
    assert_match(/Created view 'legacyview'/, output)
    assert_match(/legacyview.*Legacy View/, output)
  end

  def test_list_posts_and_drafts
    # Delete existing scriptorium-TEST if it exists
    if Dir.exist?("scriptorium-TEST")
      FileUtils.rm_rf("scriptorium-TEST")
    end
    
    # Create test repo and four views: empty, alpha, beta, gamma
    api = Scriptorium::API.new("scriptorium-TEST")
    
    api.create_view("empty", "Empty View", "A view with no content")
    api.create_view("alpha", "Alpha View", "First content view")
    api.create_view("beta", "Beta View", "Second content view") 
    api.create_view("gamma", "Gamma View", "Third content view")
    
    # Test lsd - should show no drafts initially
    commands = [
      "lsd\n",  # List drafts
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Verify there are no drafts
    assert_match(/No drafts found/, output)
    
    # Create 2 drafts
    api.draft(title: "First Draft", body: "Content of first draft")
    api.draft(title: "Second Draft", body: "Content of second draft")
    
    # Test lsd again - should show 2 drafts
    commands = [
      "lsd\n",  # List drafts
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Verify there are 2 drafts
    assert_match(/Drafts:/, output)
    assert_match(/\d{8}-\d{6}-draft\.lt3/, output)  # Should match draft filename pattern
    
    # Create 28 posts with specific view distributions
    post_distributions = [
      ["alpha"],                    # 1
      ["alpha"],                    # 2
      ["gamma"],                    # 3
      ["alpha", "gamma"],           # 4
      ["beta", "gamma"],            # 5
      ["beta"],                     # 6
      ["gamma"],                    # 7
      ["beta"],                     # 8
      ["gamma"],                    # 9
      ["beta"],                     # 10
      ["beta", "gamma"],            # 11
      ["beta"],                     # 12
      ["gamma"],                    # 13
      ["alpha", "beta"],            # 14
      ["alpha"],                    # 15
      ["alpha"],                    # 16
      ["beta", "gamma"],            # 17
      ["gamma"],                    # 18
      ["alpha", "beta", "gamma"],   # 19
      ["beta"],                     # 20
      ["alpha", "beta"],            # 21
      ["beta", "gamma"],            # 22
      ["alpha"],                    # 23
      ["beta"],                     # 24
      ["alpha", "gamma"],           # 25
      ["alpha"],                    # 26
      ["alpha", "beta"],            # 27
      ["alpha"]                     # 28
    ]
    
    post_distributions.each_with_index do |views, index|
      post_number = index + 1
      api.create_post("Post number #{post_number}", "Content for post #{post_number}", views: views)
    end
    
    # Test lsp for alpha view
    commands = [
      "cv alpha\n",  # Change to alpha view
      "lsp\n",       # List posts
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Check that all expected alpha posts are present
    alpha_posts = ["Post number 1", "Post number 2", "Post number 4", "Post number 14", 
                   "Post number 15", "Post number 16", "Post number 19", "Post number 21", 
                   "Post number 23", "Post number 25", "Post number 26", "Post number 27", "Post number 28"]
    assert_present(output, *alpha_posts)
    
    # Test lsp for beta view
    commands = [
      "cv beta\n",   # Change to beta view
      "lsp\n",       # List posts
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Check that all expected beta posts are present
    beta_posts = ["Post number 5", "Post number 6", "Post number 8", "Post number 10", 
                  "Post number 11", "Post number 12", "Post number 14", "Post number 17", 
                  "Post number 19", "Post number 20", "Post number 21", "Post number 22", 
                  "Post number 24", "Post number 27"]
    assert_present(output, *beta_posts)
    
    # Test lsp for gamma view
    commands = [
      "cv gamma\n",  # Change to gamma view
      "lsp\n",       # List posts
      "q\n"
    ]
    
    output = run_tui_commands(commands)
    
    # Check that all expected gamma posts are present
    gamma_posts = ["Post number 3", "Post number 4", "Post number 5", "Post number 7", 
                   "Post number 9", "Post number 11", "Post number 13", "Post number 17", 
                   "Post number 18", "Post number 19", "Post number 22", "Post number 25"]
    assert_present(output, *gamma_posts)
  end

  private

  def run_tui_commands(commands, cwd: nil)
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    
    # Prepare input string
    input = commands.join("")
    
    # Use the rbenv Ruby version
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    # Add timeout to prevent hanging
    Timeout.timeout(30) do
      stdout, stderr, status = Open3.capture3(
        "#{ruby_path} #{script_path}",
        stdin_data: input
      )
      return stdout + stderr
    end
  rescue Timeout::Error
    return "TIMEOUT: TUI test took longer than 30 seconds"
  end

  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
    
    # Also clean up views created in the main test repo
    main_test_repo = "scriptorium-TEST"
    if Dir.exist?(main_test_repo)
      views_dir = "#{main_test_repo}/views"
      if Dir.exist?(views_dir)
        # Remove test views (keep sample view)
        Dir.entries(views_dir).each do |entry|
          next if entry == "." || entry == ".." || entry == "sample"
          # Remove test views that start with "testview" or "uniqueview"
          if entry.start_with?("testview") || entry.start_with?("uniqueview") || entry.start_with?("myview")
            FileUtils.rm_rf("#{views_dir}/#{entry}")
          end
        end
      end
    end
  end
end 