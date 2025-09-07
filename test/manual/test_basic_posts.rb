require_relative "./environment"

manual_setup

@repo.create_view("testview", "Test View", "A test view for manual inspection")

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

name1 = @repo.create_draft(title: "Post number one", views: ["testview"], body: draft_1_body)
num = @repo.finish_draft(name1)
@repo.generate_post(num)

# Post 2
draft_2_body = <<~BODY
  .blurb In Roman numerals, this is post II.
  This is the second post.

  - Discussing the second topic.<br>
  - Elaborating on several points.<br>
  - Wrapping up with some additional comments.<br>

  It also spans multiple lines in the draft.
BODY

name2 = @repo.create_draft(title: "Post number two", views: ["testview"], body: draft_2_body)
num = @repo.finish_draft(name2)
@repo.generate_post(num)

@repo.generate_front_page("testview")   # Generate the front page

instruct <<~EOS
  Front page should have two posts.
  Each should have a blurb.
  Links should work (and back button to return).
EOS
examine("testview")
