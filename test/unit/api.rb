# test/unit/api.rb

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestScriptoriumAPI < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  def setup
    @test_dir = "test/scriptorium-TEST"
    @api = Scriptorium::API.new(true)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  # Basic API functionality tests
  def test_api_initialization
    assert_instance_of Scriptorium::API, @api
    assert_instance_of Scriptorium::Repo, @api.repo
    assert_nil @api.current_view
  end

  def test_create_view_and_use
    @api.create_view_and_use("test_view", "Test View", "A test view")
    
    assert_equal "test_view", @api.current_view.name
    assert_equal "Test View", @api.current_view.title
    assert_equal "A test view", @api.current_view.subtitle
  end

  def test_create_post
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test"])
    
    assert_instance_of Scriptorium::Post, post
    assert_equal "Test Post", post.title
    assert_equal "test", post.tags
  end

  def test_posts
    @api.create_view_and_use("test_view", "Test View")
    @api.create_post("Post 1", "Body 1")
    @api.create_post("Post 2", "Body 2")
    
    posts = @api.posts
    assert_equal 2, posts.length
    # Posts might not be in creation order, so check both exist
    titles = posts.map(&:title)
    assert_includes titles, "Post 1"
    assert_includes titles, "Post 2"
  end

  def test_post
    @api.create_view_and_use("test_view", "Test View")
    created_post = @api.create_post("Test Post", "Test body")
    
    retrieved_post = @api.post(created_post.id)
    assert_equal created_post.id, retrieved_post.id
    assert_equal "Test Post", retrieved_post.title
  end

  # New API methods tests
  def test_views
    @api.create_view("view1", "View 1")
    @api.create_view("view2", "View 2")
    
    views = @api.views
    assert_includes views, "view1"
    assert_includes views, "view2"
  end

  def test_post_attrs
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test", "demo"])
    
    attrs = @api.post_attrs(post.id, :title, :tags)
    assert_equal ["Test Post", "test, demo"], attrs
  end

  def test_post_attrs_with_post_object
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body", tags: ["test"])
    
    attrs = @api.post_attrs(post, :title, :tags)
    assert_equal ["Test Post", "test"], attrs
  end

  def test_views_for
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    views = @api.views_for(post)
    assert_equal ["test_view"], views
  end

  def test_views_for_with_id
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    views = @api.views_for(post.id)
    assert_equal ["test_view"], views
  end

  def test_apply_theme
    @api.create_view_and_use("test_view", "Test View")
    
    # Should not raise an error
    @api.apply_theme("standard")
    assert_equal "standard", @api.current_view.theme
  end

  def test_apply_theme_without_current_view
    assert_raises(RuntimeError) do
      @api.apply_theme("standard")
    end
  end

  # Empty methods tests (should not raise errors)
  def test_empty_methods
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

  def test_drafts
    drafts = @api.drafts
    assert_instance_of Array, drafts
    # Should return empty array if no drafts directory exists
  end

  def test_themes_available
    themes = @api.themes_available
    assert_instance_of Array, themes
    assert_includes themes, "standard"  # Should have the standard theme
  end

  def test_widgets_available
    widgets = @api.widgets_available
    assert_instance_of Array, widgets
    # Should return available widgets from widgets.txt
    assert_includes widgets, "links"
    assert_includes widgets, "pages"
  end

  def test_generate_view
    @api.create_view_and_use("test_view", "Test View")
    
    # Should not raise an error
    @api.generate_view
  end

  def test_generate_view_with_specific_view
    @api.create_view("view1", "View 1")
    @api.create_view("view2", "View 2")
    
    # Should not raise an error
    @api.generate_view("view1")
  end

  def test_generate_view_without_view
    assert_raises(RuntimeError) do
      @api.generate_view
    end
  end

  # Error handling tests
  def test_create_post_without_view
    assert_raises(RuntimeError) do
      @api.create_post("Test Post", "Test body")
    end
  end

  def test_generate_front_page_without_view
    assert_raises(RuntimeError) do
      @api.generate_front_page
    end
  end

  def test_quick_post
    @api.create_view_and_use("test_view", "Test View")
    
    # Should not raise an error
    @api.quick_post("Quick Post", "Quick body", tags: ["quick"])
    
    posts = @api.posts
    assert_equal 1, posts.length
    assert_equal "Quick Post", posts[0].title
  end

  def test_safe_delete_post
    @api.create_view_and_use("test_view", "Test View")
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

  def test_undelete_post
    @api.create_view_and_use("test_view", "Test View")
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

  def test_update_post
    @api.create_view_and_use("test_view", "Test View")
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

  def test_update_post_preserves_comments
    @api.create_view_and_use("test_view", "Test View")
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
    write_file(source_file, *lines)
    
    # Update the views field
    result = @api.update_post(post.id, {views: ["new_view"]})
    assert result
    
    # Check that original comment is preserved
    content = read_file(source_file)
    assert_includes content, "# original comment"
    assert_includes content, "# updated views"
  end

  def test_update_post_multiple_fields
    @api.create_view_and_use("test_view", "Test View")
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



  def test_unlink_post
    @api.create_view_and_use("test_view", "Test View")
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

  def test_link_post
    @api.create_view_and_use("test_view", "Test View")
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

  def test_link_post_current_view
    @api.create_view_and_use("test_view", "Test View")
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

  def test_link_post_duplicate
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_add_view
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_add_view_with_view_object
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_remove_view
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_remove_view_with_view_object
    @api.create_view_and_use("test_view", "Test View")
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

  def test_update_post_blurb
    @api.create_view_and_use("test_view", "Test View")
    post = @api.create_post("Test Post", "Test body")
    
    # Manually add a blurb line to the source file
    source_file = post.dir/"source.lt3"
    lines = read_file(source_file, lines: true, chomp: false)
    lines.insert(-2, ".blurb This is just a short intro to this post.\n")  # Insert before the body
    write_file(source_file, *lines)
    
    # Update the blurb
    result = @api.update_post(post.id, {blurb: "Updated blurb for this post"})
    assert result
    
    # Check that the blurb was updated
    content = read_file(source_file)
    assert_includes content, ".blurb Updated blurb for this post"
    assert_includes content, "# updated blurb"
  end

  def test_delete_draft
    @api.create_view_and_use("test_view", "Test View")
    
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

  def test_delete_draft_invalid_path
    @api.create_view_and_use("test_view", "Test View")
    
    # Test with non-draft file
    assert_raises(RuntimeError) do
      @api.delete_draft("not-a-draft.txt")
    end
    
    # Test with non-existent file
    assert_raises(RuntimeError) do
      @api.delete_draft("nonexistent-draft.lt3")
    end
  end

  def test_generate_all
    @api.create_view_and_use("test_view", "Test View")
    @api.create_post("Test Post", "Test body")
    
    # Should not raise an error
    result = @api.generate_all
    assert result
  end

  def test_generate_all_without_view
    assert_raises(RuntimeError) do
      @api.generate_all
    end
  end

  def test_generate_widget
    @api.create_view_and_use("test_view", "Test View")
    
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

  def test_generate_widget_without_view
    assert_raises(RuntimeError) do
      @api.generate_widget("links")
    end
  end

  def test_generate_widget_invalid_name
    @api.create_view_and_use("test_view", "Test View")
    
    # Test with invalid widget name
    assert_raises(RuntimeError) do
      @api.generate_widget("invalid-widget")
    end
    
    # Test with nil
    assert_raises(RuntimeError) do
      @api.generate_widget(nil)
    end
    
    # Test with empty string
    assert_raises(RuntimeError) do
      @api.generate_widget("")
    end
  end

  def test_generate_widget_nonexistent
    @api.create_view_and_use("test_view", "Test View")
    
    # Test with non-existent widget class
    assert_raises(RuntimeError) do
      @api.generate_widget("nonexistent")
    end
  end

  def test_select_posts
    @api.create_view_and_use("test_view", "Test View")
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

  def test_search_posts
    @api.create_view_and_use("test_view", "Test View")
    
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

  def test_search_posts_with_blurb
    @api.create_view_and_use("test_view", "Test View")
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

  def test_search_posts_unknown_field
    @api.create_view_and_use("test_view", "Test View")
    
    # Create a post so the search actually processes something
    @api.create_post("Test Post", "Test body")
    
    assert_raises(RuntimeError) do
      @api.search_posts(unknown_field: "value")
    end
  end

  def test_unlink_post_specific_view
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_add_tag
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_add_tag_duplicate
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_remove_tag
    @api.create_view_and_use("test_view", "Test View")
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

  def test_post_remove_tag_nonexistent
    @api.create_view_and_use("test_view", "Test View")
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
  def test_edit_file_validation_nil_path
    assert_raises(CannotEditFilePathNil) do
      @api.edit_file(nil)
    end
  end

  def test_edit_file_validation_empty_path
    assert_raises(CannotEditFilePathEmpty) do
      @api.edit_file("")
    end
  end

  def test_edit_file_validation_whitespace_path
    assert_raises(CannotEditFilePathEmpty) do
      @api.edit_file("   ")
    end
  end

  def test_edit_file_uses_editor_from_env
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

  def test_edit_file_uses_vim_fallback
    # Mock ENV to return nil (no EDITOR set)
    ENV.stub :[], nil do
      # Mock system! to verify it uses vim as fallback
      mock_system = Minitest::Mock.new
      mock_system.expect :call, true, ["vim", "/path/to/file"]
      
      @api.stub :system!, mock_system do
        @api.edit_file("/path/to/file")
      end
      
      mock_system.verify
    end
  end
end 