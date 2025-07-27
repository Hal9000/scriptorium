# Set up environment for manual tests
ENV['PATH'] = "#{ENV['HOME']}/.rbenv/shims:#{ENV['PATH']}"

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

include TestHelpers

def manual_setup
  system("rm -rf test/scriptorium-TEST")

  @repo = Scriptorium::Repo.create(true)  # true for testing mode

  @pid = nil
  Dir.chdir(File.expand_path("..", __dir__)) do
    Process.spawn ("ruby -run -e httpd . -p 8000 >/dev/null 2>&1") 
    sleep 1
    puts "webrick started\n "
  end
end

def instruct(msg)
  lines = msg.split("\n")
  longest = lines.map {|line| line.length }.max
  puts "  +" + "-" * (longest + 4) + "+"
  lines.each do |line|
    puts "  | #{line.ljust(longest + 2)} |"
  end
  puts "  +" + "-" * (longest + 4) + "+"
  puts
end

def examine(view)
  view = @repo.lookup_view(view)
  index_url = "http://127.0.0.1:8000/scriptorium-TEST/views/#{view.name}/output/index.html"
  puts "Generated front page located at: \n#{index_url}"
  
  if ARGV.include?('--automated')
    # Automated mode - just validate files were created
    index_file = "test/scriptorium-TEST/views/#{view.name}/output/index.html"
    if File.exist?(index_file)
      puts "✓ Files generated successfully"
    else
      puts "✗ Error: Index file not generated"
      exit 1
    end
    return
  end
  
  puts "Press Enter to open the generated front page to inspect the result."
  STDIN.gets
  cmd = "open #{index_url}"
  see("cmd = ", cmd)
  system("open #{index_url}")

  puts "Press Enter to kill webrick"
  STDIN.gets
  line = `ps | grep "ruby -run -e httpd" | grep -v grep`
  pid = line.split.first
  puts "line: #{line}"
  puts "pid: #{pid}"
  pid2 = pid.to_i + 1
  system("kill #{pid} #{pid2}")
  puts "Killed\n "
end
