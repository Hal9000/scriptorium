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

  def see_file(file)
    puts "----- File: #{file}"
    system("cat #{file}")
    puts "-----"
  end

end
