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
      highlight      # See highlight_css.txt for syntax highlighting
      highlight_custom # Custom CSS overrides for Highlight.js
    EOS
    str
  end

  def common_js
    files = [
      'common_js/navigation.js',
      'common_js/content-loader.js',
      'common_js/syntax-highlighting.js',
      'common_js/clipboard.js'
    ]
    
    files.map { |file| support_data(file) }.join("\n\n")
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

  
  def initial_post(mode = :filled, num: "0", title: nil, blurb: nil, views: nil,
                  tags: nil, body:  nil)
    # FIXME - screwed up?
    title ||= "ADD TITLE HERE"
    blurb ||= "ADD BLURB HERE"
    views ||= %w[sample]
    tags  ||= %w[sample tags]
    body  ||= "BEGIN HERE..."

    str = support_data('templates/initial_post.lt3')

    return str if mode == :raw
    mytags = tags
    mytags = tags.join(", ") if tags.is_a?(Array)
    str2 = str % {num: d4(num.to_i), created: ymdhms, title: title, blurb: blurb,
                  views: views.join(" "), tags: mytags, body: body}
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

  def support_data(relative_path)
    read_file(support_file(relative_path))
  end

  def post_template
    support_data('templates/post.lt3')
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
