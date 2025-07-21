require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

include TestHelpers

def manual_setup
  system("rm -rf scriptorium-TEST")

  @repo = Scriptorium::Repo.create(true)  # true for testing mode

  @pid = nil
  Dir.chdir("scriptorium-TEST") do
    Process.spawn ("ruby -run -e httpd . -p 8000 >/dev/null 2>&1") 
    sleep 1
    puts "webrick started\n "
  end
end

def examine(view)
  view = @repo.lookup_view(view)
  index_url = "http://127.0.0.1:8000/views/#{view.name}/output/index.html"
  puts "Generated front page located at: \n#{index_url}"
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
