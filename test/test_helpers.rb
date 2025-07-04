module TestHelpers

  def assert_dir_exist?(dir)
    assert Dir.exist?(dir), "Directory '#{dir}' was not found"
  end

  def assert_file_exist?(file)
    assert File.exist?(file), "File '#{file}' was not found"
  end

  def create_test_repo(viewname = nil)
    repo = Scriptorium::Repo.create(true)  # testing
    if viewname
      repo.create_view(viewname, "My Awesome Title", "Just another subtitle")
    end
    repo
  end

  def assert_file_contains?(file, str)
    text = File.read(file)
    text.include?(str)
  end

  def assert_file_lines(file, num)
    lines = File.readlines(file)
    assert lines.size == num, "Expected #{num} lines in #{file}"
  end

  def see_file(file)
    puts "----- File: #{file}"
    system("cat #{file}")
    puts "-----"
  end

  def assert_wildcard_exist?(pattern)
    glob = Dir.glob(pattern)
    assert glob.size == 1, "Wildcard '#{pattern}' - expected 1 entry"
  end

  def assert_generated_post_found?(repo, num, views)
    id4 = d4(num)
    views = [views] if views.is_a?(String)
    assert_file_exist?(repo.root/:posts/id4/"body.html")
    assert_file_exist?(repo.root/:posts/id4/"meta.txt")
    views.each do |view|
      assert_wildcard_exist?(repo.root/:views/view/:output/:posts/"#{id4}-*.html")
    end
  end

  def random_post(repo, views: nil)
    views ||= []
    views = [views] if views.is_a?(String)
    rnum = rand(10000).to_i
    name = repo.create_draft(title: "Random Post #{rnum}", 
                             body:  "Just a (#{rand(10000).to_i}) random post",
                             views: views)
    num = repo.finish_draft(name)
    num
  end

  def try_post_with_views(repo, views)
    num = random_post(repo, views: views)
    repo.generate_post(num)
    assert_generated_post_found?(repo, num, views)
  end

  def num_posts_per_view(repo, view, exp)
    posts = repo.all_posts(view)
    assert posts.size == exp, "Expected #{exp} #{view} posts, found #{posts.size}"
  end
end
