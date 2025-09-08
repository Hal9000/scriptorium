#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'json'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class BackupTestFixed < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  def setup
    @test_dir = "test/scriptorium-TEST"
    # Clean up any existing test directory first
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    @api = Scriptorium::API.new(testmode: true)
    @api.create_repo(@test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    # Clean up backup directory too
    if @api
      backup_dir = @api.get_backup_directory
      FileUtils.rm_rf(backup_dir) if Dir.exist?(backup_dir)
    end
    @api = nil
  end
  
  private def count_posts_in_compressed_backup(backup_dir)
    tar_gz_path = backup_dir/"data.tar.gz"
    return 0 unless File.exist?(tar_gz_path)
    
    # Use tar -tf to list files and count posts directories
    output = `tar -tf '#{tar_gz_path}' 2>/dev/null`
    return 0 unless $?.success?
    
    # Count unique post directories (tar output has ./ prefix)
    post_dirs = output.lines.select { |line| line.strip.match(/^\.\/posts\/\d+\//) }
    post_dirs.map { |line| line.strip.split('/')[2] }.uniq.length
  end

  def test_001_create_full_backup
    # Create some test content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Test Post", "This is a test post", views: "test-view")
    
    # Create a full backup
    backup_name = @api.create_backup(type: :full, label: "test-backup")
    
    # Verify backup was created
    assert_match(/^\d{8}-\d{6}-full$/, backup_name)
    
    backup_dir = @api.get_backup_directory/"data"/backup_name
    assert Dir.exist?(backup_dir), "Backup directory should exist"
    
    # Verify compressed backup structure
    assert File.exist?(backup_dir/"data.tar.gz"), "Compressed backup data should exist"
    
    # Verify backup info file exists (uncompressed)
    assert File.exist?(backup_dir/"backup-info.txt"), "Backup info file should exist"
    
    # Verify manifest was created
    manifest_file = @api.get_backup_directory/"manifest.txt"
    assert File.exist?(manifest_file), "Backup manifest should exist"
    
    manifest_content = File.read(manifest_file)
    assert_includes manifest_content, backup_name, "Backup should be in manifest"
    assert_includes manifest_content, "test-backup", "Label should be in manifest"
    
    # Verify backup info file was created
    backup_info_file = backup_dir/"backup-info.txt"
    assert File.exist?(backup_info_file), "Backup info file should exist"
    
    info_content = File.read(backup_info_file)
    assert_includes info_content, "scriptorium_version:", "Should contain scriptorium version"
    assert_includes info_content, "livetext_version:", "Should contain livetext version"
    assert_includes info_content, "ruby_version:", "Should contain ruby version"
    assert_includes info_content, "backup_type: full", "Should contain backup type"
  end

  def test_002_create_incremental_backup
    # Create some test content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Test Post", "This is a test post", views: "test-view")
    
    # Create an incremental backup
    backup_name = @api.create_backup(type: :incremental, label: "incremental-test")
    
    # Verify backup was created
    assert_match(/^\d{8}-\d{6}-incr$/, backup_name)
    
    backup_dir = @api.get_backup_directory/"data"/backup_name
    assert Dir.exist?(backup_dir), "Backup directory should exist"
    
    # Verify compressed backup structure
    assert File.exist?(backup_dir/"data.tar.gz"), "Compressed backup data should exist"
    
    # Verify manifest was created
    manifest_file = @api.get_backup_directory/"manifest.txt"
    assert File.exist?(manifest_file), "Backup manifest should exist"
    
    manifest_content = File.read(manifest_file)
    assert_includes manifest_content, backup_name, "Backup should be in manifest"
    assert_includes manifest_content, "incremental-test", "Label should be in manifest"
    
    # Verify backup info file was created
    backup_info_file = backup_dir/"backup-info.txt"
    assert File.exist?(backup_info_file), "Backup info file should exist"
    
    info_content = File.read(backup_info_file)
    assert_includes info_content, "scriptorium_version:", "Should contain scriptorium version"
    assert_includes info_content, "livetext_version:", "Should contain livetext version"
    assert_includes info_content, "ruby_version:", "Should contain ruby version"
    assert_includes info_content, "backup_type: incremental", "Should contain backup type"
  end

  def test_003_list_backups
    # Create multiple backups
    backup1 = @api.create_backup(type: :full, label: "first")
    sleep(1) # Ensure different timestamps
    backup2 = @api.create_backup(type: :incremental, label: "second")
    
    # List backups
    backups = @api.list_backups
    
    assert_equal 2, backups.length, "Should have 2 backups"
    
    # Should be sorted by creation time, newest first
    assert_equal backup2, backups[0][:name], "Newest backup should be first"
    assert_equal backup1, backups[1][:name], "Older backup should be second"
    
    # Verify backup info
    backup_info = backups[0]
    assert_equal backup2, backup_info[:name]
    assert_equal :incremental, backup_info[:type]
    assert_equal "second", backup_info[:description]
    assert backup_info[:timestamp].is_a?(Time)
    assert backup_info[:size].is_a?(Integer)
    assert backup_info[:file_count].is_a?(Integer)
  end

  def test_004_restore_backup_safe_strategy
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Modify content
    @api.create_post("New Post", "New content", views: "test-view")
    
    # Restore from backup using safe strategy (default)
    result = @api.restore_backup(backup_name, strategy: :safe)
    assert result.is_a?(Hash), "Restore should return a hash"
    assert_equal backup_name, result[:restored], "Should return the restored backup name"
    assert result[:pre_restore], "Should have created a pre-restore backup"
    
    # Verify content was restored
    posts = @api.posts("test-view")
    assert_equal 1, posts.length, "Should have only 1 post after restore"
    assert_equal "Original Post", posts[0].title, "Should have original post"
    
    # Verify pre-restore backup was created
    backups = @api.list_backups
    pre_restore = backups.find { |b| b[:description]&.include?("pre-restore") }
    assert pre_restore, "Should have created a pre-restore backup"
  end

  def test_004b_restore_backup_destroy_strategy
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Modify content
    @api.create_post("New Post", "New content", views: "test-view")
    
    # Restore from backup using destroy strategy
    result = @api.restore_backup(backup_name, strategy: :destroy)
    assert result.is_a?(Hash), "Restore should return a hash"
    assert_equal backup_name, result[:restored], "Should return the restored backup name"
    assert_equal :destroy, result[:strategy], "Should indicate destroy strategy"
    
    # Verify content was restored
    posts = @api.posts("test-view")
    assert_equal 1, posts.length, "Should have only 1 post after restore"
    assert_equal "Original Post", posts[0].title, "Should have original post"
  end

  def test_004c_restore_backup_merge_strategy
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Modify content
    @api.create_post("New Post", "New content", views: "test-view")
    
    # Restore from backup using merge strategy
    result = @api.restore_backup(backup_name, strategy: :merge)
    assert result.is_a?(Hash), "Restore should return a hash"
    assert_equal backup_name, result[:restored], "Should return the restored backup name"
    assert_equal :merge, result[:strategy], "Should indicate merge strategy"
    
    # Verify content was restored (merge should keep existing files)
    posts = @api.posts("test-view")
    assert_equal 2, posts.length, "Should have 2 posts after merge restore"
    post_titles = posts.map(&:title).sort
    assert_equal ["New Post", "Original Post"], post_titles, "Should have both posts"
  end

  def test_005_delete_backup
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "to-delete")
    
    # Verify it exists
    backups = @api.list_backups
    assert_equal 1, backups.length, "Should have 1 backup"
    
    # Delete the backup
    result = @api.delete_backup(backup_name)
    assert result, "Delete should succeed"
    
    # Verify it's gone
    backups = @api.list_backups
    assert_equal 0, backups.length, "Should have 0 backups after delete"
    
    # Verify directory is gone
    backup_dir = @api.get_backup_directory/"data"/backup_name
    assert !Dir.exist?(backup_dir), "Backup directory should be deleted"
  end

  def test_006_incremental_backup_tracks_changes
    # Create initial content and full backup first
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Post 1", "Content 1", views: "test-view")
    
    
    backup1 = @api.create_backup(type: :full, label: "initial")
    
    # Now add new content and create incremental backup
    @api.create_post("Post 2", "Content 2", views: "test-view")
    backup2 = @api.create_backup(type: :incremental, label: "after-changes")
    
    # Verify backups contain expected content
    backup1_dir = @api.get_backup_directory/"data"/backup1
    backup2_dir = @api.get_backup_directory/"data"/backup2
    
    # Full backup should have 1 post (check compressed content)
    backup1_posts = count_posts_in_compressed_backup(backup1_dir)
    assert_equal 1, backup1_posts, "Full backup should have 1 post"
    
    # Incremental backup should have 2 posts (both posts, since post creation modifies existing files)
    backup2_posts = count_posts_in_compressed_backup(backup2_dir)
    assert_equal 2, backup2_posts, "Incremental backup should have 2 posts (both posts, since post creation modifies existing files)"
    
    # Verify the incremental backup contains the new post
    # Extract and check compressed content
    temp_extract_dir = backup2_dir/"temp_extract"
    FileUtils.mkdir_p(temp_extract_dir)
    
    begin
      # Extract tar.gz to temporary directory
      system("tar -xzf '#{backup2_dir}/data.tar.gz' -C '#{temp_extract_dir}'")
      assert $?.success?, "Should successfully extract compressed backup"
      
      # Check for post directories
      backup2_post_dirs = Dir.glob("#{temp_extract_dir}/posts/*")
      assert_equal 2, backup2_post_dirs.length, "Should have exactly two post directories"
      
      # The incremental backup should contain both posts
      # Check that both post directories exist and contain the expected content
      post_dirs = backup2_post_dirs.sort
      
      # Check first post (0001)
      source_file_1 = "#{post_dirs[0]}/source.lt3"
      assert File.exist?(source_file_1), "Source file should exist for post 1"
      content_1 = File.read(source_file_1)
      assert_includes content_1, "Post 1", "Should contain Post 1"
      
      # Check second post (0002)
      source_file_2 = "#{post_dirs[1]}/source.lt3"
      assert File.exist?(source_file_2), "Source file should exist for post 2"
      content_2 = File.read(source_file_2)
      assert_includes content_2, "Post 2", "Should contain Post 2"
    ensure
      # Clean up temporary directory
      FileUtils.rm_rf(temp_extract_dir) if Dir.exist?(temp_extract_dir)
    end
  end

  def test_007_backup_validation
    # Temporarily enable contracts for this test
    original_dbc = ENV['DBC_DISABLED']
    ENV['DBC_DISABLED'] = nil
    
    begin
      # Test invalid backup type - this should fail the assume check
      assert_raises(RuntimeError) do
        @api.create_backup(type: :invalid)
      end
      
      # Test with nil repo - this should fail the assume check
      api_no_repo = Scriptorium::API.new(testmode: true)
      assert_raises(RuntimeError) do
        api_no_repo.create_backup(type: :full)
      end
    ensure
      # Restore original contract setting
      ENV['DBC_DISABLED'] = original_dbc
    end
  end

  def test_008_restore_nonexistent_backup
    # Try to restore a backup that doesn't exist
    assert_raises(BackupNotFound) do
      @api.restore_backup("nonexistent-backup")
    end
  end

  def test_009_delete_nonexistent_backup
    # Try to delete a backup that doesn't exist
    assert_raises(BackupNotFound) do
      @api.delete_backup("nonexistent-backup")
    end
  end

  def test_010_restore_incremental_backup_with_dependencies
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Post 1", "Content 1", views: "test-view")
    
    # Create full backup
    full_backup = @api.create_backup(type: :full, label: "initial")
    sleep(1) # Ensure different timestamps
    
    # Add more content
    @api.create_post("Post 2", "Content 2", views: "test-view")
    
    # Create incremental backup
    incr_backup = @api.create_backup(type: :incremental, label: "after-post-2")
    sleep(1) # Ensure different timestamps
    
    # Add more content
    @api.create_post("Post 3", "Content 3", views: "test-view")
    
    # Restore from incremental backup using safe strategy
    result = @api.restore_backup(incr_backup, strategy: :safe)
    assert result.is_a?(Hash), "Restore should return a hash"
    assert_equal incr_backup, result[:restored], "Should return the restored backup name"
    assert result[:pre_restore], "Should have created a pre-restore backup"
    
    # Verify content was restored correctly (should have Post 1 and Post 2)
    posts = @api.posts("test-view")
    assert_equal 2, posts.length, "Should have 2 posts after restore"
    post_titles = posts.map(&:title).sort
    assert_equal ["Post 1", "Post 2"], post_titles, "Should have correct posts"
  end

  def test_011_restore_invalid_strategy
    # Create a backup first
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Test Post", "Test content", views: "test-view")
    backup_name = @api.create_backup(type: :full, label: "test")
    
    # Try to restore with invalid strategy
    assert_raises(ArgumentError) do
      @api.restore_backup(backup_name, strategy: :invalid)
    end
  end

  def test_012_restore_default_strategy_is_safe
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Modify content
    @api.create_post("New Post", "New content", views: "test-view")
    
    # Restore from backup without specifying strategy (should default to :safe)
    result = @api.restore_backup(backup_name)
    assert result.is_a?(Hash), "Restore should return a hash"
    assert_equal backup_name, result[:restored], "Should return the restored backup name"
    assert result[:pre_restore], "Should have created a pre-restore backup (default is safe)"
    
    # Verify content was restored
    posts = @api.posts("test-view")
    assert_equal 1, posts.length, "Should have only 1 post after restore"
    assert_equal "Original Post", posts[0].title, "Should have original post"
  end

  def test_013_restore_with_pre_restore_backup_timestamp_handling
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Modify content
    @api.create_post("New Post", "New content", views: "test-view")
    
    # Restore from backup using safe strategy
    result = @api.restore_backup(backup_name, strategy: :safe)
    
    # Verify that the pre-restore backup was created and is not used as the base for restore
    backups = @api.list_backups
    pre_restore = backups.find { |b| b[:description]&.include?("pre-restore") }
    assert pre_restore, "Should have created a pre-restore backup"
    
    # The pre-restore backup should not be the same as the original backup
    refute_equal backup_name, pre_restore[:name], "Pre-restore backup should be different from original"
    
    # Verify content was restored correctly
    posts = @api.posts("test-view")
    assert_equal 1, posts.length, "Should have only 1 post after restore"
    assert_equal "Original Post", posts[0].title, "Should have original post"
  end

  def test_014_merge_strategy_preserves_existing_files
    # Create initial content
    @api.create_view("test-view", "Test View", "A test view")
    @api.create_post("Original Post", "Original content", views: "test-view")
    
    # Create a backup
    backup_name = @api.create_backup(type: :full, label: "before-changes")
    
    # Add content that should be preserved
    @api.create_post("Keep This Post", "This should be kept", views: "test-view")
    
    # Restore from backup using merge strategy
    result = @api.restore_backup(backup_name, strategy: :merge)
    
    # Verify both posts exist (merge should preserve existing files)
    posts = @api.posts("test-view")
    assert_equal 2, posts.length, "Should have 2 posts after merge restore"
    post_titles = posts.map(&:title).sort
    assert_equal ["Keep This Post", "Original Post"], post_titles, "Should have both posts"
  end

end
