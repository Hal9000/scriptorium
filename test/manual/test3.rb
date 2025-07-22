require_relative './environment'

abort "Need a view name (blog1 blog2 blog3)" unless ARGV.size == 1

view = ARGV.first

manual_setup

srand(42)  # for random posts

create_3_views
create_13_posts_manual
alter_pubdates

instruct <<~EOS
  Three blogs created: blog1 blog2 blog3
  Browser goes to whichever you put on command line: #{view.name}
  You can also navigate to the others.
  Total of 13 posts 
  Each post may be in only one view or two or all three
EOS

%w[blog1 blog2 blog3].each do |v|
  @repo.generate_front_page(v)
end

examine view
