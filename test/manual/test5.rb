require_relative './environment'

manual_setup

srand(42)  # for random posts

view = @repo.create_view("testview", "Another Test View", "testing pagination for post index")

35.times do |i|
  ts = Time.now.strftime("%H:%M:%S")
  puts "#{i} - created at #{ts}"
  @repo.create_post(title: pseudowords(5, "Post #{i} @ #{ts} "), body: pseudolines(10))
  sleep 1 
end

view.generate_front_page

instruct <<~EOS
  Creates 35 posts (takes time because of sleeps - this will change)
  Sleeps are so that posts will have different timestamps
  Confirm they are in "recent first" order -- 35 down to 1
  Confirm pagination works
EOS

examine view
