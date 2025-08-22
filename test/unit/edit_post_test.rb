require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestEditPost < Minitest::Test
  include TestHelpers
  
  def setup
    @test_dir = "test/scriptorium-TEST"
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    
    @api = Scriptorium::API.new(testmode: true)
    @api.create_repo(@test_dir)
    @api.open_repo(@test_dir)
  end
  
  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end
  
  def test_001_edit_post_no_changes
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially unpublished and undeployed
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
    
    # Mock the editor by not changing the file content
    # (file content remains the same, so checksum will be identical)
    
    # Call edit_post with mock (should detect no changes)
    @api.edit_post(post.id, mock: true)
    
    # State should remain unchanged
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
  end
  
  def test_002_edit_post_with_changes
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially unpublished and undeployed
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
    
    # Mock the editor by simulating a different checksum
    @api.edit_post(post.id, mock: [:checksum, "different_checksum_for_testing"])
    
    # State should remain unchanged since it was already unpublished/undeployed
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
  end
  
  def test_003_edit_post_published_post
    @api.create_view("test_view", "Test View")
    @api.repo.instance_variable_set(:@current_view, @api.repo.lookup_view("test_view"))
    
    post = @api.create_post("Test Post", "Test body")
    
    # Publish the post
    @api.publish_post(post.id)
    assert @api.post_published?(post.id)
    
    # Mock the editor by simulating a different checksum
    @api.edit_post(post.id, mock: [:checksum, "different_checksum_for_testing"])
    
    # Post should now be unpublished
    refute @api.post_published?(post.id)
  end
  
  def test_004_edit_post_deployed_post
    @api.create_view("test_view", "Test View")
    @api.repo.instance_variable_set(:@current_view, @api.repo.lookup_view("test_view"))
    
    post = @api.create_post("Test Post", "Test body")
    
    # Publish and deploy the post
    @api.publish_post(post.id)
    @api.mark_post_deployed(post.id)
    assert @api.post_published?(post.id)
    assert @api.post_deployed?(post.id)
    
    # Mock the editor by simulating a different checksum
    @api.edit_post(post.id, mock: [:checksum, "different_checksum_for_testing"])
    
    # Post should now be unpublished and undeployed
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
  end
  
  def test_005_edit_post_multiple_views
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    post = @api.create_post("Test Post", "Test body", views: "test_view other_view")
    
    # Publish in both views
    @api.publish_post(post.id, "test_view")
    @api.publish_post(post.id, "other_view")
    @api.mark_post_deployed(post.id, "test_view")
    @api.mark_post_deployed(post.id, "other_view")
    
    assert @api.post_published?(post.id, "test_view")
    assert @api.post_published?(post.id, "other_view")
    assert @api.post_deployed?(post.id, "test_view")
    assert @api.post_deployed?(post.id, "other_view")
    
    # Mock the editor by simulating a different checksum
    @api.edit_post(post.id, mock: [:checksum, "different_checksum_for_testing"])
    
    # Post should now be unpublished and undeployed in both views
    
    refute @api.post_published?(post.id, "test_view")
    refute @api.post_published?(post.id, "other_view")
    refute @api.post_deployed?(post.id, "test_view")
    refute @api.post_deployed?(post.id, "other_view")
  end
  
  def test_006_edit_post_timestamp_change_only
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially unpublished and undeployed
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
    
    # Mock the editor by simulating no content changes (same checksum)
    @api.edit_post(post.id, mock: [:checksum, Digest::MD5.file("#{@test_dir}/posts/#{post.num}/source.lt3").hexdigest])
    
    # State should remain unchanged since content didn't change
    refute @api.post_published?(post.id)
    refute @api.post_deployed?(post.id)
  end
  
  def test_007_edit_post_missing_source
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Remove source.lt3 to test error handling
    source_path = "#{@test_dir}/posts/#{post.num}/source.lt3"
    File.delete(source_path) if File.exist?(source_path)
    
    # Ensure body.html exists
    body_path = "#{@test_dir}/posts/#{post.num}/body.html"
    assert File.exist?(body_path)
    
    # Call edit_post should raise error since source.lt3 is missing
    assert_raises(RuntimeError) do
      @api.edit_post(post.id, mock: true)
    end
  end
  
  def test_008_edit_post_deleted_post
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Delete the post
    @api.delete_post(post.id)
    assert @api.post_deleted?(post.id)
    
    # Try to edit deleted post
    assert_raises(PostDeleted) do
      @api.edit_post(post.id, mock: true)
    end
  end
end
