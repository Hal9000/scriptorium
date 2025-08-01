require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class RedditTest < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/reddit_test_files"
    make_dir(@test_dir)
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("test", "Test View", "A test view")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  def test_001_reddit_class_initialization
    reddit = Scriptorium::Reddit.new(@repo)
    assert_instance_of Scriptorium::Reddit, reddit
    assert_equal @repo, reddit.instance_variable_get(:@repo)
  end

  def test_002_reddit_credentials_file_path
    reddit = Scriptorium::Reddit.new(@repo)
    expected_path = @repo.dir/:config/"reddit_credentials.json"
    assert_equal expected_path, reddit.instance_variable_get(:@credentials_file)
  end

  def test_003_reddit_python_script_path
    reddit = Scriptorium::Reddit.new(@repo)
    script_path = reddit.instance_variable_get(:@python_script)
    assert File.exist?(script_path), "Python script should exist at #{script_path}"
  end

  def test_004_reddit_not_configured_when_no_credentials
    reddit = Scriptorium::Reddit.new(@repo)
    assert_equal false, reddit.configured?
  end

  def test_005_reddit_configured_when_credentials_exist
    # Create a mock credentials file
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test", "client_secret": "test"}')
    
    reddit = Scriptorium::Reddit.new(@repo)
    assert_equal true, reddit.configured?
  end

  def test_006_reddit_config_returns_nil_when_not_configured
    reddit = Scriptorium::Reddit.new(@repo)
    assert_nil reddit.config
  end

  def test_007_reddit_config_returns_parsed_json_when_configured
    # Create a valid credentials file
    credentials_data = {
      "client_id" => "test_id",
      "client_secret" => "test_secret",
      "username" => "test_user",
      "password" => "test_pass",
      "user_agent" => "test_agent"
    }
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, JSON.generate(credentials_data))
    
    reddit = Scriptorium::Reddit.new(@repo)
    config = reddit.config
    
    assert_instance_of Hash, config
    assert_equal "test_id", config["client_id"]
    assert_equal "test_secret", config["client_secret"]
  end

  def test_008_reddit_config_handles_invalid_json
    # Create an invalid JSON file
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, "invalid json content")
    
    reddit = Scriptorium::Reddit.new(@repo)
    config = reddit.config
    
    assert_nil config
  end

  def test_009_repo_reddit_method_returns_reddit_instance
    reddit_instance = @repo.reddit
    assert_instance_of Scriptorium::Reddit, reddit_instance
  end

  def test_010_repo_reddit_method_caches_instance
    reddit1 = @repo.reddit
    reddit2 = @repo.reddit
    assert_same reddit1, reddit2
  end

  def test_011_repo_reddit_configured_method
    assert_equal false, @repo.reddit_configured?
    
    # Create credentials file
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test"}')
    
    assert_equal true, @repo.reddit_configured?
  end

  def test_012_autopost_requires_credentials_file
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content"
    }
    
    assert_raises(Scriptorium::Exceptions::FileNotFound) do
      reddit.autopost(post_data)
    end
  end

  def test_013_autopost_requires_python_script
    # Create credentials but remove Python script
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test"}')
    
    reddit = Scriptorium::Reddit.new(@repo)
    script_path = reddit.instance_variable_get(:@python_script)
    
    # Temporarily rename the script
    if File.exist?(script_path)
      File.rename(script_path, "#{script_path}.bak")
    end
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content"
    }
    
    assert_raises(Scriptorium::Exceptions::FileNotFound) do
      reddit.autopost(post_data)
    end
    
    # Restore the script
    if File.exist?("#{script_path}.bak")
      File.rename("#{script_path}.bak", script_path)
    end
  end

  def test_014_temp_file_creation_for_post_data
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post Title",
      url: "https://example.com/test",
      content: "Test content here",
      subreddit: "testsubreddit"
    }
    
    # Use reflection to test private method
    temp_file = reddit.send(:write_temp_post_data, post_data)
    
    assert File.exist?(temp_file), "Temporary file should be created"
    
    # Read and verify content
    content = JSON.parse(File.read(temp_file))
    assert_equal "Test Post Title", content["title"]
    assert_equal "https://example.com/test", content["url"]
    assert_equal "Test content here", content["content"]
    assert_equal "testsubreddit", content["subreddit"]
    
    # Clean up
    File.delete(temp_file) if File.exist?(temp_file)
  end

  def test_015_autopost_cleans_up_temp_files
    # Create credentials file
    credentials_file = @repo.dir/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test", "client_secret": "test", "username": "test", "password": "test", "user_agent": "test"}')
    
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content"
    }
    
    # Mock the system call to avoid actual Reddit API calls
    reddit.stub :system, false do
      reddit.autopost(post_data)
    end
    
    # Verify no temp files are left behind
    temp_files = Dir.glob("/tmp/reddit_post*")
    assert_empty temp_files, "Temporary files should be cleaned up"
  end
end 