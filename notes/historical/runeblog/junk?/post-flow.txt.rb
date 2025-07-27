# lib/repl.rb

  def cmd_legacy_draft(arg, testing = false)
    reset_output
    check_empty(arg)
    old_file = ask("\nImport draft from: ")
    lines = File.readlines(old_file)
puts "--- Lines = #{lines.size}"
puts lines
puts
    title = lines.grep(/.title /).first[7..-1].chomp
 puts "Title is: #{title.inspect}"
    @blog.create_new_post(title, file: old_file)
    STDSCR.clear
    @out
  rescue => err
    out = "/tmp/blog#{rand(100)}.txt"
    File.open(out, "w") do |f|
      f.puts err
      f.puts err.backtrace.join("\n")
    end
    puts "Error: See #{out}"
  end

# lib/runeblog.rb

  def create_new_post(title, testing = false, file: nil, teaser: nil, body: nil, 
                      pubdate: Time.now.strftime("%Y-%m-%d"), views: [])
    log!(enter: __method__, args: [title, testing, teaser, body, views], level: 1, stderr: true)
    meta = nil
    views = views + [self.view.to_s]
    views.uniq!
    legacy_draft = file
    Dir.chdir(@root/:posts) do
      post = Post.create(title: title, teaser: teaser, body: body, pubdate: pubdate, views: views, file: legacy_draft)
      post.edit unless testing
      post.build
      meta = post.meta
    end
    return meta.num
  rescue => err
    _tmp_error(err)
  end

# lib/post.rb

  def self.create(title:, teaser:, body:, pubdate: Time.now.strftime("%Y-%m-%d"),
                  views:[], file: nil)
    log!(enter: __method__, args: [title, teaser, body, pubdate, views], stderr: true)
    post = self.new
    # NOTE: This is the ONLY place next_sequence is called!
    num = post.meta.num   = post.blog.next_sequence

    # new_metadata
    post.meta.title, post.meta.teaser, post.meta.body, post.meta.pubdate = 
      title, teaser, body, pubdate
    post.meta.views = [post.blog.view.to_s] + views
    post.meta.tags = []
    post.blog.make_slug(post.meta)  # adds to meta

    # create_draft
    viewhome = post.blog.view.publisher.url
    meta = post.meta
    if file.nil?
      text = RuneBlog.post_template(num: meta.num, title: meta.title, date: meta.pubdate, 
                 view: meta.view, teaser: meta.teaser, body: meta.body,
                 views: meta.views, tags: meta.tags, home: viewhome)
      srcdir = post.blog.root/:drafts + "/"
      vpdir = post.blog.root/:drafts + "/"
      fname  = meta.slug + ".lt3"
      post.draft = srcdir + fname
      dump(text, post.draft)
    else
      dump(File.read(file), post.draft)
    end
    return post
  end


  def build
    log!(enter: __method__)
    post = self
    views = post.meta.views
    text = File.read(@draft)
    @blog.generate_post(@draft)
  end

# lib/runeblog.rb

  def generate_post(draft)
    log!(enter: __method__, args: [draft], level: 1)
    views = _get_views(draft)
    views.each {|view| _handle_post(draft, view) }
  rescue => err
    _tmp_error(err)
  end

