require 'rubytext'

  Help = <<-EOS

Commands:

Basics:                                           Views:
-------------------------------------------       -------------------------------------------
{h, help}           This message                  {change view VIEW}  Change current view
{q, quit}           Exit the program              {cv VIEW}           Change current view
{v, version}        Print version information     {new view}          Create a new view
                                                  {list views}        List all views available
                                                  {lsv}               Same as: list views
                 
Posts:                                            Advanced:
-------------------------------------------       -------------------------------------------
{p, post}           Create a new post             {config}            Edit various system files
{new post}          Same as p, post               {customize}         (BUGGY) Change set of tags, extra views
{lsp, list posts}   List posts in current view    {preview}           Look at current (local) view in browser
{lsd, list drafts}  List all drafts (all views)   {browse}            Look at current (published) view in browser
{delete ID [ID...]} Remove multiple posts         {rebuild}           Regenerate all posts and relink
{undelete ID}       Undelete a post               {publish}           Publish (current view)
{edit ID}           Edit a post                   {ssh}               Login to remote server
{import ASSETS}     Import assets (images, etc.)  {manage WIDGET}     Manage content/layout of a widget
  EOS

RubyText.start

Help.each_line do |line|
  e = line.each_char
  first = true
  loop do
    s1 = ""
    c = e.next
    if c == "{"
      s2 = first ? "" : "  "
      first = false
      loop do 
        c = e.next
        break if c == "}"
        s2 << c
      end
      print fx(s2, :bold)
      s2 = ""
    else
      s1 << c
    end
    print s1
  end
end


gets
