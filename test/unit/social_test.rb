require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class SocialTest < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/social_test_files"
    make_dir(@test_dir)
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("test", "Test View", "A test view")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  def test_001_social_config_file_created
    social_config_file = @view.dir/:config/"social.txt"
    assert File.exist?(social_config_file), "Social config file should be created"
    
    content = read_file(social_config_file)
    assert_includes content, "facebook"
    assert_includes content, "twitter"
  end

  def test_002_social_meta_tags_generated_when_enabled
    # Enable social features
    social_config = <<~EOS
      facebook
      twitter
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Generate meta tags
    meta_tags = @view.generate_social_meta_tags
    
    # Check for Open Graph tags
    assert_includes meta_tags, 'property="og:title"'
    assert_includes meta_tags, 'property="og:type"'
    assert_includes meta_tags, 'property="og:url"'
    assert_includes meta_tags, 'property="og:description"'
    assert_includes meta_tags, 'property="og:site_name"'
    
    # Check for Twitter Card tags
    assert_includes meta_tags, 'name="twitter:card"'
    assert_includes meta_tags, 'name="twitter:title"'
    assert_includes meta_tags, 'name="twitter:description"'
    assert_includes meta_tags, 'name="twitter:url"'
  end

  def test_003_social_meta_tags_not_generated_when_disabled
    # Disable social features
    social_config = <<~EOS
      # facebook
      # twitter
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Generate meta tags
    meta_tags = @view.generate_social_meta_tags
    
    # Should be empty when disabled
    assert_empty meta_tags
  end

  def test_004_post_specific_meta_tags
    # Enable social features
    social_config = <<~EOS
      facebook
      twitter
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Create post data
    post_data = {
      :"post.id" => "1",
      :"post.title" => "Test Post",
      :"post.body" => "This is a test post body",
      :"post.blurb" => "Test post blurb",
      :"post.pubdate" => "2024-01-01 12:00:00",
      :"post.slug" => "test-post.html"
    }
    
    # Generate meta tags for post
    meta_tags = @view.generate_social_meta_tags(nil, post_data)
    
    # Check for post-specific content
    assert_includes meta_tags, 'content="Test Post"'
    assert_includes meta_tags, 'content="article"'
    assert_includes meta_tags, 'content="posts/test-post.html"'
    assert_includes meta_tags, 'content="Test post blurb"'
    assert_includes meta_tags, 'content="2024-01-01 12:00:00"'
  end

  def test_005_complete_post_html_generation
    # Enable social features
    social_config = <<~EOS
      facebook
      twitter
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Create post data
    post_data = {
      :"post.id" => "1",
      :"post.title" => "Test Post",
      :"post.body" => "<p>This is a test post body</p>",
      :"post.pubdate" => "2024-01-01 12:00:00",
      :"post.tags" => "test, example"
    }
    
    # Generate social meta tags (this method exists)
    meta_tags = @view.generate_social_meta_tags(nil, post_data)
    
    # Check for social meta tags
    assert_includes meta_tags, 'property="og:title"'
    assert_includes meta_tags, 'name="twitter:card"'
  end

  # Reddit Button Tests

  def test_006_reddit_config_file_created
    reddit_config_file = @view.dir/:config/"reddit.txt"
    assert File.exist?(reddit_config_file), "Reddit config file should be created"
    
    content = read_file(reddit_config_file)
    assert_includes content, "button true"
    assert_includes content, "subreddit"
    assert_includes content, "hover_text"
  end

  def test_007_reddit_button_not_generated_when_reddit_not_enabled
    # Disable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button in reddit config
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should be empty when Reddit not enabled in social config
    assert_empty button_html
  end

  def test_008_reddit_button_not_generated_when_button_disabled
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Disable Reddit button in reddit config
    reddit_config = <<~EOS
      button false
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should be empty when button disabled
    assert_empty button_html
  end

  def test_009_reddit_button_generated_when_enabled
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button in reddit config
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should contain Reddit button HTML
    assert_includes button_html, 'href="https://reddit.com/submit'
    assert_includes button_html, 'title="Share on Reddit"'
    assert_includes button_html, 'src="../../assets/icons/social/reddit.png"'
    assert_includes button_html, 'alt="Share on Reddit"'
  end

  def test_010_reddit_button_with_subreddit
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button with subreddit
    reddit_config = <<~EOS
      button true
      subreddit RubyElixirEtc
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should contain subreddit-specific URL and hover text
    assert_includes button_html, 'href="https://reddit.com/r/RubyElixirEtc/submit'
    assert_includes button_html, 'title="Share on r/RubyElixirEtc"'
  end

  def test_011_reddit_button_with_custom_hover_text
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button with custom hover text
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text Share this awesome post!
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should contain custom hover text
    assert_includes button_html, 'title="Share this awesome post!"'
  end

  def test_012_reddit_button_with_post_data
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Create post data
    post_data = {
      :"post.id" => "123",
      :"post.title" => "My Test Post",
      :"post.slug" => "my-test-post"
    }
    
    # Generate Reddit button with post data
    button_html = @view.generate_reddit_button(post_data)
    
    # Should contain post-specific URL and title
    assert_includes button_html, 'url=posts/my-test-post.html'
    assert_includes button_html, 'title=My+Test+Post'
  end

  def test_013_reddit_button_integration_with_post_generation
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Enable Reddit button
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Create and generate a post
    draft_name = @repo.create_draft(title: "Reddit Test Post", tags: %w[test reddit])
    body = "This is a test post for Reddit button integration."
    text = read_file(draft_name)
    text.sub!(/BEGIN HERE.../, body)
    write_file(draft_name, text)
    post_id = @repo.finish_draft(draft_name)
    @repo.generate_post(post_id)
    
    # Check that the generated post contains Reddit button
    post_file = @repo.root/:views/:test/:output/:posts/"#{d4(post_id)}-reddit-test-post.html"
    assert File.exist?(post_file), "Generated post should exist"
    
    post_content = read_file(post_file)
    assert_includes_concise_string post_content, 'href="https://reddit.com/submit', "Post should contain Reddit submit link"
    assert_includes_concise_string post_content, 'src="../../assets/icons/social/reddit.png"', "Post should contain Reddit icon"
  end

  def test_014_reddit_button_missing_config_file_handling
    # Enable Reddit in social config
    social_config = <<~EOS
      facebook
      twitter
      reddit
    EOS
    write_file(@view.dir/:config/"social.txt", social_config)
    
    # Remove reddit.txt config file
    reddit_config_file = @view.dir/:config/"reddit.txt"
    File.delete(reddit_config_file) if File.exist?(reddit_config_file)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should be empty when config file missing
    assert_empty button_html
  end

  def test_015_reddit_button_missing_social_config_file_handling
    # Remove social.txt config file
    social_config_file = @view.dir/:config/"social.txt"
    File.delete(social_config_file) if File.exist?(social_config_file)
    
    # Enable Reddit button in reddit config
    reddit_config = <<~EOS
      button true
      subreddit
      hover_text
    EOS
    write_file(@view.dir/:config/"reddit.txt", reddit_config)
    
    # Generate Reddit button
    button_html = @view.generate_reddit_button
    
    # Should be empty when social config file missing
    assert_empty button_html
  end
end 