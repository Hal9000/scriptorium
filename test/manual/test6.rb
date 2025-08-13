require_relative './environment'

manual_setup

srand(42)  # for random posts

create_3_views
create_13_posts_manual
alter_pubdates

view = @repo.view("blog3")
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
  f.puts "right  20%"
end
view.generate_empty_containers
File.open(view.dir/:config/"right.txt", "w") do |f|
  f.puts "widget links"
  f.puts "widget pages"
end

# Set up the Links widget
data = view.dir/:widgets/"links/list.txt"
Dir.mkdir(view.dir/:widgets/"links")
File.open(data, "w") do |f|
  f.puts "https://www.google.com,Google"
  f.puts "https://www.yahoo.com,Yahoo"
end
see_file data

# Set up the Pages widget with two dummy pages
pages_dir = view.dir/:widgets/"pages"
Dir.mkdir(pages_dir)

# Create the list.txt file that the Pages widget reads
File.open(pages_dir/"list.txt", "w") do |f|
  f.puts "about"
  f.puts "contact"
end

# Create the actual page files
File.open(view.dir/:pages/"about.html", "w") do |f|
  f.puts "<html><head><title>About Us</title></head><body>"
  f.puts "<h1>About Us</h1>"
  f.puts "<p>Learn more about our company and mission</p>"
  f.puts "<p><a href=\"index.html\">← Back to Home</a></p>"
  f.puts "</body></html>"
end
File.open(view.dir/:pages/"contact.html", "w") do |f|
  f.puts "<html><head><title>Contact</title></head><body>"
  f.puts "<h1>Contact</h1>"
  f.puts "<p>Get in touch with our team</p>"
  f.puts "<p><a href=\"index.html\">← Back to Home</a></a></p>"
  f.puts "</body></html>"
end

see_file pages_dir/"list.txt"
see_file view.dir/:pages/"about.html"
see_file view.dir/:pages/"contact.html"

view.generate_front_page

instruct <<~EOS
  Again, 13 posts in three views
  blog3 will have only header, main, right
  It will have both the Links widget and Pages widget in the right sidebar
  Click the + to expand widgets
  Links open in new tabs
  Pages show dummy content (About Us and Contact)
EOS

examine view
