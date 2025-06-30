class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def initial_post(mode = :filled, 
                    num:   "0", 
                    title: "ADD TITLE HERE", 
                    views: %w[BLOG1 BLOG2 BLOG3],
                    tags:  %w[sample tags])
    title ||= "standard/post_template.lt3"
    views ||= %w[BLOG1 BLOG2 BLOG3]
    tags  ||= %w[sample tags]
    
    str = 
    <<~EOS
      . Initial file created by StandardFiles#post_template(num)
      
      .id %{num}
      .created %{created}
      
      .title %{title}
      
      .views %{views}  
      .tags  %{tags}   
      
      . Start of post body:
      BEGIN HERE...
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
        <span style="text-align: left; font-size: 1.5em;">%{title}</span>
        <span style="text-align: right; font-size: 0.9em;">%{pubdate}</span>
      </div>
      <hr>
      %{body}
      <hr>
      <div style="text-align: right; font-size: 0.8em;">%{tags}</div>
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