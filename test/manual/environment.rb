require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

include TestHelpers

def manual_setup
  system("rm -rf scriptorium-TEST")

  @repo = Scriptorium::Repo.create(true)  # true for testing mode

  @pid = nil
  Dir.chdir("scriptorium-TEST") do
    @pid = Process.spawn ("ruby -run -e httpd . -p 8000 >/dev/null 2>&1") 
    sleep 1
    puts "webrick started\n "
  end
end

def examine(view)
  index_path = @repo.root/:views/view/:output/"index.html"
  index_path.sub!("./scriptorium-TEST", "http://127.0.0.1:8000")
  puts "Generated front page located at: #{index_path}"
  puts "Press Enter to open the generated front page to inspect the result."
  STDIN.gets
  system("open #{index_path}")

  puts "Press Enter to kill webrick"
  STDIN.gets
  system("kill #@pid")
  system("kill #{@pid + 1}")   # child
  puts "Killed\n "
end
