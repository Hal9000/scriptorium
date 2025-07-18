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
  f.puts "right  25%"
end
File.open(view.dir/:config/"right.txt", "w") do |f|
  f.puts "widget links"
end

data = view.dir/:widgets/"links/list.txt"
Dir.mkdir(view.dir/:widgets/"links")
File.open(data, "w") do |f|
  f.puts "https://www.google.com,Google"
  f.puts "https://www.yahoo.com,Yahoo"
end
see_file data

view.generate_front_page

examine view
