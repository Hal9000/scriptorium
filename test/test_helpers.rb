module TestHelpers

  include Scriptorium::Helpers
  
  # Disable Design by Contract in tests by default
  ENV['DBC_DISABLED'] = 'true'

  def assert_dir_exist?(dir)
    assert Dir.exist?(dir), "Directory '#{dir}' was not found"
  end

  def assert_file_exist?(file)
    assert File.exist?(file), "File '#{file}' was not found"
  end

  def create_test_repo
    Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)  # testing
  end

  def assert_file_contains?(file, str)
    text = File.read(file)
    text.include?(str)
  end

  def assert_file_lines(file, num)
    lines = File.readlines(file)
    assert lines.size == num, "Expected #{num} lines in #{file}; found #{lines.size}"
  end

  def assert_file_newer?(f1, f2)
    assert File.mtime(f1) > File.mtime(f2), "File #{f1} is not newer than #{f2}"
  end

  def assert_file_older?(f1, f2)
    assert File.mtime(f1) < File.mtime(f2), "File #{f1} is not older than #{f2}"
  end

  def assert_class(obj, klass)
    assert obj.is_a?(klass), "Expected a #{klass}, got #{obj.class}"
  end

  def see_file(file)
    puts "----- File: #{file}"
    system("cat #{file}")
    puts "-----"
  end

  def see(label, var)
    puts "#{label} = <<<\n#{var}"
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

  def post_with_views(repo, views)  # No assert - for manual tests
    num = random_post(repo, views: views)
    repo.generate_post(num)
  end

  def num_posts_per_view(repo, view, exp)
    posts = repo.all_posts(view)
    assert posts.size == exp, "Expected #{exp} #{view} posts, found #{posts.size}"
  end

  def create_post(repo, title: "Test Post", views: ["sample"], body: "Hello")
    draft = repo.create_draft(title: title, views: views, body: body)
    num = repo.finish_draft(draft)
    repo.generate_post(num)
    Scriptorium::Post.new(repo, num)
  end

  def assert_ordered(str, *targets)
    located = []
    targets.each do |t|
      located << str.index(t)
    end
    assert located == located.sort, "Targets out of order (#{located})"
  end

  def assert_present(str, *targets)
    result = true
    missing = []
    targets.each do |t|
      if ! str.include?(t)
        result = false
        missing << t
      end
    end
    assert result, "Targets missing: #{missing.join(", ").inspect}"
  end
  
  def create_3_views  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.create_view("blog1", "Blog 1", "nothing (1)")
    @repo.create_view("blog2", "Blog 2", "nothing (2)")
    @repo.create_view("blog3", "Blog 3", "nothing (3)")
  end

  def create_13_posts_manual
    post_with_views(@repo, "blog1")
    post_with_views(@repo, "blog2")
    post_with_views(@repo, "blog3")
    post_with_views(@repo, %w[blog1 blog2])
    post_with_views(@repo, %w[blog2 blog3])
    post_with_views(@repo, %w[blog1 blog3])
    post_with_views(@repo, %w[blog1 blog2 blog3])
    post_with_views(@repo, "blog1")
    post_with_views(@repo, "blog1")
    post_with_views(@repo, "blog1")
    post_with_views(@repo, "blog2")
    post_with_views(@repo, "blog2")
    post_with_views(@repo, "blog3")
  end

  def create_13_posts  # For test_posts_generated_and_indexed_across_multiple_views
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog3")
    try_post_with_views(@repo, %w[blog1 blog2])
    try_post_with_views(@repo, %w[blog2 blog3])
    try_post_with_views(@repo, %w[blog1 blog3])
    try_post_with_views(@repo, %w[blog1 blog2 blog3])
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog3")
    # blog1   1 4 6 7 8 9 10
    # blog2   2 4 5 11 12
    # blog3   3 5 6 7 13
  end

  def alter_pubdates  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.post(1).set_pubdate("2025-07-01")
    @repo.post(2).set_pubdate("2025-07-02")
    @repo.post(3).set_pubdate("2025-07-03")
    @repo.post(4).set_pubdate("2025-07-04")
    @repo.post(5).set_pubdate("2025-07-05")
    @repo.post(6).set_pubdate("2025-07-06")
    @repo.post(7).set_pubdate("2025-07-07")
    @repo.post(8).set_pubdate("2025-07-08")
    @repo.post(9).set_pubdate("2025-07-09")
    @repo.post(10).set_pubdate("2025-07-10")
    @repo.post(11).set_pubdate("2025-07-11")
    @repo.post(12).set_pubdate("2025-07-12")
    @repo.post(13).set_pubdate("2025-07-13")
  end

  def try_blog1_index  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.generate_post_index("blog1")  
    %w[header main right footer].each do |section|
      file = @repo.root/:views/"blog1"/:output/:panes/"#{section}.html"
      assert File.exist?(file), "Expected section file #{file} to exist"
    end
    @repo.tree("/tmp/blog1.txt")
    post_index = @repo.root/:views/"blog1"/:output/"post_index.html"
    assert File.exist?(post_index), "Expected blog1 post_index.html to be generated"
    content = File.read(post_index)
    
    assert content.include?("July 1</div>"), "Expected July 1 in post_index"
    assert content.include?("July 4</div>"), "Expected July 4 in post_index"
    assert content.include?("July 6</div>"), "Expected July 6 in post_index"
    assert content.include?("July 7</div>"), "Expected July 7 in post_index"
    assert content.include?("July 8</div>"), "Expected July 8 in post_index"
    assert content.include?("July 9</div>"), "Expected July 9 in post_index"
    assert content.include?("July 10</div>"), "Expected July 10 in post_index"
    refute content.include?("July 2</div>"), "Expected July 2 not in post_index"
    refute content.include?("July 3</div>"), "Expected July 3 not in post_index"
    refute content.include?("July 5"), "Expected July 5 not in post_index"
    refute content.include?("July 11"), "Expected July 11 not in post_index"
    refute content.include?("July 12"), "Expected July 12 not in post_index"
    refute content.include?("July 13"), "Expected July 13 not in post_index"
  end

  def pseudoword
    syllables = %w[tel mas re ko tem sil cro nim tes ran vel san tos le tor
                   de del mac dor mor ma ril odo tre kon lan sa te ti do mu]
    n = syllables.size
    num = rand(1..3)
    str = ""
    num.times { str << syllables[rand(n)] }
    str
  end

  def pseudowords(n, prefix = "")
    arr = [prefix]
    n.times { arr << pseudoword }
    arr.join(" ")
  end

  def pseudoline
    pseudowords(10) + "\n"
  end

  def pseudolines(n)
    str = ""
    n.times { str << pseudoline }
    str
  end

end
