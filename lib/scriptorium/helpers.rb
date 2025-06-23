# Path magic

module PathSep
  def /(right)
    s1 = self.to_s.dup
    s2 = right.to_s.dup
    s1 << "/" unless s1.end_with?("/") || s2.start_with?("/")
    path = s1 + s2
    path.gsub!("//", "/")
    path
  end
end

String.include(PathSep)
Symbol.include(PathSep)

## Helpers

module Scriptorium::Helpers
  def getvars(file)
    lines = File.readlines(file)
    lines.map! {|line| line.sub(/ #.*$/, "").strip }
    # FIXME - what if variable value has a # in it?
    vhash = Hash.new("")
    lines.each do |line|
      var, val = line.split(" ", 2)
      vhash[var] = val
    end
    vhash
  end

  def d4(num)
    "%04d" % num
  end

  def view_dir(name)
    @root/:views/name
  end

  def make_dirs(*dirs, top: nil)
    dir0 = top ? "#{top}/" : ""
    Dir.mkdir(dir0) unless Dir.exist?(dir0)
    dirs.each do |dir|
      Dir.mkdir(dir0/dir)
    end
  end

  def make_empty_file(file)
    FileUtils.touch(file)
  end

  def write_file(file, *lines)
    # dir = file.sub(/\/[a-zA-Z_\.]+$/, "") rescue "."
    File.open(file, "w") do |f|
      lines.each {|line| f.puts line }
    end
  end
end

