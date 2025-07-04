class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def initial_post(mode = :filled, 
                    num:   "0", 
                    title: nil, 
                    views: nil,
                    tags:  nil,
                    body:  nil)

    # FIXME - screwed up?
    title ||= "ADD TITLE HERE"
    views ||= %w[sample]
    tags  ||= %w[sample tags]
    body  ||= "BEGIN HERE..."

    str = 
    <<~EOS
      . Initial file created by StandardFiles#post_template(num)
      
      .id %{num}
      .created %{created}
      
      .title %{title}
      
      .views %{views}  
      .tags  %{tags}   
      
      . Start of post body:
      #{body}
    EOS

    return str if mode == :raw
    str2 = str % {num: d4(num.to_i), created: ymdhms, title: title, 
                  views: views.join(" "), tags: tags.join(", ")}
    return str2
  end

  def post_template(theme)
    str = <<~EOS
      <!-- theme: #{theme} -->
      <div style="display: flex; justify-content: space-between; align-items: baseline;">
        <span style="text-align: left; font-size: 1.5em;">%{post.title}</span>
        <span style="text-align: right; font-size: 0.9em;">%{post.pubdate}</span>
      </div>
      <hr>
      %{post.body}
      <hr>
      <div style="text-align: right; font-size: 0.8em;">%{post.tags}</div>
    EOS
  end

def layout_text
  layout_text = <<~TXT
  header      # Top (banner? title? navbar? etc.)
  left   20%  # Left sidebar, 20% width
  main        # Main (center) container - posts/etc.
  right  20%  # Right sidebar, 20% width
  footer      # Footer (copyright? mail? social media? etc.)
TXT
end

def index_entry
  <<~EOS
    <div class="index-entry">
      <div style="font-size: 0.8em">$post.pubdate</div>
      <div class="post-title" style="font-size: 1.2em">$post.title</div>
      <div class="post-blurb" style="font-size: 0.8em">$post.blurb</div>
    </div>
  EOS
end

def theme_header     # Add theme name to these files??
  <<~EOS
    # Contents of header
    # (may include banner, title, navbar, ...)
  EOS
end

def theme_footer
  <<~EOS
    # Contents of footer
  EOS
end

def theme_left
  <<~EOS
    # Contents of left sidebar
    # (may be widgets or whatever)
  EOS
end

def theme_right
  <<~EOS
    # Contents of right sidebar
    # (may be widgets or whatever)
  EOS
end

def theme_main
  <<~EOS
   # Contents of center pane
   # This may be empty, as it is "usually" populated
   # by Javascript (list of recent posts, content from
   # a widget, or whatever)
  EOS
end

def scriptor
  <<~EOS
    .def id
      setvar("post.id", api.args.first)
    .end

    .def title
      setvar("post.title", api.data)
    .end

    .def created
      setvar("post.created", Time.now.strftime("%Y-%m-%d %H-%M-%S"))
    .end

    .def views
      setvar("post.views", api.data.strip)
    .end

    .def tags
      setvar("post.tags", api.data.strip)
    .end
  EOS
end

end