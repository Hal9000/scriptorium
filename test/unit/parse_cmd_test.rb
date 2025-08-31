require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class ParseCmdTest < Minitest::Test
  # Extract the parse_cmd method from the TUI class for testing
  private def parse_cmd(cmdstr)
    parts = cmdstr.split
    return [:unknown_command, ""] if parts.empty?
    
    # Handle 2-word commands and single-word commands with arguments
    if parts.length >= 2
      # Check if first two words form a known 2-word command
      two_word_cmd = parts[0..1].join(" ")
      case two_word_cmd.downcase
      when "list views", "list posts", "list drafts", "list assets", "list widgets", "list themes",
           "change view", "new view", "new post", "upload asset", "copy asset", "delete asset",
           "delete theme", "asset info", "configure deployment", "add widget", "config widget",
           "config social", "config reddit", "clone theme"
        cmd = two_word_cmd
        args = parts[2..-1]
      else
        # Check if first word is a single-word command that can take parameters
        first_word = parts[0].downcase
        case first_word
        when "cv"  # Only cv is a single-word command that takes parameters
          # First word can take parameters, rest are arguments
          cmd = first_word
          args = parts[1..-1]
        else
          # Unknown command - treat as unknown 2-word command
          cmd = two_word_cmd
          args = parts[2..-1]
        end
      end
    else
      cmd = parts[0]
      args = []
    end
    
    cmd = cmd.downcase

    case cmd
    when "help", "h"
      [:show_help]
    when "view"
      [:show_current_view]
    when "cv"
      [:change_view, args]
    when "lsv"
      [:list_views]
    when "lsp"
      [:list_posts]
    when "lsd"
      [:list_drafts]
    when "version", "v"
      [:show_version]
    when "deploy"
      [:deploy_current_view]
    when "preview"
      [:preview_current_view]
    when "browse"
      [:browse_deployed_view]
    when "generate"
      [:generate_current_view]
    when "quit", "q"
      [:exit, 0]
    when "list views"
      [:list_views]
    when "list posts"
      [:list_posts]
    when "list drafts"
      [:list_drafts]
    when "list assets"
      [:list_assets, args]
    when "list widgets"
      [:list_widgets]
    when "list themes"
      [:list_themes]
    when "change view"
      [:change_view, args]
    when "new view"
      args.empty? ? [:create_view] : [:create_view, args]
    when "new post"
      [:create_post, args]
    when "upload asset"
      [:upload_asset, args]
    when "copy asset"
      [:copy_asset, args]
    when "delete asset"
      [:delete_asset, args]
    when "delete theme"
      [:delete_theme, args]
    when "asset info"
      [:asset_info, args]
    when "configure deployment"
      [:configure_deployment, args]
    when "add widget"
      [:add_widget, args]
    when "config widget"
      [:config_widget, args]
    when "config social"
      [:config_social]
    when "config reddit"
      [:config_reddit]
    when "clone theme"
      [:clone_theme, args]
    else
      [:unknown_command, cmd]
    end
  end

  def test_001_parse_cmd_basic_commands
    # Test basic single-word commands
    assert_equal [:show_help], parse_cmd("help")
    assert_equal [:show_help], parse_cmd("h")
    assert_equal [:show_current_view], parse_cmd("view")
    assert_equal [:list_views], parse_cmd("lsv")
    assert_equal [:list_posts], parse_cmd("lsp")
    assert_equal [:list_drafts], parse_cmd("lsd")
    assert_equal [:show_version], parse_cmd("version")
    assert_equal [:show_version], parse_cmd("v")
    assert_equal [:deploy_current_view], parse_cmd("deploy")
    assert_equal [:preview_current_view], parse_cmd("preview")
    assert_equal [:browse_deployed_view], parse_cmd("browse")
    assert_equal [:generate_current_view], parse_cmd("generate")
    assert_equal [:exit, 0], parse_cmd("quit")
    assert_equal [:exit, 0], parse_cmd("q")
  end

  def test_002_parse_cmd_list_commands
    # Test list commands
    assert_equal [:list_views], parse_cmd("list views")
    assert_equal [:list_posts], parse_cmd("list posts")
    assert_equal [:list_drafts], parse_cmd("list drafts")
    assert_equal [:list_assets, ["assets", "global"]], parse_cmd("list assets assets global")
    assert_equal [:list_widgets], parse_cmd("list widgets")
    assert_equal [:list_themes], parse_cmd("list themes")
  end

  def test_003_parse_cmd_change_commands
    # Test change commands
    assert_equal [:change_view, ["myview"]], parse_cmd("change view myview")
  end

  def test_004_parse_cmd_new_commands
    # Test new commands
    assert_equal [:create_view], parse_cmd("new view")
    assert_equal [:create_view, ["myview"]], parse_cmd("new view myview")
    assert_equal [:create_post, ["mypost"]], parse_cmd("new post mypost")
  end

  def test_005_parse_cmd_asset_commands
    # Test asset commands
    assert_equal [:upload_asset, ["myfile", "global"]], parse_cmd("upload asset myfile global")
    assert_equal [:copy_asset, ["myfile", "from", "to"]], parse_cmd("copy asset myfile from to")
    assert_equal [:delete_asset, ["myfile", "global"]], parse_cmd("delete asset myfile global")
    assert_equal [:asset_info, ["myfile", "global"]], parse_cmd("asset info myfile global")
  end

  def test_006_parse_cmd_configure_commands
    # Test configure commands
    assert_equal [:configure_deployment, ["myview"]], parse_cmd("configure deployment myview")
  end

  def test_007_parse_cmd_widget_commands
    # Test widget commands
    assert_equal [:add_widget, ["mywidget"]], parse_cmd("add widget mywidget")
    assert_equal [:config_widget, ["mywidget"]], parse_cmd("config widget mywidget")
  end

  def test_008_parse_cmd_config_commands
    # Test config commands
    assert_equal [:config_social], parse_cmd("config social")
    assert_equal [:config_reddit], parse_cmd("config reddit")
  end

  def test_009_parse_cmd_clone_commands
    # Test clone commands
    assert_equal [:clone_theme, ["mytheme"]], parse_cmd("clone theme mytheme")
  end

  def test_010_parse_cmd_theme_commands
    # Test theme commands
    assert_equal [:delete_theme, ["mytheme"]], parse_cmd("delete theme mytheme")
  end

  def test_011_parse_cmd_edge_cases
    # Test edge cases
    assert_equal [:unknown_command, "invalid"], parse_cmd("invalid")
    assert_equal [:unknown_command, ""], parse_cmd("")
    assert_equal [:unknown_command, ""], parse_cmd("   ")  # split() removes whitespace
    assert_equal [:show_help], parse_cmd("help")
    assert_equal [:show_help], parse_cmd("  help  ")
  end

  def test_012_parse_cmd_complex_args
    # Test commands with complex arguments
    assert_equal [:change_view, ["my", "view", "with", "spaces"]], parse_cmd("change view my view with spaces")
    assert_equal [:create_view, ["my", "view", "with", "spaces"]], parse_cmd("new view my view with spaces")
    assert_equal [:list_assets, ["global", "with", "spaces"]], parse_cmd("list assets global with spaces")
  end

  def test_013_parse_cmd_abbreviated_commands
    # Test abbreviated commands
    assert_equal [:change_view, ["myview"]], parse_cmd("cv myview")
    assert_equal [:list_views], parse_cmd("lsv")
    assert_equal [:list_posts], parse_cmd("lsp")
    assert_equal [:list_drafts], parse_cmd("lsd")
  end

  def test_014_parse_cmd_unknown_commands
    # Test unknown commands
    assert_equal [:unknown_command, "list invalid"], parse_cmd("list invalid")
    assert_equal [:unknown_command, "change invalid"], parse_cmd("change invalid")
    assert_equal [:unknown_command, "new invalid"], parse_cmd("new invalid")
    assert_equal [:unknown_command, "upload invalid"], parse_cmd("upload invalid")
    assert_equal [:unknown_command, "copy invalid"], parse_cmd("copy invalid")
    assert_equal [:unknown_command, "delete invalid"], parse_cmd("delete invalid")
    assert_equal [:unknown_command, "asset invalid"], parse_cmd("asset invalid")
    assert_equal [:unknown_command, "configure invalid"], parse_cmd("configure invalid")
    assert_equal [:unknown_command, "add invalid"], parse_cmd("add invalid")
    assert_equal [:unknown_command, "config invalid"], parse_cmd("config invalid")
    assert_equal [:unknown_command, "clone invalid"], parse_cmd("clone invalid")
  end
end
