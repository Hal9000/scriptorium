class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def global_head
    <<~EOS
      <head>
        title     My Blog (powered by Scriptorium)
        charset   UTF-8
        desc      A blog powered by Scriptorium. This is default text intended to be changed by the user.
        viewport  width=device-width  initial-scale=1.0
        robots    index  follow
        bootstrap 
      </head>
    EOS
  end

  def bootstrap_txt
    <<~EOS
    href         https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/css/bootstrap.min.css
    rel          stylesheet
    integrity    sha384-KyZXEJ04F5o1v7V5b7ZMjGhGjxA8yQmBfvZwzI1r+0gEv+9KnQIMJxWwzD0u8nZ7
    crossorigin  anonymous
    EOS
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
    mytags = tags
    mytags = tags.join(", ") if tags.is_a?(Array)
    str2 = str % {num: d4(num.to_i), created: ymdhms, title: title, 
                  views: views.join(" "), tags: mytags}
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
  left   15%  # Left sidebar, 15% width
  main        # Main (center) container - posts/etc.
  right  15%  # Right sidebar, 15% width
  footer      # Footer (copyright? mail? social media? etc.)
TXT
end

def index_entry
  <<~EOS
    <div class="index-entry" style="margin-bottom: 20px;">
      <div style="font-size: 0.8em">%{post.pubdate}</div>
      <div class="post-title" style="font-size: 1.2em">%{post.title}</div>
      <div class="post-blurb" style="font-size: 0.8em">%{post.blurb}</div>
    </div>
  EOS
end

def theme_header     # Add theme name to these files??
  <<~EOS
    # <!-- Section: header -->
    # Contents of header
    # (may include banner, title, navbar, ...)
    title
  EOS
end

def theme_footer
  <<~EOS
    # <!-- Section: footer -->
    # Contents of footer
  EOS
end

def theme_left
  <<~EOS
    # <!-- Section: left -->
    # Contents of left sidebar
    # (may be widgets or whatever)
  EOS
end

def theme_right
  <<~EOS
    # <!-- Section: right -->
    # Contents of right sidebar
    # (may be widgets or whatever)
  EOS
end

def theme_main
  <<~EOS
    # <!-- Section: main -->
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