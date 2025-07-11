# manual_test_script.rb

require_relative '../../lib/scriptorium'  # Adjust this path based on your project structure

system("rm -rf scriptorium-TEST")

# Step 1: Create a new repo (if not already existing)
repo = Scriptorium::Repo.create(true)  # true for testing mode, change as needed

# Step 2: Create a view for the repo
repo.create_view("testview", "Test View", "A test view for manual inspection")

# Step 3: Add posts to the view with multiline bodies
# Post 1
draft_1_body = <<~BODY
  This is the first post.

  It contains multiple paragraphs:
  - Introduction to the topic.
  - A deep dive into the details.
  - Conclusion with key takeaways.

  This should span multiple lines in the draft.
BODY

name1 = repo.create_draft(title: "Post 1", views: ["testview"], body: draft_1_body)
num = repo.finish_draft(name1)
repo.generate_post(num)

# Post 2
draft_2_body = <<~BODY
  This is the second post.

  - Discussing the second topic.
  - Elaborating on several points.
  - Wrapping up with some additional comments.

  It also spans multiple lines in the draft.
BODY

name2 = repo.create_draft(title: "Post 2", views: ["testview"], body: draft_2_body)
num = repo.finish_draft(name2)
repo.generate_post(num)



# Step 5: Generate the front page
repo.generate_front_page("testview")

# Step 6: Output path for manual inspection
index_path = repo.root/:views/"testview"/:output/"index.html"
puts "Generated front page located at: #{index_path}"

# Step 7: Inform the user to inspect the result
puts "Please open the generated front page to inspect the result."


