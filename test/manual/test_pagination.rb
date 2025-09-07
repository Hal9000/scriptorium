require_relative './environment'

manual_setup

srand(42)  # for random posts

view = @repo.create_view("testview", "Another Test View", "testing pagination for post index")

35.times do |i|
  post = @repo.create_post(title: pseudowords(5, "Post #{i}"), body: pseudolines(10))
  post.set_pubdate_with_seconds("2025-07-26", i)  # Set seconds to 00, 01, 02, etc.
  @repo.generate_post(post.id)
end

view.generate_front_page

instruct <<~EOS
  Creates 35 posts (now instant!)
  Posts have timestamps 12:00:00, 12:00:01, 12:00:02, etc.
  Confirm they are in "recent first" order -- 35 down to 1
  Confirm pagination works
EOS

examine view
