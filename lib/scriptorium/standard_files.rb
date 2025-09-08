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
      social     # See social.txt for configuration
      highlight      # See prism_css.txt for syntax highlighting
      highlight_custom # Custom CSS overrides for Highlight.js
    EOS
    str
  end

  def common_js
    <<~EOS
      // Handle the back button (or JavaScript history.go(-1))
      window.onpopstate = function(event) {
        console.log('onpopstate event:', event); // Log the event object
        // Simply reload the page to avoid nesting issues
        window.location.reload();
      };

        // Initialize with the front page when navigating via the back button or similar
  window.onload = function() {
    // Check if the URL has a post parameter and load it automatically
    const urlParams = new URLSearchParams(window.location.search);
    const postParam = urlParams.get('post');
    
    if (postParam) {
      // URL has a post parameter, load the post content
      console.log('Auto-loading post from URL parameter:', postParam);
      load_main('index.html?post=' + postParam);
      return;
    }
    
    // Check if the initial state exists, if not, set it
    if (!history.state) {
       // Don't try to load post_index.html if there are no posts
       // The "No posts yet!" message is already in the main container
       history.replaceState({ slug: "index.html" }, "", "index.html");
    }
    

};

    // Load the main content and other page containers (header, footer, left, right)
    function load_main(slug) {
        // Get all container elements (header, footer, left, right, and main)
        const contentDiv = document.getElementById("main");
        const headerDiv = document.querySelector("header");
        const footerDiv = document.querySelector("footer");
        const leftDiv = document.querySelector(".left");
        const rightDiv = document.querySelector(".right");
        console.log('Loading main with slug:', slug); // Log the slug
        
        // Clear any existing content to prevent nesting
        contentDiv.innerHTML = '';
        contentDiv.dataset.currentSlug = slug;

                      // Check if this is a post parameter request
      if (slug.includes('?post=')) {
          const postSlug = slug.split('?post=')[1];
          console.log('Loading post:', postSlug);
          
                  // Load the post content - add .html extension if it's missing
        const postFile = postSlug.endsWith('.html') ? postSlug : postSlug + '.html';
              console.log('Fetching post file:', 'posts/' + postFile);
      fetch('posts/' + postFile)
            .then(response => {
                console.log('Response status:', response.status);
                if (response.ok) {
                    return response.text();
                } else {
                    console.error('Failed to load post:', response.status);
                    return 'Post not found';
                }
            })
                          .then(content => {
                console.log('Loaded content length:', content.length);
                console.log('Content preview:', content.substring(0, 200));
                contentDiv.innerHTML = content;
                
                        // Debug: Check what pre elements exist
        const allPreElements = contentDiv.querySelectorAll('pre');
        console.log('All pre elements found:', allPreElements.length);
        allPreElements.forEach((pre, index) => {
            console.log(`Pre element ${index}:`, pre.outerHTML.substring(0, 100));
        });

        // Highlight only the newly loaded content
        if (typeof hljs !== 'undefined') {
            // Find all code blocks in the new content and highlight them
            const codeBlocks = contentDiv.querySelectorAll('pre code[class*="language-"]');
            console.log('Found code blocks:', codeBlocks.length);
            if (codeBlocks.length > 0) {
                // Highlight each code block
                codeBlocks.forEach((codeBlock, index) => {
                    console.log(`Highlighting code block ${index}:`, codeBlock);
                    try {
                        hljs.highlightElement(codeBlock);
                        console.log(`Successfully highlighted code block ${index}`);
                    } catch (error) {
                        console.error(`Error highlighting code block ${index}:`, error);
                    }
                });
            }
        } else {
            console.log('hljs is not defined');
        }
                history.pushState({slug: 'index.html?post=' + postSlug}, "", 'index.html?post=' + postSlug);
            })
              .catch(error => {
                  console.log("Error loading post:", error);
                  contentDiv.innerHTML = 'Error loading post';
              });
          return;
      }

      // Check if this is a static page request (pages/, assets/, etc.)
      if (slug.startsWith('pages/') || slug.startsWith('assets/') || slug.includes('/')) {
          console.log('Loading static page:', slug);
          // Simple approach: always go back to index.html directory and fetch from there
          fetch(slug)
              .then(response => {
                  if (response.ok) {
                      return response.text();
                  } else {
                      console.error('Failed to load static page:', response.status);
                      return 'Page not found';
                  }
              })
              .then(content => {
                  contentDiv.innerHTML = content;
                  // Don't change the URL for static pages to avoid path resolution issues
                  history.pushState({slug: slug}, "", window.location.pathname);
              })
              .catch(error => {
                  console.log("Error loading static page:", error);
                  contentDiv.innerHTML = 'Error loading page';
              });
          return;
      }

      fetch(slug)
        .then(response => {
            if (response.ok) {
                console.log('Response is ok');
                return response.text();
            } else {
                console.error('Failed to load:', response.status); // Log the failed response
            }
        })
        .then(content => {
            console.log('Loaded content into div'); // Log successful content insertion

            // Now, reload the content into the respective containers:
            // Main section
            contentDiv.innerHTML = content;

            // Re-insert header, footer, left, and right (if necessary)
            // If you want the static layout to be kept, you can preserve these parts
            // with additional logic or predefined structure (here it's assumed 
            // that header/footer/left/right are already statically included).
            
            // You can also replace the other parts (left, right, header, footer) if needed.
            history.pushState({slug: slug}, "", slug);  // Update browser history
            

        })
        .catch(error => {
            console.log("Error loading content:", error); // Log any errors during fetch
        });
    }

    // Copy permalink to clipboard functionality
    function copyPermalinkToClipboard() {
        // Get the current post slug from the URL or construct it
        const currentUrl = window.location.href;
        let permalinkUrl;
        
        if (currentUrl.includes('?post=')) {
          // We're on the main blog page, construct the permalink URL
          const postSlug = currentUrl.split('?post=')[1];
          const baseUrl = window.location.origin + window.location.pathname.replace(/\\/[^\\/]*$/, '');
          permalinkUrl = baseUrl + '/permalink/' + postSlug;
        } else {
          // We're already on a permalink page, use current URL
          permalinkUrl = currentUrl;
        }
        
        navigator.clipboard.writeText(permalinkUrl).then(function() {
          // Change button text temporarily to show success
          const button = event.target;
          const originalText = button.textContent;
          button.textContent = 'Copied!';
          button.style.background = '#28a745';
          setTimeout(function() {
            button.textContent = originalText;
            button.style.background = '#007bff';
          }, 2000);
              }).catch(function(err) {
        console.error('Failed to copy: ', err);
        alert('Failed to copy link to clipboard');
      });
    }

            // Initialize highlight.js syntax highlighting
        if (typeof hljs !== 'undefined') {
          hljs.highlightAll();
        }
  EOS
  end


  def bootstrap_css
    <<~EOS
    href         https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css
    rel          stylesheet
    # integrity has a problem - compute instead?
    # integrity    sha384-KyZXEJ04F5o1v7V5b7ZMjGhGjxA8yQmBfvZwzI1r+0gEv+9KnQIMJxWwzD0u8nZ7
    # crossorigin  anonymous
    EOS
  end

  def bootstrap_js
    <<~EOS
    src          https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js
    # integrity has a problem - compute instead?
    # integrity    sha384-pzjw8f+ua7Kw1TIq0+v5+GZkR6P/6v03cI0myXcJU22Hc5p5BY5/X93HmaJXjm4C
    crossorigin  anonymous
    EOS
  end

  def highlight_css
    <<~EOS
    href         https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/default.min.css
    rel          stylesheet
    EOS
  end

  def highlight_custom_css
    <<~EOS
    <style>
    pre {
      max-height: none !important;
      height: auto !important;
      overflow: visible !important;
      background: #f5f2f0 !important;
      padding: 1em !important;
      margin: 1em 0 !important;
      border-radius: 0.3em !important;
      display: block !important;
    }
    pre code {
      white-space: pre-wrap !important;
      word-wrap: break-word !important;
      display: block !important;
    }
    pre code tt {
      white-space: normal !important;
      display: inline !important;
    }
    code {
      white-space: normal;
      display: inline;
    }
    /* Normal whitespace handling */
    #main {
      white-space: normal;
    }
    #main tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    .main tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    * tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    body tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    html tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    /* Normal paragraph styling - Bootstrap isolation not needed with proper HTML */
    #main p {
      margin: 0 0 1em 0;
    }
    #main p:last-child {
      margin-bottom: 0;
    }
    p:only-child {
      display: inline !important;
    }
    p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    /* More specific selectors to override Bootstrap */
    #main p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    body #main p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    html body #main p tt {
      white-space: nowrap !important;
      display: inline !important;
      float: none !important;
      clear: none !important;
    }
    /* Ensure br elements work for paragraph spacing */
    br {
      display: block !important;
      margin: 0 !important;
      padding: 0 !important;
      line-height: 1.2em !important;
    }
    </style>
    EOS
  end

  def highlight_js
    <<~EOS
    src          https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js
    EOS
  end

  def highlight_ruby_js
    <<~EOS
    src          https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/ruby.min.js
    EOS
  end

  def available_widgets
    <<~EOS
      links
      pages
      featuredposts
    EOS
  end

  def social_config
    <<~EOS
      # Available platforms: facebook twitter linkedin reddit
      # List one platform per line to enable social meta tags
      facebook
      twitter
      
      # Note: No Facebook App ID or Twitter username required for basic meta tags
      # These are only needed if you want to add social sharing buttons later
    EOS
  end

  def reddit_config
    <<~EOS
      # Reddit sharing button configuration
      # Set to true to show Reddit share button on posts
      button true
      
      # Optional: specify a subreddit for direct posting
      # Leave empty or omit to let users choose subreddit
      subreddit
      
      # Optional: custom hover text (defaults to "Share on Reddit" or "Share on [subreddit]")
      hover_text
    EOS
  end
  
  def initial_post(mode = :filled, num: "0", title: nil, blurb: nil, views: nil,
                  tags: nil, body:  nil)
    # FIXME - screwed up?
    title ||= "ADD TITLE HERE"
    blurb ||= "ADD BLURB HERE"
    views ||= %w[sample]
    tags  ||= %w[sample tags]
    body  ||= "BEGIN HERE..."

    str = 
    <<~EOS
      . Initial file created by StandardFiles#post_template(num)
      .created
      
      .title %{title}
      .blurb 
      %{blurb}
      .end
      
      .views %{views}  
      .tags  %{tags}   
      
      #{body}
    EOS

    return str if mode == :raw
    mytags = tags
    mytags = tags.join(", ") if tags.is_a?(Array)
    str2 = str % {num: d4(num.to_i), created: ymdhms, title: title, blurb: blurb,
                  views: views.join(" "), tags: mytags}
    return str2
  end

  def initial_post_metadata(num: "0", title: nil, blurb: nil, views: nil, tags: nil)
    title ||= "ADD TITLE HERE"
    blurb ||= "ADD BLURB HERE"
    views ||= %w[sample]
    tags  ||= %w[sample tags]

    mytags = tags
    mytags = tags.join(", ") if tags.is_a?(Array)

    <<~EOS
      post.id #{d4(num.to_i)}
      post.created #{ymdhms}
      post.published no
      post.deployed no
      post.title #{title}
      post.blurb #{blurb}
      post.views #{views.join(" ")}
      post.tags  #{mytags}
    EOS
  end

  def post_template(theme)
    str = <<~EOS
      <!-- theme: #{theme} -->
      <style>
      body { font-family: verdana; line-height: 1.1 }
      
      /* Dropcap styles */
      .dropcap {
        float: left;
        font-size: 3em;
        line-height: 0.8;
        margin: 0.1em 0.1em 0 0;
        padding: 0;
        font-weight: bold;
      }
      
      /* Pullquote styles */
      .pullquote {
        float: right;
        width: 200px;
        margin: 0 0 20px 20px;
        padding: 15px;
        background: #f5f5f5;
        border-left: 4px solid #333;
        font-size: 1.2em;
        font-style: italic;
        line-height: 1.4;
        color: #666;
        border-radius: 4px;
      }
      
      .pullquote-left {
        float: left;
        margin: 0 20px 20px 0;
      }
      
      .pullquote-right {
        float: right;
        margin: 0 0 20px 20px;
      }
      </style>

      <div align='right'><a style="text-decoration: none" href="index.html">
        <img src="assets/back-icon.png" width=24 height=24 alt="Go to Index"></img></a>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: baseline;">
        <span style="text-align: left; font-size: 1.5em;">%{post.title}</span>
        <span style="text-align: right; font-size: 0.9em;">%{reddit_button}%{post.date}</span>
      </div>
      <hr>
      %{post.body}
      <hr>
      <div style="text-align: right; font-size: 0.8em;">%{post.tags}</div>
      <div style="text-align: center; margin-top: 20px;">
        <button onclick="copyPermalinkToClipboard()" style="padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;">Copy link</button>
      </div>
    EOS
    str
  end

  def layout_text
    <<~EOS
      header      # Top (banner? title? navbar? etc.)
      left   15%  # Left sidebar, 15% width
      main        # Main (center) container - posts/etc.
      right  15%  # Right sidebar, 15% width
      footer      # Footer (copyright? mail? social media? etc.)
    EOS
  end

  def post_index_config
    <<~EOS
      posts.per.page 10
      entry.title.size 1.1em
      entry.blurb.size 0.75em
      entry.date.size 0.7em
      entry.date.width 14%
      entry.cellpadding 4
      entry.margin.bottom 6px
      entry.title.color #000000
      entry.blurb.color #666666
      entry.date.color #888888
      entry.line.height 1.1
      entry.date.alignment right
      entry.date.spacing 0.1em
      entry.date.format month dd, yyyy
      index.margin.top 20px
    EOS
  end

  def post_index_style   # Not really a file
    <<~EOS
      <style>
      body { font-family: verdana; line-height: 1.1 }

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

  # <!-- posts/%{post.slug}" --> 

  def index_entry
    # Note the use of %% to escape the % in the flex-basis attribute!
    <<~EOS
      <tr style="margin-bottom: %{entry.margin.bottom};">
        <td width=%{entry.date.width} valign=top align=right>
          <div style="text-align: %{entry.date.alignment}; font-size: %{entry.date.size}; color: %{entry.date.color}; line-height: %{entry.line.height};">
            <div style="height: %{entry.date.spacing};">&nbsp;</div>
            <div>%{formatted_date}</div>
          </div>
        </td>
        <td valign=top> 
          <div style="font-size: %{entry.title.size}; line-height: %{entry.line.height};">
            <div><a href="javascript:void(0)" 
                    style="text-decoration: none; color: %{entry.title.color};"
                    onclick="load_main('index.html?post=%{post.slug}')">%{post.title}</a></div>
            <div style="font-size: %{entry.blurb.size}; color: %{entry.blurb.color};">%{post.blurb}</div>
          </div>
        </td>
      </tr>
    EOS
  end

  def theme_header 
    <<~EOS
      # <!-- Section: header -->
      # Contents of header
      # (may include banner, title, navbar, ...)
      banner svg
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

  def svg_txt
    <<~EOS
      aspect          7.0  
      text.font       verdana  
      title.color     #cccccc
      subtitle.color  #cccccc
      text.justify    left   

      title.scale     0.8   
      subtitle.scale  0.4  

      title.style     bold  
      subtitle.style  bold italic 
      title.xy        5 50
      subtitle.xy     5 75

      back.linear #0000cc #000077 lr


    EOS
  end

  def deploy_text
    <<~EOS
      user      root
      server    %{domain}
      docroot   /var/www/html
      path      %{view}
      proto     https
    EOS
  end

  def status_txt
    <<~EOS
      header   n
      banner   n
      navbar   n
      left     n
      right    n
      pages    n
      deploy   n
    EOS
  end
end
