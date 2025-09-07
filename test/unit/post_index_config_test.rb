require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestPostIndexConfig < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers
  def setup
    @repo = create_test_repo
    @view = @repo.create_view("testview", "Test View")
  end

  def teardown
    system("rm -rf test/scriptorium-TEST")
  end

  def test_001_post_index_config_defaults
    # Test that default title size is used when no config file exists
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)    
    assert_match(/font-size: 1\.1em/, entry)
  end

  def test_002_post_index_config_override
    # Test that custom title size from config file is used
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.title.size 1.5em")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/font-size: 1\.5em/, entry)
  end

  def test_003_post_index_config_missing_key_falls_back
    # Test that missing config key falls back to default
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "posts.per.page 5")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/font-size: 1\.1em/, entry)
  end

  def test_004_posts_per_page_uses_global_default
    # Test that posts.per.page gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal 10, config[:"posts.per.page"].to_i
  end

  def test_005_posts_per_page_view_override
    # Test that view config can override posts.per.page
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "posts.per.page 5")
    
    config = @view.read_post_index_config
    assert_equal 5, config[:"posts.per.page"].to_i
  end

  def test_006_entry_blurb_size_uses_global_default
    # Test that entry.blurb.size gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "0.75em", config[:"entry.blurb.size"]
  end

  def test_007_entry_blurb_size_view_override
    # Test that view config can override entry.blurb.size
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.blurb.size 0.9em")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/font-size: 0\.9em/, entry)
  end

  def test_008_entry_date_size_uses_global_default
    # Test that entry.date.size gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "0.7em", config[:"entry.date.size"]
  end

  def test_009_entry_date_width_uses_global_default
    # Test that entry.date.width gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "14%", config[:"entry.date.width"]
  end

  def test_010_entry_date_config_view_override
    # Test that view config can override entry.date.size and entry.date.width
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.date.size 0.8em\nentry.date.width 16%")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/width=16%/, entry)
    assert_match(/font-size: 0\.8em/, entry)
  end

  def test_011_entry_cellpadding_uses_global_default
    # Test that entry.cellpadding gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "4", config[:"entry.cellpadding"]
  end

  def test_012_entry_margin_bottom_uses_global_default
    # Test that entry.margin.bottom gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "6px", config[:"entry.margin.bottom"]
  end

  def test_013_entry_spacing_config_view_override
    # Test that view config can override entry.cellpadding and entry.margin.bottom
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.cellpadding 6\nentry.margin.bottom 8px")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    
    # Test the full post index generation to see cellpadding on the table
    @view.generate_post_index
    full_index = File.read("test/scriptorium-TEST/views/testview/output/post_index.html")
    assert_match(/cellpadding=6/, full_index)
    
    # Test individual entry for margin-bottom
    entry = @view.post_index_entry(post)
    assert_match(/margin-bottom: 8px/, entry)
  end

  def test_014_entry_title_color_uses_global_default
    # Test that entry.title.color gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "#000000", config[:"entry.title.color"]
  end

  def test_015_entry_blurb_color_uses_global_default
    # Test that entry.blurb.color gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "#666666", config[:"entry.blurb.color"]
  end

  def test_016_entry_date_color_uses_global_default
    # Test that entry.date.color gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "#888888", config[:"entry.date.color"]
  end

  def test_017_entry_colors_view_override
    # Test that view config can override all color settings
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.title.color #ff0000\nentry.blurb.color #00ff00\nentry.date.color #0000ff")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/color: #ff0000/, entry)
    assert_match(/color: #00ff00/, entry)
    assert_match(/color: #0000ff/, entry)
  end

  def test_018_entry_line_height_uses_global_default
    # Test that entry.line.height gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "1.1", config[:"entry.line.height"]
  end

  def test_019_entry_date_alignment_uses_global_default
    # Test that entry.date.alignment gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "right", config[:"entry.date.alignment"]
  end

  def test_020_entry_date_spacing_uses_global_default
    # Test that entry.date.spacing gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "0.1em", config[:"entry.date.spacing"]
  end

  def test_021_entry_layout_config_view_override
    # Test that view config can override line height, date alignment, and date spacing
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.line.height 1.3\nentry.date.alignment center\nentry.date.spacing 0.2em")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.today.to_s
    entry = @view.post_index_entry(post)
    
    assert_match(/line-height: 1\.3/, entry)
    assert_match(/text-align: center/, entry)
    assert_match(/height: 0\.2em/, entry)
  end

  def test_022_index_margin_top_uses_global_default
    # Test that index.margin.top gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "20px", config[:"index.margin.top"]
  end

  def test_023_index_margin_top_view_override
    # Test that view config can override index.margin.top
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "index.margin.top 10px")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    
    # Test the full post index generation to see margin-top on the table
    @view.generate_post_index
    full_index = File.read("test/scriptorium-TEST/views/testview/output/post_index.html")
    assert_match(/margin-top: 10px/, full_index)
  end

  def test_024_date_format_uses_global_default
    # Test that entry.date.format gets global default when no view config exists
    config = @view.read_post_index_config
    assert_equal "month dd, yyyy", config[:"entry.date.format"]
  end

  def test_025_date_format_view_override
    # Test that view config can override entry.date.format
    config_file = @view.dir/:config/"post_index.txt"
    write_file(config_file, "entry.date.format dd month yyyy")
    
    dname = @repo.create_draft(title: "Test Post")
    @repo.finish_draft(dname)
    post = @repo.all_posts("testview").first
    post.meta["post.pubdate"] = Date.new(2025, 2, 22).to_s
    
    entry = @view.post_index_entry(post)
    assert_match(/22 February 2025/, entry)
  end
end
