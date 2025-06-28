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

end
