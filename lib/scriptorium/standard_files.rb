class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def html_head_content(view = nil)
    line1global = "# This global file supplies the default values for all views."
    line2view   = "# This view-specific file supplies the default values for this view."
    line1 = view ? line2view : line1global
    str = <<~EOS
      #{line1}
      # title is omitted - filled in at generation 
      charset    UTF-8
      desc       A blog powered by Scriptorium. This is default text intended to be changed by the user.
      viewport   width=device-width  initial-scale=1.0
      robots     index  follow
      javascript # See common.js 
      bootstrap  # See bootstrap.txt
    EOS
  end

  def common_js
    <<~EOS
      // This is the common JavaScript file for all views.
      // It is included in all views.
      <script type="text/javascript">
        function load_main(slug) {
          const contentDiv = document.getElementById("main");
          fetch(slug)  // This fetches a local file, such as post_123.html
            .then(response => response.text())
            .then(content => { contentDiv.innerHTML = content; })
            .catch(error => console.log("Error loading content:", error));
        }
      </script>

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

      <div align='right'><a style="text-decoration: none" href="javascript:history.go(-1)">
        <img src="assets/back-icon.png" width=24 height=24 alt="Go back"></img></a>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: baseline;">
        <!<span style="text-align: left; font-size: 1.5em;">%{post.title}</span>
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

def oldindex_entry
  <<~EOS
    <div class="index-entry" style="margin-bottom: 20px;">
      <div style="font-size: 0.8em">%{post.pubdate}</div>
      <div class="post-title" style="font-size: 1.2em">
        <a href="posts/%{post.slug}" 
           style="text-decoration: none;"
          onclick="load_main('%{post.slug}')">%{post.title}</a>
      </div>
      <div class="post-blurb" style="font-size: 0.8em">%{post.blurb}</div>
    </div>
  EOS
end

def post_index_style   # Not really a file
  <<~EOS
    <style>
    body { font-family: verdana }

    .recent-title a {
      color: #010101;
      font-family: verdana;
      font-size: 28px;
      float: right;
      display: inline-block;
      text-align: top;
      text-decoration: none;
    }

    .recent-title a:hover {
      text-decoration: none;
    }

    .recent-title-text a {
      color: #0101a1;
      font-family: verdana;
      font-size: 22px; 
      display: block;
      text-decoration: none;
    }

    .recent-title-text a:hover {
      text-decoration: none;
    }

    .recent-date {
      color: #9a9a9a;
      font-family: verdana;
      font-size: 15px;
      display: block;
      float: left;
      text-align: top;
    }

    .mydrop {
      color: #444444;
      float: left;
      text-align: top;
    # font-family: Verdana;
      font-size: 38px;
      line-height: 38px;
    # padding-top: 0px;
      padding-right: 8px;
      padding-left: 3px;
    }

    .thumbnail img {
        max-height: 100%;
        max-width: 100%;
    }
    </style>
  EOS
end

def index_entry
  # Note the use of %% to escape the % in the flex-basis attribute!
  <<~EOS
    <div class="index-entry" style="display: flex; justify-content: space-between; margin-bottom: 20px;">
      <!-- Left Side: Date (right aligned) -->
      <div style="text-align: right; font-size: 0.7em; flex-basis: 20%%;">
        <div>%{post.pubdate.month} %{post.pubdate.day}</div>
        <div>%{post.pubdate.year}</div>
      </div>
      <!-- Right Side: Title and Blurb (left aligned) -->
      <div style="font-size: 1.2em; margin-left: 10px; flex-grow: 1;">
        <div><a href="posts/%{post.slug}" 
                style="text-decoration: none;"
                onclick="load_main('%{post.slug}')">%{post.title}</a></div>
        <div style="font-size: 0.9em;">%{post.blurb}</div>
      </div>
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

    .def blurb
      setvar("post.blurb", api.data.strip)
    .end

    .def created
      t = Time.now
      setvar("post.created", t.strftime("%Y-%m-%d %H-%M-%S"))
      setvar("post.created.month", t.strftime("%B")) 
      setvar("post.created.day",   t.strftime("%d")) 
      setvar("post.created.year",  t.strftime("%Y")) 
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