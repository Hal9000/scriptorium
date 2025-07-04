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

  def random_post(repo, num = 1, views: nil)
    views ||= []
    name = repo.create_draft(title: "Random Post #{num}", 
                             body:  "Just a (#{rand(10000).to_i}) random post",
                             views: views)
    num = repo.finish_draft(name)
    repo.generate_post(num)
    num
  end
end
