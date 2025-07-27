require_relative './environment'

# Handle --automated flag at the end
automated_mode = ARGV.last == '--automated'
if automated_mode
  ARGV.pop  # Remove --automated from ARGV
end

abort "Need a view name (blog1 blog2 blog3)" unless ARGV.size == 1

view = ARGV.first

# Restore --automated flag for the examine function
ARGV << '--automated' if automated_mode

manual_setup

srand(42)  # for random posts

create_3_views
create_13_posts_manual
alter_pubdates

view = @repo.lookup_view(view)

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
