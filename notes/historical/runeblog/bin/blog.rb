#!/usr/bin/env ruby

# $LOAD_PATH << "./lib"

require 'runeblog'
require 'rubytext'

require 'menus'

require 'repl'

include RuneBlog::REPL

def yesno(question, noskip=false)
  puts fx("\n  #{question}", :bold)
  puts unless noskip
  STDSCR.yesno
end

def pick_editor
  choices = %w[vim emacs vi nano]
  r, c = STDSCR.rc
  num, name = STDSCR.menu(r: r, c: c+6, title: "Default editor", items: choices)
  file = `which #{name}`.chomp
end

def get_universal
  univ = "#{@blog.root}/data/universal.lt3"
  if yesno("Faster initial setup? (no: edit universal.lt3)")
    #   author = ask!("      Author name: ")
    #   site   = ask!("      Site/domain: ")
    # Temporarily, for speed:
    author, site = "Hal Fulton", "somedomain.com"
    puts "      Author name: #{author}"
    puts "      Site/domain: #{site}"
    # Now stash it...
    str = File.read(univ)
    str = str.gsub(/AUTHOR/, author)
    str = str.gsub(/SITE_DOMAIN/, site)
    File.write(univ, str)
  else
    vim_params = '-c ":set hlsearch" -c ":hi Search ctermfg=2 ctermbg=6" +/"\(AUTHOR.*\|SITE.*\)"'
    edit_file(univ, vim: vim_params)
  end
end

def get_global
  view_name = ask!("      Filename: ")
  @blog.create_view(view_name)   # call change_view??
  if yesno("Faster view setup? (no: edit global.lt3)")
    title     = ask!("      View title: ")
    subtitle  = ask!("      Subtitle  : ")
    domain    = ask!("      Domain    : ")
    modify_view_global(view_name)
    modify_view_settings(name: view_name, title: title, subtitle: subtitle,
                         domain: domain)
  else
    vim_params = '-c ":set hlsearch" -c ":hi Search ctermfg=2 ctermbg=6" +/"\(VIEW_.*\|SITE.*\)"'
    edit_file(@blog.view.dir/"themes/standard/global.lt3", vim: vim_params)
  end
end

def get_started
  if yesno("Do you want to qo a quick setup?")
    puts "      First choose your editor."
    @blog.editor = pick_editor
    File.write("#{@blog.root}/data/EDITOR", @blog.editor)
    print "      Default editor is "
    puts  fx(@blog.editor, :bold)

    get_universal
    # Now create a custom global.lt3
    @blog._generate_global
    puts fx("\n  Quick setup complete!", :bold)
    if yesno("Create your first view now?")
      get_global
      puts fx("\n      View #{@blog.view} created!\n ", :bold)
    end
  end

  print fx("  For help", :bold);      puts " type h or help."
  print fx("  Create a view", :bold); puts  " with: new view"
  print fx("  Create a post", :bold); puts " (within current view): new post"
end

def mainloop
  info = @blog.view || "no view"
  print fx("[#{info}] ", Red, :bold)
  cmd = STDSCR.gets(history: @cmdhist, tab: @tabcom, capture: [" "]).chomp
  case cmd
    when " ", RubyText::Keys::Escape
      Dir.chdir(@blog.view.dir)
      show_top_menu
      puts
      return
    when RubyText::Keys::CtlD    # ^D
      cmd_quit
    when String
      return if cmd.empty?  # CR does nothing
      invoking = RuneBlog::REPL.choose_method(cmd)
      ret = send(*invoking)
  else
    puts "Don't understand '#{cmd.inspect}'\n "
  end
rescue => err
  log!(str: err.to_s)
  log!(str: err.backtrace.join("\n")) if err.respond_to?(:backtrace)
  puts "Current dir = #{Dir.pwd}"
  puts err
  puts err.backtrace.join("\n")
  puts "Pausing..."; gets
end

def cmdline_preview
  _need_view
  local = @blog.view.local_index
  result = system("open #{local}")
end

def cmdline_publish
  abort "Not implemented yet"
  _need_view
end

def cmdline_browse
  abort "Not implemented yet"
  _need_view
end

def _need_view
  @view = ARGV[1]
  abort "Need 'view' parameter" if @view.nil?
  abort "No such view '#{view}'" unless @blog.view?(@view)
end

def cmdline_rebuild
  _need_view
  print "Generating view... "
  @blog.generate_view(@view)
  print "Generating index... "
  num = @blog.generate_index(@view)
  puts "#{num} posts\n "
end

def handle_cmdline
  cmd = ARGV[0]
  @blog = RuneBlog.new
  abort "No blog found" if @blog.nil?

  case cmd
    when "rebuild"; cmdline_rebuild
    when "publish"; cmdline_publish
    when "preview"; cmdline_preview
    when "browse";  cmdline_browse
  else
    puts "Command '#{cmd}' is unknown"
  end
  exit
end

def check_ruby_version
  major, minor = RUBY_VERSION.split(".").values_at(0,1)
  ver = major.to_i*10 + minor.to_i
  unless ver >= 24
    RubyText.stop
    sleep 0.2
    puts "Needs Ruby 2.4 or greater" 
    exit
  end
end

def reopen_stderr
  errfile = File.new("stderr.out", "w")
  STDERR.reopen(errfile)
end

def set_fgbg
  # read a .rubytext file here?? Call it something else?
  home = ENV['HOME']
  @fg, @bg = Blue, White   ##  FIXME!! try_read_config("#{home}/.rubytext", fg: Blue, bg: White)
  @fg = @fg.downcase.to_sym
  @bg = @bg.downcase.to_sym

  RubyText.start(:_echo, :keypad, scroll: true, log: "binblog.txt", fg: @fg, bg: @bg)
end

def create_new_repo?
  new_repo = false
  if ! RuneBlog.exist?
    exit unless yesno("No blog repo found. Create new one?")
    RuneBlog.create_new_blog_repo
    puts fx("  Blog repo successfully created.", :bold)
    new_repo = true
  end

  @blog = RuneBlog.new
  get_started if new_repo
rescue => err
  STDERR.puts "Error - #{err.to_s}"
  STDERR.puts err.backtrace if err.respond_to?(:backtrace)
end

def print_intro
  print fx("  For help", :bold)
  puts " type h or help.\n "

  puts fx("\n  RuneBlog", :bold), fx(" v #{RuneBlog::VERSION}\n", Red)
end

def cmd_history_etc
  @cmdhist = []
  @tabcom = RuneBlog::REPL::Patterns.keys.uniq - RuneBlog::REPL::Abbr.keys
  @tabcom.map! {|x| x.sub(/ [\$\>].*/, "") + " " }
  @tabcom.sort!
end

def exit_repl
  # RubyText.stop
  sleep 0.2
  puts
end

### Main

include RuneBlog::Helpers  # for try_read_config

reopen_stderr
check_ruby_version

handle_cmdline unless ARGV.empty?
set_fgbg
print_intro
create_new_repo?

cmd_history_etc
loop { mainloop }
exit_repl
