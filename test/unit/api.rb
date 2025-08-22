# test/unit/api.rb


require 'minitest/autorun'
require 'open3'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestScriptoriumAPI < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers



  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    @api = nil
  end

  def setup
    @test_dir = "test/scriptorium-TEST"
    # Clean up any existing test directory first
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    @api = Scriptorium::API.new(testmode: true)
    @api.create_repo(@test_dir)
  end

  # Basic API functionality tests

  def test_001_api_initialization
    assert_instance_of Scriptorium::API, @api
    assert_instance_of Scriptorium::Repo, @api.repo
    refute_nil @api.current_view
    assert_equal "sample", @api.current_view.name
  end

  def test_002_create_view
    @api.create_view("test_view", "Test View", "A test view")
    
    assert_equal "test_view", @api.current_view.name
    assert_equal "Test View", @api.current_view.title
    assert_equal "A test view", @api.current_view.subtitle
  end

  def test_003_create_post
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test"])
    
    assert_instance_of Scriptorium::Post, post
    assert_equal "Test Post", post.title
    assert_equal "test", post.tags
  end

  def test_004_posts
    @api.create_view("test_view", "Test View")
    @api.create_post("Post 1", "Body 1")
    @api.create_post("Post 2", "Body 2")
    
    posts = @api.posts
    assert_equal 2, posts.length
    # Posts might not be in creation order, so check both exist
    titles = posts.map(&:title)
    assert_includes titles, "Post 1"
    assert_includes titles, "Post 2"
  end

  def test_005_post
    @api.create_view("test_view", "Test View")
    created_post = @api.create_post("Test Post", "Test body")
    
    retrieved_post = @api.post(created_post.id)
    assert_equal created_post.id, retrieved_post.id
    assert_equal "Test Post", retrieved_post.title
  end

  # New API methods tests
  def test_006_views
    @api.create_view("view1", "View 1")
    @api.create_view("view2", "View 2")
    
    views = @api.views.map(&:name)
    assert_includes views, "view1"
    assert_includes views, "view2"
  end

  def test_007_post_attrs
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test", "demo"])
    
    attrs = @api.post_attrs(post.id, :title, :tags)
    assert_equal ["Test Post", "test, demo"], attrs
  end

  def test_008_post_attrs_with_post_object
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test"])
    
    attrs = @api.post_attrs(post, :title, :tags)
    assert_equal ["Test Post", "test"], attrs
  end

  def test_009_views_for
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    views = @api.views_for(post)
    assert_equal ["test_view"], views
  end

  def test_010_views_for_with_id
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    views = @api.views_for(post.id)
    assert_equal ["test_view"], views
  end

  def test_011_apply_theme
    @api.create_view("test_view", "Test View")
    
    # Should not raise an error
    @api.apply_theme("standard")
    assert_equal "standard", @api.current_view.theme
  end



  # Empty methods tests (should not raise errors)
  def test_012_empty_methods
    assert_equal [], @api.drafts
    # Widgets are now available from widgets.txt
    widgets = @api.widgets_available
    assert_includes widgets, "links"
    assert_includes widgets, "pages"
    
    # These should not raise errors
    # @api.delete_draft("some_path")  # This would fail since it's not a valid draft path
    # @api.delete_post(1)  # This would fail since post doesn't exist
    # @api.generate_widget("some_widget")  # This would fail since no current view set
    @api.select_posts { |p| true }
    @api.search_posts(title: "query")
    # @api.unlink_post(nil, nil)  # This would fail since no current view and invalid post
    # @api.generate_all  # This would fail since no current view set
  end

  def test_013_drafts
    drafts = @api.drafts
    assert_instance_of Array, drafts
    # Should return empty array if no drafts directory exists
  end

  def test_014_themes_available
    themes = @api.themes_available
    assert_instance_of Array, themes
    
    # Should have the standard theme
    assert_includes themes, "standard"
    
    # Check system vs user themes
    system_themes = @api.system_themes
    user_themes = @api.user_themes
    
    assert_includes system_themes, "standard"
    assert_empty user_themes  # No user themes yet
  end

  def test_015_clone_theme
    # Clone the standard theme
    result = @api.clone_theme("standard", "my-custom")
    assert_equal "my-custom", result
    
    # Check that the new theme exists
    themes = @api.themes_available
    assert_includes themes, "my-custom"
    
    # Check that it's now a user theme
    user_themes = @api.user_themes
    assert_includes user_themes, "my-custom"
    
    # Check that standard is still a system theme
    system_themes = @api.system_themes
    assert_includes system_themes, "standard"
  end

  def test_016_clone_theme_validation
    # Try to clone to existing theme name
    assert_raises(ThemeAlreadyExists) do
      @api.clone_theme("standard", "standard")
    end
    
    # Try to clone from non-existent theme
    assert_raises(ThemeNotFound) do
      @api.clone_theme("nonexistent", "new-theme")
    end
    
    # Try to clone with invalid name
    assert_raises(ThemeNameInvalid) do
      @api.clone_theme("standard", "invalid name with spaces")
    end
  end

  def test_017_widgets_available
    widgets = @api.widgets_available
    assert_instance_of Array, widgets
    # Should return available widgets from widgets.txt
    assert_includes widgets, "links"
    assert_includes widgets, "pages"
  end

  def test_016_generate_view
    @api.create_view("test_view", "Test View")
    
    # Should not raise an error
    @api.generate_view
  end

  def test_017_generate_view_with_specific_view
    @api.create_view("view1", "View 1")
    @api.create_view("view2", "View 2")
    
    # Should not raise an error
    @api.generate_view("view1")
  end



  # Error handling tests
  def test_018_create_post_without_view
    # Clear the current view directly
    @api.repo.instance_variable_set(:@current_view, nil)
    
    assert_raises(ViewTargetNil) do
      @api.create_post("Test Post", "Test body")
    end
  end

  def test_019_safe_delete_post
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially visible
    posts = @api.posts
    assert_equal 1, posts.length
    
    # Delete the post
    @api.delete_post(post.id)
    
    # Should not appear in posts list
    posts = @api.posts
    assert_equal 0, posts.length
    
    # But post object still exists and can be retrieved
    retrieved_post = @api.post(post.id)
    assert_equal "Test Post", retrieved_post.title
  end

  def test_020_undelete_post
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Delete the post
    @api.delete_post(post.id)
    assert_equal 0, @api.posts.length
    
    # Undelete the post
    @api.undelete_post(post.id)
    
    # Should appear in posts list again
    posts = @api.posts
    assert_equal 1, posts.length
    assert_equal "Test Post", posts[0].title
  end

  def test_021_update_post
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view", "other_view"])
    
    # Update the views field
    result = @api.update_post(post.id, {views: ["test_view"]})
    assert result
    
    # Check that the source file was updated
    source_file = post.dir/"source.lt3"
    content = read_file(source_file)
    assert_includes content, ".views test_view"
    assert_includes content, "# updated views"
  end

  def test_022_update_post_preserves_comments
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Manually add a comment to the source file
    source_file = post.dir/"source.lt3"
    lines = read_file(source_file, lines: true, chomp: false)
    lines.map! do |line|
      if line.strip.start_with?('.views')
        ".views test_view # original comment\n"
      else
        line
      end
    end
    write_file(source_file, lines.join)
    
    # Update the views field
    result = @api.update_post(post.id, {views: ["new_view"]})
    assert result
    
    # Check that original comment is preserved
    content = read_file(source_file)
    assert_includes content, "# original comment"
    assert_includes content, "# updated views"
  end

  def test_023_update_post_multiple_fields
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Update multiple fields at once
    result = @api.update_post(post.id, {
      title: "Updated Title",
      tags: ["new", "tags"]
    })
    assert result
    
    # Check that both fields were updated
    source_file = post.dir/"source.lt3"
    content = read_file(source_file)
    assert_includes content, ".title Updated Title"
    assert_includes content, ".tags new, tags"
    assert_includes content, "# updated title"
    assert_includes content, "# updated tags"
  end



  def test_024_unlink_post
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view", "other_view"])
    
    # Initially post should be in both views
    assert_includes post.views, "test_view"
    assert_includes post.views, "other_view"
    
    # Unlink from current view
    result = @api.unlink_post(post.id)
    assert result
    
    # Post should now only be in test_view (since we unlinked from other_view)
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    refute_includes updated_views, "other_view"
  end

  def test_025_link_post
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Initially post should only be in test_view
    assert_includes post.views, "test_view"
    refute_includes post.views, "other_view"
    
    # Link to other_view
    result = @api.link_post(post.id, "other_view")
    assert result
    
    # Post should now be in both views
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    assert_includes updated_views, "other_view"
  end

  def test_026_link_post_current_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["other_view"])
    
    # Initially post should only be in other_view
    assert_includes post.views, "other_view"
    refute_includes post.views, "test_view"
    
    # Set current view to test_view
    @api.view("test_view")
    
    # Link to current view (test_view)
    result = @api.link_post(post.id)
    assert result
    
    # Post should now be in both views
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    assert_includes updated_views, "other_view"
  end

  def test_027_link_post_duplicate
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Initially post should be in test_view
    assert_includes post.views, "test_view"
    
    # Try to link to the same view (should not add duplicate)
    result = @api.link_post(post.id, "test_view")
    assert result
    
    # Post should still only be in test_view (no duplicates)
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_equal ["test_view"], updated_views
  end

  def test_028_post_add_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Initially post should only be in test_view
    assert_includes post.views, "test_view"
    refute_includes post.views, "other_view"
    
    # Add other_view to the post
    result = @api.post_add_view(post.id, "other_view")
    assert result
    
    # Post should now be in both views
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    assert_includes updated_views, "other_view"
  end

  def test_029_post_add_view_with_view_object
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    other_view = @api.view("other_view")  # Get the View object
    post = @api.create_post("Test Post", "Test body", views: ["test_view"])
    
    # Add other_view to the post using View object
    result = @api.post_add_view(post.id, other_view)
    assert result
    
    # Post should now be in both views
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    assert_includes updated_views, "other_view"
  end

  def test_030_post_remove_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view", "other_view"])
    
    # Initially post should be in both views
    assert_includes post.views, "test_view"
    assert_includes post.views, "other_view"
    
    # Remove other_view from the post
    result = @api.post_remove_view(post.id, "other_view")
    assert result
    
    # Post should now only be in test_view
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    refute_includes updated_views, "other_view"
  end

  def test_031_post_remove_view_with_view_object
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    other_view = @api.view("other_view")  # Get the View object
    post = @api.create_post("Test Post", "Test body", views: ["test_view", "other_view"])
    
    # Remove other_view from the post using View object
    result = @api.post_remove_view(post.id, other_view)
    assert result
    
    # Post should now only be in test_view
    updated_post = @api.post(post.id)
    updated_views = updated_post.views.strip.split(/\s+/)
    assert_includes updated_views, "test_view"
    refute_includes updated_views, "other_view"
  end

  def test_032_update_post_blurb
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Manually add a blurb line to the source file
    source_file = post.dir/"source.lt3"
    lines = read_file(source_file, lines: true, chomp: false)
    lines.insert(-2, ".blurb This is just a short intro to this post.\n")  # Insert before the body
    write_file(source_file, lines.join)
    
    # Update the blurb
    result = @api.update_post(post.id, {blurb: "Updated blurb for this post"})
    assert result
    
    # Check that the blurb was updated
    content = read_file(source_file)
    assert_includes content, ".blurb Updated blurb for this post"
    assert_includes content, "# updated blurb"
  end

  def test_033_delete_draft
    @api.create_view("test_view", "Test View")
    
    # Create a draft
    draft_path = @api.draft(title: "Test Draft", body: "Test body")
    
    # Verify draft exists
    drafts = @api.drafts
    assert_equal 1, drafts.length
    assert_equal draft_path, drafts.first[:path]
    
    # Delete the draft
    result = @api.delete_draft(draft_path)
    assert result
    
    # Verify draft is gone
    drafts = @api.drafts
    assert_equal 0, drafts.length
  end

  def test_034_delete_draft_invalid_path
    @api.create_view("test_view", "Test View")
    
    # Test with non-draft file
    assert_raises(DraftFileInvalid) do
      @api.delete_draft("not-a-draft.txt")
    end
    
    # Test with non-existent file
    assert_raises(DraftFileNotFound) do
      @api.delete_draft("nonexistent-draft.lt3")
    end
  end

  def test_035_generate_view
    @api.create_view("test_view", "Test View")
    @api.create_post("Test Post", "Test body")
    
    # Should not raise an error
    result = @api.generate_view
    assert result
  end



  def test_036_generate_widget
    @api.create_view("test_view", "Test View")
    
    # Create the widget directory and sample data
    widget_dir = @api.repo.root/:views/"test_view"/:widgets/"links"
    make_dir(widget_dir)
    write_file(widget_dir/"list.txt", "https://example.com, Example Link")
    
    # Should not raise an error for a valid widget
    result = @api.generate_widget("links")
    assert result
    
    # Verify the widget files were created
    assert File.exist?(widget_dir/"links-card.html")
  end



  def test_037_generate_widget_invalid_name
    @api.create_view("test_view", "Test View")
    
    # Test with invalid widget name
    assert_raises(WidgetNameInvalid) do
      @api.generate_widget("invalid-widget")
    end
    
    # Test with nil
    assert_raises(WidgetNameNil) do
      @api.generate_widget(nil)
    end
    
    # Test with empty string
    assert_raises(WidgetsArgEmpty) do
      @api.generate_widget("")
    end
  end

  def test_038_generate_widget_nonexistent
    @api.create_view("test_view", "Test View")
    
    # Test with non-existent widget class
    assert_raises(CannotBuildWidget) do
      @api.generate_widget("nonexistent")
    end
  end

  def test_039_select_posts
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    # Create posts in different views
    post1 = @api.create_post("Post 1", "Body 1", views: ["test_view"])
    post2 = @api.create_post("Post 2", "Body 2", views: ["other_view"])
    post3 = @api.create_post("Post 3", "Body 3", views: ["test_view", "other_view"])
    
    # Test filtering by view
    test_view_posts = @api.select_posts { |post| post.views.include?("test_view") }
    assert_equal 2, test_view_posts.length
    assert_includes test_view_posts.map(&:title), "Post 1"
    assert_includes test_view_posts.map(&:title), "Post 3"
    
    # Test filtering by title
    title_posts = @api.select_posts { |post| post.title.include?("Post 2") }
    assert_equal 1, title_posts.length
    assert_equal "Post 2", title_posts.first.title
  end

  def test_040_search_posts
    @api.create_view("test_view", "Test View")
    
    # Create posts with different content
    post1 = @api.create_post("Ruby Programming", "Learn Ruby basics", tags: "ruby, programming")
    post2 = @api.create_post("Python Guide", "Python vs Ruby", tags: "python, comparison")
    post3 = @api.create_post("Scriptorium API", "API documentation", tags: "api, scriptorium")
    
    # Test title search with regex
    ruby_posts = @api.search_posts(title: /Ruby/)
    assert_equal 1, ruby_posts.length
    assert_equal "Ruby Programming", ruby_posts.first.title
    
    # Test body search with string
    body_posts = @api.search_posts(body: "Ruby")
    assert_equal 2, body_posts.length
    assert_includes body_posts.map(&:title), "Ruby Programming"
    assert_includes body_posts.map(&:title), "Python Guide"
    
    # Test tags search
    api_posts = @api.search_posts(tags: "api")
    assert_equal 1, api_posts.length
    assert_equal "Scriptorium API", api_posts.first.title
    
    # Test multiple criteria (AND)
    ruby_api_posts = @api.search_posts(title: /Ruby/, body: "basics")
    assert_equal 1, ruby_api_posts.length
    assert_equal "Ruby Programming", ruby_api_posts.first.title
  end

  def test_041_search_posts_with_blurb
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", blurb: "This is a test blurb for searching.")
    
    # Test blurb search
    blurb_posts = @api.search_posts(blurb: "test blurb")
    assert_equal 1, blurb_posts.length
    assert_equal "Test Post", blurb_posts.first.title
    
    # Test blurb search with regex
    regex_posts = @api.search_posts(blurb: /blurb.*search/)
    assert_equal 1, regex_posts.length
    assert_equal "Test Post", regex_posts.first.title
  end

  def test_042_search_posts_unknown_field
    @api.create_view("test_view", "Test View")
    
    # Create a post so the search actually processes something
    @api.create_post("Test Post", "Test body")
    
    assert_raises(UnknownSearchField) do
      @api.search_posts(unknown_field: "value")
    end
  end

  def test_043_unlink_post_specific_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    post = @api.create_post("Test Post", "Test body", views: ["test_view", "other_view"])
    
    # Unlink from specific view
    result = @api.unlink_post(post.id, "other_view")
    assert result
    
    # Post should now only be in test_view
    updated_post = @api.post(post.id)
    assert_includes updated_post.views, "test_view"
    refute_includes updated_post.views, "other_view"
  end

  def test_044_post_add_tag
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["ruby"])
    
    # Initially post should only have ruby tag
    assert_includes post.tags, "ruby"
    refute_includes post.tags, "scriptorium"
    
    # Add scriptorium tag to the post
    result = @api.post_add_tag(post.id, "scriptorium")
    assert result
    
    # Post should now have both tags
    updated_post = @api.post(post.id)
    updated_tags = updated_post.tags.strip.split(/,\s*/)
    assert_includes updated_tags, "ruby"
    assert_includes updated_tags, "scriptorium"
  end

  def test_045_post_add_tag_duplicate
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["ruby"])
    
    # Initially post should have ruby tag
    assert_includes post.tags, "ruby"
    
    # Try to add the same tag (should not add duplicate)
    result = @api.post_add_tag(post.id, "ruby")
    assert result
    
    # Post should still only have ruby tag (no duplicates)
    updated_post = @api.post(post.id)
    updated_tags = updated_post.tags.strip.split(/,\s*/)
    assert_equal ["ruby"], updated_tags
  end

  def test_046_post_remove_tag
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["ruby", "scriptorium"])
    
    # Initially post should have both tags
    assert_includes post.tags, "ruby"
    assert_includes post.tags, "scriptorium"
    
    # Remove scriptorium tag from the post
    result = @api.post_remove_tag(post.id, "scriptorium")
    assert result
    
    # Post should now only have ruby tag
    updated_post = @api.post(post.id)
    updated_tags = updated_post.tags.strip.split(/,\s*/)
    assert_includes updated_tags, "ruby"
    refute_includes updated_tags, "scriptorium"
  end

  def test_047_post_remove_tag_nonexistent
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["ruby"])
    
    # Initially post should have ruby tag
    assert_includes post.tags, "ruby"
    
    # Try to remove a tag that doesn't exist
    result = @api.post_remove_tag(post.id, "nonexistent")
    assert result  # Should succeed even if tag doesn't exist
    
    # Post should still have ruby tag
    updated_post = @api.post(post.id)
    updated_tags = updated_post.tags.strip.split(/,\s*/)
    assert_includes updated_tags, "ruby"
    refute_includes updated_tags, "nonexistent"
  end

  # edit_file tests
  def test_048_edit_file_validation_nil_path
    assert_raises(EditFilePathNil) do
      @api.edit_file(nil)
    end
  end

  def test_049_edit_file_validation_empty_path
    assert_raises(EditFilePathEmpty) do
      @api.edit_file("")
    end
  end

  def test_050_edit_file_validation_whitespace_path
    assert_raises(EditFilePathEmpty) do
      @api.edit_file("   ")
    end
  end

  def test_051_edit_file_uses_editor_from_env
    # Mock ENV to return a specific editor
    ENV.stub :[], "nano" do
      # Mock system! to verify it's called with the right editor
      mock_system = Minitest::Mock.new
      mock_system.expect :call, true, ["nano", "/path/to/file"]
      
      @api.stub :system!, mock_system do
        @api.edit_file("/path/to/file")
      end
      
      mock_system.verify
    end
  end

  def test_052_edit_file_uses_vim_fallback
    # Mock ENV to return nil (no EDITOR set)
    ENV.stub :[], nil do
      # Mock system to return true (vim available)
      @api.stub :system, true do
        # Mock Open3.popen3 to return a mock process
        mock_process = Minitest::Mock.new
        mock_process.expect :pid, 123
        mock_process.expect :wait, nil
        
        Open3.stub :popen3, mock_process do
          @api.edit_file("test.txt")
        end
      end
    end
  end

  # Convenience file editing method tests
  
  def test_053_edit_layout
    @api.create_view("test_view", "Test View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_layout
      assert_equal "views/test_view/layout.txt", called_path
    end
  end

  def test_054_edit_layout_with_specific_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_layout("other_view")
      assert_equal "views/other_view/layout.txt", called_path
    end
  end

  def test_055_edit_layout_no_view
    # Clear the current view
    @api.repo.instance_variable_set(:@current_view, nil)
    
    assert_raises(ViewTargetNil, "No view specified and no current view set") do
      @api.edit_layout
    end
  end

  def test_065_edit_config
    @api.create_view("test_view", "Test View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_config
      assert_equal "views/test_view/config.txt", called_path
    end
  end

  def test_066_edit_config_with_specific_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_config("other_view")
      assert_equal "views/other_view/config.txt", called_path
    end
  end

  def test_067_edit_config_no_view
    # Clear the current view
    @api.repo.instance_variable_set(:@current_view, nil)
    
    assert_raises(ViewTargetNil, "No view specified and no current view set") do
      @api.edit_config
    end
  end

  def test_056_edit_widget_data
    @api.create_view("test_view", "Test View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_widget_data(nil, "links")
      assert_equal "views/test_view/widgets/links/list.txt", called_path
    end
  end

  def test_057_edit_widget_data_with_specific_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_widget_data("other_view", "news")
      assert_equal "views/other_view/widgets/news/list.txt", called_path
    end
  end

  def test_058_edit_widget_data_nil_widget
    @api.create_view("test_view", "Test View")
    
    assert_raises(WidgetNameNil, "Widget name cannot be nil") do
      @api.edit_widget_data(nil, nil)
    end
  end

  def test_060_edit_repo_config
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_repo_config
      assert_equal "config/repo.txt", called_path
    end
  end

  def test_061_edit_deploy_config
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_deploy_config
      assert_equal "config/deploy.txt", called_path
    end
  end

  def test_062_edit_post_with_source
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Create source.lt3 file to test smart selection
    source_path = "posts/#{post.num}/source.lt3"
    write_file(source_path, "Test source content")
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_post(post.id)
      assert_equal source_path, called_path
    end
  end

  def test_063_edit_post_without_source
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Ensure source.lt3 doesn't exist, only body.html
    source_path = "posts/#{post.num}/source.lt3"
    File.delete(source_path) if File.exist?(source_path)
    
    # Mock edit_file to track calls
    called_path = nil
    @api.stub :edit_file, ->(path) { called_path = path } do
      @api.edit_post(post.id)
      assert_equal "posts/#{post.num}/body.html", called_path
    end
  end

  def test_064_edit_post_nonexistent
    assert_raises(CannotGetPost) do
      @api.edit_post(999)
    end
  end

  # Publication system tests


  def test_068_publish_post
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially unpublished
    refute @api.post_published?(post.id)
    
    # Publish the post
    published_post = @api.publish_post(post.id)
    
    # Should now be published
    assert @api.post_published?(post.id)
    assert_equal "Test Post", published_post.title
    
    # Should have generated the post
    assert File.exist?("#{@test_dir}/posts/#{post.num}/body.html")
  end

  def test_069_publish_post_already_published
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Publish once
    @api.publish_post(post.id)
    
    # Try to publish again
    assert_raises(PostAlreadyPublished, "Post #{post.id} is already published") do
      @api.publish_post(post.id)
    end
  end

  def test_070_publish_post_nonexistent
    assert_raises(RequiredFileNotFound) do
      @api.publish_post(999)
    end
  end

  def test_071_post_published_status
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Initially unpublished
    refute @api.post_published?(post.id)
    
    # Publish
    @api.publish_post(post.id)
    
    # Now published
    assert @api.post_published?(post.id)
  end

  def test_072_get_published_posts
    @api.create_view("test_view", "Test View")
    
    # Create multiple posts
    post1 = @api.create_post("Post 1", "Body 1")
    post2 = @api.create_post("Post 2", "Body 2")
    post3 = @api.create_post("Post 3", "Body 3")
    
    # Initially no published posts
    published_posts = @api.get_published_posts
    assert_equal 0, published_posts.length
    
    # Publish two posts
    @api.publish_post(post1.id)
    @api.publish_post(post3.id)
    
    # Should have 2 published posts
    published_posts = @api.get_published_posts
    assert_equal 2, published_posts.length
    assert_includes published_posts.map(&:id), post1.id
    assert_includes published_posts.map(&:id), post3.id
    refute_includes published_posts.map(&:id), post2.id
  end

  def test_073_get_published_posts_with_view
    @api.create_view("test_view", "Test View")
    @api.create_view("other_view", "Other View")
    
    # Create posts in different views
    post1 = @api.create_post("Post 1", "Body 1", views: "test_view")
    post2 = @api.create_post("Post 2", "Body 2", views: "other_view")
    
    # Publish both
    @api.publish_post(post1.id)
    @api.publish_post(post2.id)
    
    # Get published posts for specific view
    test_view_posts = @api.get_published_posts("test_view")
    assert_equal 1, test_view_posts.length
    assert_equal post1.id, test_view_posts.first.id
    
    other_view_posts = @api.get_published_posts("other_view")
    assert_equal 1, other_view_posts.length
    assert_equal post2.id, other_view_posts.first.id
  end

  def test_074_create_post_with_generation
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Post should exist and be generated by default
    assert File.exist?("#{@test_dir}/posts/#{post.num}/source.lt3")
    assert File.exist?("#{@test_dir}/posts/#{post.num}/meta.txt")
    assert File.exist?("#{@test_dir}/posts/#{post.num}/body.html")
    
    # Should not be published
    refute @api.post_published?(post.id)
  end

  def test_075_create_post_with_generation_default
    @api.create_view("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Post should be generated by default (backward compatibility)
    assert File.exist?("#{@test_dir}/posts/#{post.num}/body.html")
    
    # Should NOT be published (generation and publication are separate)
    # Check the metadata file directly to be sure
    metadata_file = "#{@test_dir}/posts/#{post.num}/meta.txt"
    assert File.exist?(metadata_file)
    metadata_content = read_file(metadata_file)
    assert_match /post\.published\s+no/, metadata_content
    refute @api.post_published?(post.id)
  end

  def test_999_placeholder
    # This test ensures the file has at least one test method
    assert true
  end

  # Asset management tests
  
  def test_1000_list_assets_global
    # @api is already set up in setup method
    
    # Create some test assets
    write_file("test/scriptorium-TEST/assets/test1.jpg", "Test image 1")
    write_file("test/scriptorium-TEST/assets/test2.png", "Test image 2")
    
    assets = @api.list_assets(target: 'global')
    
    assert_equal 2, assets.length
    assert_equal "test1.jpg", assets[0][:filename]
    assert_equal "test2.png", assets[1][:filename]
    assert_equal "image", assets[0][:type]
    assert_equal "image", assets[1][:type]
    assert assets[0][:size] > 0
  end
  
  def test_1001_list_assets_library
    # @api is already set up in setup method
    
    # Create library assets
    write_file("test/scriptorium-TEST/assets/library/sample1.jpg", "Sample 1")
    write_file("test/scriptorium-TEST/assets/library/sample2.txt", "Sample 2")
    
    assets = @api.list_assets(target: 'library')
    
    # There might be existing assets from setup, so check that our test assets are included
    assert assets.length >= 2, "Should have at least our 2 test assets"
    filenames = assets.map { |a| a[:filename] }
    assert_includes filenames, "sample1.jpg"
    assert_includes filenames, "sample2.txt"
    
    # Find our specific test assets
    sample1 = assets.find { |a| a[:filename] == "sample1.jpg" }
    sample2 = assets.find { |a| a[:filename] == "sample2.txt" }
    
    assert_equal "image", sample1[:type]
    assert_equal "document", sample2[:type]
  end
  
  def test_1002_list_assets_view
    # @api is already set up in setup method
    @api.create_view("testview", "Test View", "Test Subtitle")
    
    # Create view assets
    write_file("test/scriptorium-TEST/views/testview/assets/view1.jpg", "View asset 1")
    write_file("test/scriptorium-TEST/views/testview/assets/view2.svg", "View asset 2")
    
    assets = @api.list_assets(target: 'view', view: 'testview')
    
    assert_equal 2, assets.length
    assert_equal "view1.jpg", assets[0][:filename]
    assert_equal "view2.svg", assets[1][:filename]
    assert_equal "image", assets[0][:type]
    assert_equal "image", assets[1][:type]
  end
  
  def test_1003_list_assets_gem
    # @api is already set up in setup method
    
    # Test gem assets (should work in development environment)
    assets = @api.list_assets(target: 'gem')
    
    # In development environment, we should find assets from the working directory
    # If no gem assets are found, that's also acceptable
    if assets.length > 0
      assert assets.all? { |asset| asset[:type] == 'image' || asset[:type] == 'other' }
    end
  end
  
  def test_1004_get_asset_info
    # @api is already set up in setup method
    
    # Create test asset
    write_file("test/scriptorium-TEST/assets/test_info.jpg", "Test info image")
    
    asset_info = @api.get_asset_info("test_info.jpg", target: 'global')
    
    assert_equal "test_info.jpg", asset_info[:filename]
    assert_equal "image", asset_info[:type]
    assert asset_info[:size] > 0
    assert asset_info[:path].include?("test_info.jpg")
  end
  
  def test_1005_asset_exists
    # @api is already set up in setup method
    
    # Create test asset
    write_file("test/scriptorium-TEST/assets/exists.jpg", "Exists")
    
    assert @api.asset_exists?("exists.jpg", target: 'global')
    refute @api.asset_exists?("missing.jpg", target: 'global')
  end
  
  def test_1006_copy_asset_global_to_view
    # @api is already set up in setup method
    @api.create_view("testview", "Test View", "Test Subtitle")
    
    # Create source asset
    write_file("test/scriptorium-TEST/assets/source.jpg", "Source image")
    
    # Copy asset
    target_path = @api.copy_asset("source.jpg", from: 'global', to: 'view', view: 'testview')
    
    # Verify copy
    assert File.exist?(target_path)
    assert File.exist?("test/scriptorium-TEST/views/testview/assets/source.jpg")
    assert_equal "Source image", read_file("test/scriptorium-TEST/views/testview/assets/source.jpg").chomp
  end
  
  def test_1007_copy_asset_gem_to_global
    # @api is already set up in setup method
    
    # Find a gem asset to copy
    gem_assets = @api.list_assets(target: 'gem')
    skip "No gem assets available for testing" if gem_assets.empty?
    
    gem_filename = gem_assets.first[:filename]
    
    # Copy from gem to global
    target_path = @api.copy_asset(gem_filename, from: 'gem', to: 'global')
    
    # Verify copy
    assert File.exist?(target_path)
    assert File.exist?("test/scriptorium-TEST/assets/#{gem_filename}")
  end
  
  def test_1008_copy_asset_library_to_view
    # @api is already set up in setup method
    @api.create_view("testview", "Test View", "Test Subtitle")
    
    # Create library asset
    write_file("test/scriptorium-TEST/assets/library/lib.jpg", "Library image")
    
    # Copy to view
    target_path = @api.copy_asset("lib.jpg", from: 'library', to: 'view', view: 'testview')
    
    # Verify copy
    assert File.exist?(target_path)
    assert File.exist?("test/scriptorium-TEST/views/testview/assets/lib.jpg")
  end
  
  def test_1009_upload_asset
    # @api is already set up in setup method
    
    # Create temporary source file
    source_file = "test/temp_source.jpg"
    write_file(source_file, "Temporary source image")
    
    # Upload to global
    target_path = @api.upload_asset(source_file, target: 'global')
    
    # Verify upload
    assert File.exist?(target_path)
    assert File.exist?("test/scriptorium-TEST/assets/temp_source.jpg")
    assert_equal "Temporary source image", read_file("test/scriptorium-TEST/assets/temp_source.jpg").chomp
    
    # Cleanup
    File.delete(source_file)
  end
  
  def test_1010_upload_asset_to_view
    # @api is already set up in setup method
    @api.create_view("testview", "Test View", "Test Subtitle")
    
    # Create temporary source file
    source_file = "test/temp_view_source.jpg"
    write_file(source_file, "View source image")
    
    # Upload to view
    target_path = @api.upload_asset(source_file, target: 'view', view: 'testview')
    
    # Verify upload
    assert File.exist?(target_path)
    assert File.exist?("test/scriptorium-TEST/views/testview/assets/temp_view_source.jpg")
    
    # Cleanup
    File.delete(source_file)
  end
  
  def test_1011_delete_asset
    # @api is already set up in setup method
    
    # Create test asset
    write_file("test/scriptorium-TEST/assets/to_delete.jpg", "Delete me")
    
    # Verify it exists
    assert File.exist?("test/scriptorium-TEST/assets/to_delete.jpg")
    
    # Delete it
    result = @api.delete_asset("to_delete.jpg", target: 'global')
    
    # Verify deletion
    assert result
    refute File.exist?("test/scriptorium-TEST/assets/to_delete.jpg")
  end
  
  def test_1012_get_asset_path
    # @api is already set up in setup method
    
    # Create test asset
    write_file("test/scriptorium-TEST/assets/path_test.jpg", "Path test")
    
    # Get path
    path = @api.get_asset_path("path_test.jpg", target: 'global')
    
    assert path.include?("path_test.jpg")
    assert path.include?("assets")
  end
  
  def test_1013_get_asset_dimensions
    # @api is already set up in setup method
    
    # Create test image (we'll use a placeholder)
    write_file("test/scriptorium-TEST/assets/dimensions.jpg", "Image data")
    
    # Get dimensions (may be nil if FastImage not available)
    dimensions = @api.get_asset_dimensions("dimensions.jpg", target: 'global')
    
    # Just verify the method doesn't crash
    assert true
  end
  
  def test_1014_get_asset_size
    # @api is already set up in setup method
    
    # Create test asset
    content = "Test content for size measurement"
    write_file("test/scriptorium-TEST/assets/size_test.txt", content)
    
    # Get size (write_file adds a newline, so size will be content.length + 1)
    size = @api.get_asset_size("size_test.txt", target: 'global')
    
    assert_equal content.length + 1, size
  end
  
  def test_1015_get_asset_type
    # @api is already set up in setup method
    
    # Test various file types
    assert_equal "image", @api.get_asset_type("test.jpg")
    assert_equal "image", @api.get_asset_type("test.png")
    assert_equal "image", @api.get_asset_type("test.svg")
    assert_equal "document", @api.get_asset_type("test.txt")
    assert_equal "document", @api.get_asset_type("test.md")
    assert_equal "video", @api.get_asset_type("test.mp4")
    assert_equal "audio", @api.get_asset_type("test.mp3")
    assert_equal "other", @api.get_asset_type("test.xyz")
    assert_nil @api.get_asset_type(nil)
  end
  
  def test_1016_bulk_copy_assets
    # @api is already set up in setup method
    @api.create_view("testview", "Test View", "Test Subtitle")
    
    # Create multiple source assets
    write_file("test/scriptorium-TEST/assets/bulk1.jpg", "Bulk 1")
    write_file("test/scriptorium-TEST/assets/bulk2.png", "Bulk 2")
    write_file("test/scriptorium-TEST/assets/bulk3.txt", "Bulk 3")
    
    filenames = ["bulk1.jpg", "bulk2.png", "bulk3.txt"]
    
    # Bulk copy
    results = @api.bulk_copy_assets(filenames, from: 'global', to: 'view', view: 'testview')
    
    # Verify results
    assert_equal 3, results.length
    assert results.all? { |r| r[:success] }
    
    # Verify files were copied
    filenames.each do |filename|
      assert File.exist?("test/scriptorium-TEST/views/testview/assets/#{filename}")
    end
  end
  
  def test_1017_copy_asset_invalid_source
    # @api is already set up in setup method
    
    # Try to copy from invalid source
    assert_raises(InvalidFormatError) do
      @api.copy_asset("test.jpg", from: 'invalid', to: 'global')
    end
  end
  
  def test_1018_copy_asset_invalid_target
    # @api is already set up in setup method
    
    # Try to copy to invalid target
    assert_raises(InvalidFormatError) do
      @api.copy_asset("test.jpg", from: 'global', to: 'invalid')
    end
  end
  
  def test_1019_copy_asset_source_not_found
    # @api is already set up in setup method
    
    # Try to copy non-existent asset
    assert_raises(FileNotFoundError) do
      @api.copy_asset("missing.jpg", from: 'global', to: 'global')
    end
  end
  
  def test_1020_list_assets_no_view_specified
    # @api is already set up in setup method
    
    # Should work for global assets
    assets = @api.list_assets(target: 'global')
    assert assets.is_a?(Array)
    
    # Clear the current view to test the error case
    @api.repo.instance_variable_set(:@current_view, nil)
    
    # Should fail for view assets without view
    assert_raises(ViewTargetNil) do
      @api.list_assets(target: 'view')
    end
  end
end 
