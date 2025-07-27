require 'find'

list = Find.find(".") do |path|
  if File.basename(path).start_with? ARGV.first
    size = File.size(path)
    time = File.mtime(path)
    printf("%5d  %s  %s\n", size, time, path)
  end
end

