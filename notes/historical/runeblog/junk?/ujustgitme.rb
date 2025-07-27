require 'rubytext'

def modified(r0, c0)
  rcprint r0,   c0, fx("q", :bold, Yellow), fx("  Quit", :normal)
  rcprint r0+1, c0, fx("A", :bold, Yellow), fx("  Add all", :normal)
  RubyText.splash("Work with\nmodified files...")
end

def committed(r0, c0)
  rcprint r0,   c0, fx("q", :bold, Yellow), fx("  Quit", :normal)
  RubyText.splash("Work with the\ncommitted files...")
end

def untracked(r0, c0)
  rcprint r0,   c0, fx("q", :bold, Yellow), fx("  Quit", :normal)
  RubyText.splash("Work with the\nuntracked files...")
  getch
end

def mode(num, r, c)
  case num
    when 0; modified(r, c)
    when 1; committed(r, c)
    when 2; untracked(r, c)
  end
end

RubyText.start

RubyText.hide_cursor

lines = `git status --porcelain`.split("\n")

mod, com, unt = [], [], []
lines.each do |line|
  file = line.split[1]
  case line[0..1]
    when " M"
      mod << file
    when "M "
      com << file
    when "??"
      unt << file
  end
end

@high = [mod.size, com.size, unt.size].max

@top = STDSCR.rows - @high - 8
@left = (STDSCR.cols - 3*(25+2))/2

win1 = RubyText.window(@high+2, 25, r: @top, c: @left)
rcprint @top, @left+3, fx("Modified", :bold)

win2 = RubyText.window(@high+2, 25, r: @top, c: @left+26)
rcprint @top, @left+29, fx("Committed", :bold)

win3 = RubyText.window(@high+2, 25, r: @top, c: @left+52)
rcprint @top, @left+55, fx("Untracked", :bold)

win1.puts mod.join("\n")
win2.puts com.join("\n")
win3.puts unt.join("\n")

headers = [[@left+3,  "Modified"], [@left+29, "Committed"], [@left+55, "Untracked"]]

which = 2
loop do 
  r0 = @top + @high + 3
  r0.upto(r0+2) {|row| rcprint row, 0, " "*STDSCR.cols }
  case getch
    when 9  # tab
      last, this = which, (which+1) % 3
      c1, head1 = headers[last]
      c2, head2 = headers[this]
      rcprint @top, c1, fx(head1, :bold, White)
      rcprint @top, c2, fx(head2, :bold, Yellow)
      which = (which+1) % 3
      mode(which, r0, c2)
    when "q"
      exit
  else
  end 
end

getch
