# manual_test_script.rb

require_relative '../../lib/scriptorium'  # Adjust this path based on your project structure

system("rm -rf scriptorium-TEST")

# Step 1: Create a new repo (if not already existing)
repo = Scriptorium::Repo.create(true)  # true for testing mode, change as needed

pid = nil
Dir.chdir("scriptorium-TEST") do
  pid = Process.spawn ("ruby -run -e httpd . -p 8000 >/dev/null 2>&1") 
  puts "WebRick pid = #{pid}\n "
end
sleep 2

# Step 2: Create a view for the repo
repo.create_view("testview", "Test View", "A test view for manual inspection")

# Step 3: Add posts to the view with multiline bodies
# Post 1
draft_1_body = <<~BODY
  .blurb It's sort of the William Riker of blog posts.
  This is the first post.

  It contains multiple paragraphs:
  - Introduction to the topic.<br>
  - A deep dive into the details.<br>
  - Conclusion with key takeaways.<br>

  This should span multiple lines in the draft.
BODY

name1 = repo.create_draft(title: "Post number one", views: ["testview"], body: draft_1_body)
num = repo.finish_draft(name1)
repo.generate_post(num)

# Post 2
draft_2_body = <<~BODY
  .blurb In Roman numerals, this is post II.
  This is the second post.

  - Discussing the second topic.<br>
  - Elaborating on several points.<br>
  - Wrapping up with some additional comments.<br>

  It also spans multiple lines in the draft.
BODY

name2 = repo.create_draft(title: "Post number two", views: ["testview"], body: draft_2_body)
num = repo.finish_draft(name2)
repo.generate_post(num)



# Step 5: Generate the front page
repo.generate_front_page("testview")

# Step 6: Output path for manual inspection
index_path = repo.root/:views/"testview"/:output/"index.html"
index_path.sub!("./scriptorium-TEST", "http://127.0.0.1:8000")
puts "Generated front page located at: #{index_path}"

# Step 7: Inform the user to inspect the result
puts "Press Enter to open the generated front page to inspect the result."

gets

system("open #{index_path}")

puts "Enter y to kill webrick"
resp = gets.chomp
if resp == 'y'
  system("kill #{pid}")
  system("kill #{pid + 1}")   # child
  puts "Killed"
else
  puts "NOT killed"
end
