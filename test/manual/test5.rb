require_relative './environment'

manual_setup

srand(42)  # for random posts

view = @repo.create_view("testview", "Another Test View", "testing pagination for post index")

35.times do |i|
  ts = Time.now.strftime("%H:%M:%S")
  puts "#{i} - created at #{ts}"
  @repo.create_post(title: pseudowords(5, "Post #{i} @ #{ts} "), body: pseudolines(10))
  sleep(rand(5)/10.0)
end

view.generate_front_page

examine view
