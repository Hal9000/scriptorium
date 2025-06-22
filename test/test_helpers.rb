module TestHelpers

  def dir_exist?(dir)
    assert Dir.exist?(dir), "Directory '#{dir}' was not found"
  end

end
