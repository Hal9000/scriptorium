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
    expected_path = @repo.root/:config/"reddit_credentials.json"
    assert_equal expected_path, reddit.instance_variable_get(:@credentials_file)
  end

  def test_003_reddit_not_configured_when_no_credentials
    reddit = Scriptorium::Reddit.new(@repo)
    assert_equal false, reddit.configured?
  end

  def test_004_reddit_configured_when_credentials_exist
    # Create a mock credentials file
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test", "client_secret": "test"}')
    
    reddit = Scriptorium::Reddit.new(@repo)
    assert_equal true, reddit.configured?
  end

  def test_005_reddit_config_returns_nil_when_not_configured
    reddit = Scriptorium::Reddit.new(@repo)
    assert_nil reddit.config
  end

  def test_006_reddit_config_returns_parsed_json_when_configured
    # Create a valid credentials file
    credentials_data = {
      "client_id" => "test_id",
      "client_secret" => "test_secret",
      "username" => "test_user",
      "password" => "test_pass",
      "user_agent" => "test_agent"
    }
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, JSON.generate(credentials_data))
    
    reddit = Scriptorium::Reddit.new(@repo)
    config = reddit.config
    
    assert_instance_of Hash, config
    assert_equal "test_id", config["client_id"]
    assert_equal "test_secret", config["client_secret"]
  end

  def test_007_reddit_config_handles_invalid_json
    # Create an invalid JSON file
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, "invalid json content")
    
    reddit = Scriptorium::Reddit.new(@repo)
    config = reddit.config
    
    assert_nil config
  end

  def test_008_repo_reddit_method_returns_reddit_instance
    reddit_instance = @repo.reddit
    assert_instance_of Scriptorium::Reddit, reddit_instance
  end

  def test_009_repo_reddit_method_caches_instance
    reddit1 = @repo.reddit
    reddit2 = @repo.reddit
    assert_same reddit1, reddit2
  end

  def test_010_repo_reddit_configured_method
    assert_equal false, @repo.reddit_configured?
    
    # Create credentials file
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test"}')
    
    assert_equal true, @repo.reddit_configured?
  end

  def test_011_autopost_requires_credentials_file
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content"
    }
    
    assert_raises do
      reddit.autopost(post_data)
    end
  end

  def test_012_autopost_returns_false_when_config_invalid
    # Create credentials file with missing required fields
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, '{"client_id": "test"}') # Missing required fields
    
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test"
    }
    
    result = reddit.autopost(post_data)
    assert_equal false, result
  end

  def test_013_autopost_returns_false_when_no_subreddit_specified
    # Create valid credentials file
    credentials_data = {
      "client_id" => "test_id",
      "client_secret" => "test_secret",
      "username" => "test_user",
      "password" => "test_pass",
      "user_agent" => "test_agent"
    }
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, JSON.generate(credentials_data))
    
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test"
    }
    
    result = reddit.autopost(post_data)
    assert_equal false, result
  end

  def test_014_autopost_uses_subreddit_from_post_data
    # Create valid credentials file
    credentials_data = {
      "client_id" => "test_id",
      "client_secret" => "test_secret",
      "username" => "test_user",
      "password" => "test_pass",
      "user_agent" => "test_agent"
    }
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, JSON.generate(credentials_data))
    
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test",
      subreddit: "testsubreddit"
    }
    
    # Mock the Redd session to avoid actual API calls
    mock_session = Minitest::Mock.new
    mock_subreddit = Minitest::Mock.new
    mock_submission = Minitest::Mock.new
    
    # Stub the submit method to return the mock submission
    def mock_subreddit.submit(*args, **kwargs)
      Minitest::Mock.new
    end
    mock_session.expect :subreddit, mock_subreddit, ["testsubreddit"]
    
    reddit.stub :create_reddit_session, mock_session do
      result = reddit.autopost(post_data)
      assert_equal true, result
    end
    
    mock_session.verify
  end

  def test_015_autopost_uses_default_subreddit_when_available
    # Create valid credentials file with default subreddit
    credentials_data = {
      "client_id" => "test_id",
      "client_secret" => "test_secret",
      "username" => "test_user",
      "password" => "test_pass",
      "user_agent" => "test_agent",
      "default_subreddit" => "defaultsubreddit"
    }
    credentials_file = @repo.root/:config/"reddit_credentials.json"
    write_file(credentials_file, JSON.generate(credentials_data))
    
    reddit = Scriptorium::Reddit.new(@repo)
    
    post_data = {
      title: "Test Post",
      url: "https://example.com/test"
    }
    
    # Mock the Redd session to avoid actual API calls
    mock_session = Minitest::Mock.new
    mock_subreddit = Minitest::Mock.new
    mock_submission = Minitest::Mock.new
    
    # Stub the submit method to return the mock submission
    def mock_subreddit.submit(*args, **kwargs)
      Minitest::Mock.new
    end
    mock_session.expect :subreddit, mock_subreddit, ["defaultsubreddit"]
    
    reddit.stub :create_reddit_session, mock_session do
      result = reddit.autopost(post_data)
      assert_equal true, result
    end
    
    mock_session.verify
  end
end 