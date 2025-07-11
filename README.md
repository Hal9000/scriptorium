<b>Scriptorium</b> is a major refactoring (rewrite) of Runeblog, which had an unwieldy and
fragile code base. The plan now is to develop with more of a test-first approach (and
with AI support from ChatGPT and Gemini).
<p>

<hr>
<p>

<p>

<h2>Scriptorium Project Summary</h2>
<h3>ChatGPT checkpoint - July 8, 2025</h3>
<i>This file was a ChatGPT summary hand-edited and reuploaded to improve memory/response.</i>
<p>

<h4>1. Purpose, Assumptions, and Philosophy</h4>
<ul>
  <li>  Scriptorium is a minimalist, Ruby-based blogging engine and static site generator, serving as a clean-slate rewrite of the older Runeblog project.</li>
  <li>  Avoids complexity, external dependencies, and hidden magic.</li>
  <li>  Designed for users who prefer plain text and transparent, hackable systems.</li>
  <li>  Useful first for the software author, then hackers who blog, then possibly others</li>
</ul>
<h4>2. Technologies Used (or Avoided)</h4>
<ul>
  <li>  Ruby is the primary language.</li>
  <li>  Minitest for testing.</li>
  <li>  Livetext for content and templating.</li>
  <li>  Avoids YAML, Liquid, databases, JS frameworks.</li>
  <li>  Filesystem used in lieu of a database</li>
</ul>
<h4>3. Understanding Livetext</h4>
<ul>
  <li>  Lightweight markup processor.</li>
  <li>  Supports variable injection, custom directives, and flexible transformation to HTML.</li>
  <li>  Also supports: include, raw copy, function definitions</li>
  <li>  There is a plan for a later rewrite</li>
</ul>
<h4>4. General Terminology</h4>
<ul>
  <li>  <b>containers</b>   Named layout parts of a view’s front page (e.g., header, main, right, footer), generated from corresponding config text files.</li>
  <li>  <b>post</b>         A finalized blog entry with metadata, body content, and a unique ID; stored in the posts/ directory.</li>
  <li>  <b>draft</b>        A Livetext (.lt3) source file in the drafts/ directory, created before a post is finished.</li>
  <li>  <b>repo</b>         A Scriptorium::Repo instance representing a blog workspace, with standard directory structure, config files, and one or more views.</li>
  <li>  <b>view</b>         A named subset of the repo that acts as a blog/blog-like publication; includes its own output/, config/, and staging/ directories.</li>
  <li>  <b>theme</b>        A named collection of templates (HTML and Livetext) that define the look and layout of posts and index pages for a view.</li>
  <li>  <b>slug</b>         A URL-safe, hyphenated version of a post’s title, prefixed with its 4-digit ID, e.g., 0001-my-title.html.</li>
  <li>  <b>output</b>       A view-local directory holding generated HTML files, including post HTML and containers like header.html and main.html.</li>
  <li>  <b>meta.txt</b>     A key-value file under posts/NNNN/ holding post metadata (title, slug, pubdate, views, etc.).</li>
  <li>  <b>post_index</b>   A generated file in output/ listing recent posts in a view; usually post_index.html, composed of index-entry templates.</li>
</ul>
<h4>5. Git Repository Structure</h4>
<pre>
      .
      ├── README.md
      ├── doc
      ├── lib
      │   ├── scriptorium
      │   │   ├── exceptions.rb
      │   │   ├── helpers.rb
      │   │   ├── layout.rb
      │   │   ├── post.rb
      │   │   ├── repo.rb
      │   │   ├── standard_files.rb
      │   │   ├── theme.rb
      │   │   ├── version.rb
      │   │   └── view.rb
      │   ├── scriptorium.rb
      │   └── skeleton.rb
      ├── scriptorium.gemspec
      ├── test
      │   ├── integration
      │   │   └── integration_test.rb
      │   ├── post
      │   │   └── unit.rb
      │   ├── repo
      │   │   └── unit.rb
      │   └── test_helpers.rb
      └── themes
          └── standard
              ├── README.txt
              ├── assets
              ├── config.txt
              ├── header
              ├── initial
              │   └── post.lt3
              ├── layout
              │   ├── config
              │   │   ├── footer.txt
              │   │   ├── header.txt
              │   │   ├── left.txt
              │   │   ├── main.txt
              │   │   └── right.txt
              │   ├── gen
              │   │   ├── layout.css
              │   │   ├── layout.html
              │   │   └── text.css
              │   └── layout.txt
              └── templates
                  ├── index.lt3
                  ├── post.lt3
                  └── widget.lt3
</pre>
<p>

<p>

<h4>6. Blog Repository Structure</h4>
<i>This is a snapshot of a test run.</i>
<pre>
<p>

      ./scriptorium-TEST
      ├── assets
      ├── config
      │   ├── currentview.txt
      │   └── last_post_num.txt
      ├── drafts
      ├── posts
      │   ├── 0001
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0002
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0003
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0004
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0005
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0006
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0007
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0008
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0009
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0010
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0011
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   ├── 0012
      │   │   ├── assets
      │   │   ├── body.html
      │   │   ├── draft.lt3
      │   │   └── meta.txt
      │   └── 0013
      │       ├── assets
      │       └── draft.lt3
      ├── themes
      │   └── standard
      │       ├── README.txt
      │       ├── assets
      │       ├── config.txt
      │       ├── header
      │       ├── initial
      │       │   └── post.lt3
      │       ├── layout
      │       │   ├── config
      │       │   │   ├── footer.txt
      │       │   │   ├── header.txt
      │       │   │   ├── left.txt
      │       │   │   ├── main.txt
      │       │   │   └── right.txt
      │       │   ├── gen
      │       │   │   ├── layout.css
      │       │   │   ├── layout.html
      │       │   │   └── text.css
      │       │   └── layout.txt
      │       └── templates
      │           ├── index.lt3
      │           ├── index_entry.lt3
      │           ├── post.lt3
      │           └── widget.lt3
      └── views
          ├── blog1
          │   ├── config
          │   │   ├── footer.txt
          │   │   ├── header.txt
          │   │   ├── layout.txt
          │   │   ├── left.txt
          │   │   ├── main.txt
          │   │   └── right.txt
          │   ├── config.txt
          │   ├── layout
          │   │   ├── footer.html
          │   │   ├── header.html
          │   │   ├── left.html
          │   │   ├── main.html
          │   │   └── right.html
          │   ├── output
          │   │   ├── panes
          │   │   │   ├── footer.html
          │   │   │   ├── header.html
          │   │   │   ├── left.html
          │   │   │   ├── main.html
          │   │   │   └── right.html
          │   │   └── posts
          │   │       ├── 0001-random-post-7270.html
          │   │       ├── 0004-random-post-466.html
          │   │       ├── 0006-random-post-1685.html
          │   │       ├── 0007-random-post-6949.html
          │   │       ├── 0008-random-post-5311.html
          │   │       ├── 0009-random-post-6420.html
          │   │       └── 0010-random-post-4555.html
          │   └── staging
          .
          .   (skipped blog2 and blog3 for brevity)
          .
          └── sample
              ├── config
              │   ├── footer.txt
              │   ├── header.txt
              │   ├── layout.txt
              │   ├── left.txt
              │   ├── main.txt
              │   └── right.txt
              ├── config.txt
              ├── layout
              │   ├── footer.html
              │   ├── header.html
              │   ├── left.html
              │   ├── main.html
              │   └── right.html
              ├── output
              │   ├── panes
              │   │   ├── footer.html
              │   │   ├── header.html
              │   │   ├── left.html
              │   │   ├── main.html
              │   │   └── right.html
              │   └── posts
              └── staging
</pre>
<p>

<h4>7. State of Progress</h4>
<ul>
  <li>  Basic classes in place: Repo, View, Post, Theme, etc.</li>
  <li>  Unit tests for Repo (22 assertions) and Post (70 assertions)</li>
  <li>  Integration tests (257 assertions)</li>
  <li>  Can create a blog repo, views, posts</li>
  <li>  Theme "standard" is honored</li>
  <li>  Can generate a rudimentary "front page"</li>
  <li>  Working on: &lt;head&gt; generation, Bootstrap integration, etc.</li>
</ul>
<h4>8. Near-term high-level to-do list</h4>
<i>This is planned by August 31, 2025.</i>
<ul>
  <li>  Improved handling of blog header and &lt;head&gt; tag</li>
  <li>  Support for top-level menu</li>
  <li>  Improvements in Livetext blog plugin</li>
  <li>  Widget base class</li>
  <li>  Widgets: At least Featured, Links, and Pages</li>
  <li>  Isolate and codify all of API</li>
  <li>  Interactive (text) UI</li>
  <li>  Setup/config wizard(s)</li>
  <li>  Basic user docs</li>
</ul>
<h4>9. Notes on future to-do items</h4>
<ul>
  <li>  Improve the customized scriptorium plugin for Livetext</li>
  <li>  Define header far better (title, banner, navbar...)</li>
  <li>  Implement deployment, preview, and live view</li>
  <li>  Add concept of theme components (like mini-themes)</li>
  <li>  Support theme cloning</li>
  <li>  Support single-page post for viewing in isolation</li>
  <li>  Support permalinks</li>
  <li>  Support redirection (if needed) as posts change</li>
  <li>  Add user interfaces</li>
  <li>    -  simple command line calls</li>
  <li>    -  interactive text-oriented (TUI)</li>
  <li>    -  curses-like TUI based on RubyText</li>
  <li>    -  web-based (on localhost)</li>
  <li>  Add "wizards" for each UI: startup, add view, theming...</li>
  <li>  Add actual AI assistant</li>
  <li>  Codify a widget interface</li>
  <li>  Code widgets </li>
  <li>    -  Highlights (list featured posts)</li>
  <li>    -  Search (search within this blog/view)</li>
  <li>    -  Tags (a tag cloud)</li>
  <li>    -  Links (external links manager)</li>
  <li>    -  Calendar (posts by year/month/day)</li>
  <li>    -  Pages (local static pages unrelated to blog posts)</li>
  <li>  Add some level of support for Markdown (for others, not me)</li>
  <li>  Possibly add Atom/RSS support</li>
  <li>  Integrate Bootstrap calls as needed</li>
  <li>  Add support for reposting to Facebook, X (others?)</li>
  <li>  Add support for discussion threads on a subreddit</li>
  <li>  Create documentation:</li>
  <li>    -  User level (incl. basic Livetext, usage, theme creation)</li>
  <li>    -  Project contributor level</li>
  <li>    -  Widget creator level</li>
</ul>
