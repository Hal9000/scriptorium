<b>Scriptorium</b> is a major refactoring (rewrite) of Runeblog, which had an unwieldy and
fragile code base. The plan now is to develop with more of a test-first approach (and
with AI support from ChatGPT and Gemini).

<hr>

<h2>Scriptorium User Guide</h2>
<i>In progress</i>
<p>

# 1. Core Concepts

## What is Scriptorium?

Scriptorium is a static site generator designed for creating and managing multiple blogs or content sites from a single installation. It combines the simplicity of static file generation with the power of a multi-view architecture, allowing you to maintain several distinct websites with shared infrastructure.

### Static Files Philosophy

Scriptorium generates static HTML, CSS, and JavaScript files. This approach offers several key benefits:

- **Performance**: Static files load quickly and can be served efficiently by any web server
- **Reliability**: No server-side processing means fewer points of failure
- **Security**: No dynamic code execution reduces attack vectors
- **Scalability**: Static files can be served by CDNs and cached effectively
- **Simplicity**: No database setup, server configuration, or runtime dependencies

When you publish content with Scriptorium, it generates a complete set of static files that can be deployed to any web hosting service - from simple file hosting to sophisticated CDN networks.

### Multi-View Architecture

Scriptorium's most distinctive feature is its **multi-view architecture**. Instead of managing separate installations for different blogs or websites, you can create multiple "views" within a single Scriptorium repository.

**What is a view?**
A view represents a complete, independent website or blog. Each view has its own:
- Configuration settings
- Theme and styling
- Content (posts, pages, widgets)
- Deployment settings
- URL structure

**Why use views?**
- **Efficiency**: Manage multiple sites from one installation
- **Consistency**: Share themes, templates, and infrastructure
- **Flexibility**: Each view can have completely different content and styling
- **Maintenance**: Update core functionality across all views at once

For example, you might have:
- A personal blog view
- A professional portfolio view  
- A project documentation view
- A photo gallery view

All managed from the same Scriptorium installation, with shared themes and infrastructure but completely independent content.

### Repository Structure

A Scriptorium repository is a directory that contains everything needed to manage your views and generate your websites. The repository structure follows a logical organization:

```
scriptorium/
├── config/          # Global configuration files
├── views/           # Individual view directories
│   ├── personal/    # Personal blog view
│   ├── portfolio/   # Professional portfolio view
│   └── docs/        # Documentation view
├── drafts/          # Draft posts (global)
├── posts/           # Generated posts (global)
├── assets/          # Shared images and files
├── themes/          # Theme templates
└── scripts/         # Utility scripts
```

**Key Repository Concepts:**
- **Global vs View-specific**: Some content (like posts) is global and can be shared across views, while other content (like view configuration) is specific to each view
- **Separation of concerns**: Content, presentation, and configuration are clearly separated
- **Version control friendly**: The entire repository can be managed with Git or similar tools

### Deployment Overview

Scriptorium generates static files that can be deployed to virtually any web hosting service. The deployment process is straightforward:

1. **Generate content**: Scriptorium processes your content and generates static HTML files
2. **Upload files**: Transfer the generated files to your web server
3. **Serve content**: Your web server serves the static files to visitors

**Deployment options include:**
- Traditional web hosting (shared hosting, VPS, dedicated servers)
- Static hosting services (Netlify, Vercel, GitHub Pages)
- Content delivery networks (CDN) for global performance
- Cloud storage with web serving capabilities

The static nature of Scriptorium's output means you have maximum flexibility in choosing where and how to host your content. [Detailed deployment instructions are covered in Section 9.]

## What is LiveText?

LiveText is a templating and content processing system that powers Scriptorium's content generation. It provides a simple, powerful way to create dynamic content while maintaining the benefits of static file generation.

### Why LiveText?

Scriptorium could have used any number of templating systems (Markdown, Liquid, ERB, etc.), but LiveText was chosen for several key reasons:

- **Simplicity**: LiveText syntax is straightforward and easy to learn
- **Power**: Despite its simplicity, LiveText is capable of complex content processing
- **Integration**: LiveText integrates seamlessly with Ruby, allowing for custom functions and logic
- **Flexibility**: LiveText can handle both simple content formatting and complex dynamic generation
- **Consistency**: LiveText provides a unified approach to content, templates, and configuration

LiveText bridges the gap between static content and dynamic generation, allowing you to create sophisticated websites while maintaining the performance and reliability benefits of static files.

### LiveText Syntax in Brief

LiveText uses a simple but powerful syntax based on "dot commands" and inline formatting. Here's a quick overview:

**Inline formatting:**
```
This is *bold and this is _italic text.
This is *[multiple words boldfaced].
```

**Dot commands with parameters:**
```
.title My Blog Post
.date 2025-07-29
.tags ruby, programming, blog

.link https://example.com Visit Example
.image /images/photo.jpg My Photo
```

**Dot commands with body content:**
```
.quote
  This is an inset quote.
  Wherever you go,
  there you are.
.end
```

**Variables and functions:**
```
This file is called $File (predefined var).
The current time is: $$time
This post has $$word_count words.
```

LiveText's syntax is designed to be readable and writable, making it easy to create content without getting bogged down in complex templating syntax. [Complete LiveText documentation is provided in Section 3.]

---
# 2. Getting Started

## Quick Installation

Scriptorium is distributed as a Ruby gem, making installation straightforward:

```bash
gem install scriptorium
```

**Prerequisites:**
- Ruby 2.7 or higher

After installation, you'll have access to the `scriptorium` command-line tool, which provides an interactive interface for managing your blogs and content.

## Interactive Setup

The easiest way to get started with Scriptorium is through the interactive setup process. Simply run:

```bash
scriptorium
```

This launches the interactive Scriptorium tool, which will guide you through the initial setup.

### Creating Your First Repository

When you first run Scriptorium, it will detect that no repository exists and offer to create one:

```
No repository found.
Create new repository? (y/n): y
```

The repository will be created in your home directory as `~/.scriptorium` by default. This directory will contain all your views, posts, themes, and configuration.

### Creating Your First View

After creating the repository, Scriptorium will offer to help you create your first view:

```
Do you want assistance in creating your first view? (y/n): y
```

A view represents a complete website or blog. You'll be prompted for:
- **View name**: A short identifier (e.g., "personal", "blog", "portfolio")
- **View title**: The full title that appears on your website
- **View subtitle**: An optional subtitle or description

For example:
```
View name: personal
View title: My Personal Blog
View subtitle: Thoughts on programming and life
```

### The Sample View

Scriptorium automatically creates a sample view to help you get started. This view includes:
- A basic theme with responsive design
- Sample configuration files
- Example posts and pages
- Widget configurations

You can explore the sample view to understand how Scriptorium works, then customize it or create new views for your specific needs.

### Basic Commands

Once your repository is set up, you can use these basic commands in the Scriptorium shell:

**View management:**
```
view                    # Show current view
list views              # List all views
change view <name>      # Switch to a different view
new view <name> <title> # Create a new view
```

**Content management:**
```
list posts             # List posts in current view
list drafts            # List draft posts
new post <title>       # Create a new post
```

**Generation and deployment:**
```
generate               # Regenerate current view
preview                # Preview current view locally
deploy                 # Deploy current view to server
```

**Help and information:**
```
help                   # Show available commands
version                # Show Scriptorium version
quit                   # Exit Scriptorium shell
```

## Basic Configuration

### Editor Setup

Scriptorium uses your preferred text editor for creating and editing content. For simplicity and lack of distraction, something like vim or emacs is recommended. (The ancient editor ed is mentioned here partly as a joke; but in fact, Scriptorium does use ed in automated testing.)

On first use, you'll be prompted to choose an editor:

```
Available editors:
  1. nano
  2. vim
  3. emacs
  4. ed

Choose editor (1-4): 1
```

Your choice is saved in `config/editor.txt` and will be used for all future editing sessions.

**Recommended editors:**
- **nano**: Simple and beginner-friendly
- **vim**: Powerful and efficient for experienced users
- **emacs**: Feature-rich with extensive customization
- **ed**: Minimal line editor for automation

### View Configuration

Each view has its own configuration file at `views/<viewname>/config.txt`. This file contains basic settings:

```
title My Personal Blog
subtitle Thoughts on programming and life
theme standard
```

**Key configuration options:**
- **title**: The main title of your website
- **subtitle**: A subtitle or description
- **theme**: The theme to use for this view
- **deploy_url**: The URL where this view is deployed (optional)

### Global Configuration

Global settings are stored in the `config/` directory:

- **editor.txt**: Your preferred text editor
- **last_post_num.txt**: Tracks the last post number used
- **currentview.txt**: Remembers which view was last active

Typically you would not change any of these manually. The last two especially are managed internally by Scriptorium.

## Checking Dependencies

Scriptorium includes a comprehensive dependency checker to ensure all required tools are available:

```bash
ruby scripts/check_dependencies.rb
```

This will check for:
- **Core dependencies**: Ruby (required for all features)
- **Feature dependencies**: 
  - Python 3 (for syntax highlighting and RSS validation)
  - Redd gem (Ruby Reddit API wrapper for autoposting)
  - LiveText (Scriptorium's templating system)
  - ImageMagick (for image processing and thumbnails)
  - Pygments (for code syntax highlighting)
  - Feed Validator (for RSS feed validation)
- **Configuration requirements**: SSH keys (for deployment), Reddit API credentials

The checker provides specific installation instructions for any missing dependencies.

**Example output:**
```
🔍 Scriptorium Dependency Checker
==================================================

📊 Dependency Status
==================================================

Individual Dependencies:
------------------------------
Ruby                      ✅ Available
Python 3                  ✅ Available
Redd gem (Reddit API)     ❌ Missing
LiveText                  ✅ Available
ImageMagick               ✅ Available

Feature Availability:
------------------------------
Core Blogging        ✅ Ready
Reddit Button        ✅ Ready
Reddit Autopost      ❌ Missing Dependencies
   Missing: redd
```

## The "Standard" Theme

Scriptorium comes with a single theme called "standard" that provides a clean, responsive design suitable for most blogs and websites.

The standard theme includes:
- **Responsive design**: Works well on desktop, tablet, and mobile
- **Clean typography**: Readable fonts and spacing
- **Flexible layout**: Header, footer, main content, and optional sidebars
- **Widget support**: Ready-to-use widgets for common content
- **Social integration**: Built-in support for social media features

Any future (or cloned) theme will have essentially the same structure. The standard theme is located in `themes/standard/` and includes:

```
themes/standard/
├── templates/          # LiveText templates
│   ├── post.lt3       # Individual post template
│   ├── index.lt3      # Front page template
│   └── widget.lt3     # Widget template
├── layout/            # Layout configuration
│   ├── layout.txt     # Layout definition
│   ├── config/        # Layout components
│   └── gen/           # Generated CSS/HTML
└── assets/            # Theme assets (images, etc.)
```

### Customizing the Theme

You can customize the standard theme by:
1. **Cloning it**: `clone standard mytheme` (creates a copy to modify)
2. **Editing templates**: Modify the LiveText templates in `templates/`
3. **Adjusting layout**: Change the layout configuration in `layout/`
4. **Adding assets**: Include custom images, CSS, or JavaScript

Predefined themes are considered immutable. Of course, there is only one at this point. Later on, there should be a distinction between predefined and user-defined (or cloned) themes.

[Detailed theme customization is covered in Section 7.]

---

# 3. LiveText Basics

## What is LiveText?

**[TO BE DONE]

---

# 4. The Front Page

## Containers and Their Uses

The front page of your Scriptorium view is built using a container-based layout system. Each container serves a specific purpose and can be configured independently:

**Front page containers:**
- **Header**: Contains the banner, navigation, and site branding
- **Left**: Optional sidebar for widgets and additional content
- **Main**: The primary content area, typically showing post listings
- **Right**: Optional sidebar for widgets and additional content
- **Footer**: Site footer with links and information

```
+------------------------------------------+
|                 Header                   |
|  (banner, title, subtitle, navigation)   |
+------------------------------------------+
|        |                    |            |
|  Left  |       Main         |   Right    |
| Sidebar|    (post index)    |  Sidebar   |
|        |                    |            |
+------------------------------------------+
|                 Footer                   |
+------------------------------------------+
```

## Configuring Header

### Banner and Title

The header configuration is defined in `views/<viewname>/config/header.txt`. The header can include:

```
# Header configuration example
title
subtitle
banner svg
nav
```

**Header components:**
- **title**: Displays the view title as an H1 heading
- **subtitle**: Displays the view subtitle as a paragraph
- **banner svg**: Generates an SVG banner using the BannerSVG system
- **banner <filename>**: Uses an image file as the banner
- **nav**: Includes navigation using `navbar.txt`
- **nav <filename>**: Uses a custom navigation file

### Navigation Bar

Navigation is configured in `views/<viewname>/config/navbar.txt` using a simple syntax:

```
=About                 
 Vision & Mission  mission
 Board of Directors    board
 Partners              partners
 How You Can Help      howtohelp
-Social Media          socmed
=Resources             
 Space links           links
 Space on Twitter      twitter
 Space on Instagram    instagram
 Space Newsfeeds       rssnews
-Companion sites       oursites
-Blog                  embed-blog
-Contact               contact
```

**Navigation syntax:**
- **=** - Top-level menu item with children
- **space** - Child of previous "=" item
- **-** - Top-level menu item without children
- **Label** - The text displayed in the menu
- **Filename** - The HTML file to open (without .html extension)

The navigation generates a Bootstrap navbar with responsive design.

## Configuring Sidebars

Sidebars are optional containers that can appear on the left or right side of your main content. They're perfect for widgets and additional information.

**Sidebar configuration:**
Sidebars are configured through the layout system and can contain widgets. The layout determines whether sidebars appear and on which side.

## The Main Container: Post Index

The main container is where your primary content appears. On the front page, this typically shows a listing of your blog posts:

**Post listing features:**
- **Chronological order**: Posts appear newest first
- **Post entries**: Each post shows title, date, and excerpt
- **Pagination**: Automatically paginates when you have many posts
- **Read more links**: Links to the full post content

## Widgets

Widgets are reusable content components that can be placed in sidebars. Scriptorium includes several built-in widgets:

### Links Widget

The Links widget displays a list of external links. Configuration is in `config/widgets.txt`:

```
links
```

**Links widget data:**
Links are defined in `config/links.txt` with one link per line:

```
https://ruby-lang.org, Ruby Language
https://github.com, GitHub
https://stackoverflow.com, Stack Overflow
```

**Format:** `URL, Title`

**Links widget features:**
- **External links**: Link to any external website
- **Simple configuration**: One link per line in CSV format
- **Automatic generation**: Creates clickable links with titles

### Pages Widget

The Pages widget displays links to your static pages. Configuration is in `config/widgets.txt`:

```
pages
```

**Pages widget data:**
Pages are defined in `config/pages.txt` with one page per line:

```
about
contact
mission
board
```

**Format:** `filename` (without .html extension)

**Pages widget features:**
- **Automatic discovery**: Finds pages in your `pages/` directory
- **Title extraction**: Automatically extracts titles from page HTML
- **Simple configuration**: Just list the page filenames

### Featured Posts Widget

The Featured Posts widget highlights specific posts. Configuration is in `config/widgets.txt`:

```
featuredposts
```

**Featured posts data:**
Posts are defined in `config/featuredposts.txt` with one post per line:

```
my-first-post
important-announcement
tutorial-series-part-1
```

**Format:** `post_id` or `post_id Title` (title is optional)

**Featured posts features:**
- **Manual selection**: Choose which posts to feature
- **Title fallback**: Uses post metadata if no title specified
- **Error handling**: Shows error message if post doesn't exist

## Widget Placement

While in theory, a widget can be placed in any container, typically they will go in a sidebar (left or right). Putting a widget anywhere else has not been tested, and you will be on your own.

**Widget configuration example:**
```
# In config/widgets.txt
links
pages
featuredposts
```

This enables all three available widgets. The layout system determines where they appear.

## Widget Data Files

Each widget requires a corresponding data file in the `config/` directory:

- **links.txt** - External links for the Links widget
- **pages.txt** - Page filenames for the Pages widget  
- **featuredposts.txt** - Post IDs for the Featured Posts widget

**Example data files:**

`config/links.txt`:
```
https://ruby-lang.org, Ruby Language
https://github.com, GitHub
```

`config/pages.txt`:
```
about
contact
mission
```

`config/featuredposts.txt`:
```
my-first-post
important-announcement
```

## Customizing Widget Appearance

Widgets generate HTML files in `widgets/<widgetname>/<widgetname>-card.html` that can be customized. Each widget uses Bootstrap styling and can be modified through CSS classes.

The front page layout system provides flexibility while maintaining consistency across your site. By combining different containers and widgets, you can create a front page that perfectly suits your content and audience. 

---

# 5. Managing Posts

**[Errors here - fix later. HF]

## Creating Posts

Creating new posts is one of the most common tasks in Scriptorium. Posts are the core content of your blog or website.

### Using the Interactive Shell

The easiest way to create a post is through the Scriptorium interactive shell:

```
scriptorium
```

Once in the shell, you have two options for creating content:

**Create a draft:**
```
new draft My First Blog Post
```

**Create a post directly:**
```
new post My First Blog Post
```

### Drafts vs Posts

**Drafts** are temporary files for working on content:
- Stored in `drafts/` directory
- Filename format: `YYYYMMDD-HHMMSS-draft.lt3`
- Use `list drafts` to see all drafts
- Use `new draft` to create a draft

**Posts** are the final published content:
- Stored in `posts/` directory
- Directory format: `posts/0123/` (4-digit padded numbers)
- Use `list posts` to see all posts
- Use `new post` to create a post directly

### Post File Structure

Each post consists of a directory with the following structure:

**Post directory:** `posts/0123/`
- **source.lt3**: The post content in LiveText format
- **meta.txt**: Post metadata
- **body.html**: Generated HTML (created during generation)
- **assets/**: Directory for post-specific assets

**Post metadata file:** `posts/0123/meta.txt`
- Contains post metadata like title, date, author
- Automatically generated and updated by Scriptorium

### Post Content Format

Posts use LiveText format (see Section 3 for details). A typical post structure:

```
.h1 My First Blog Post
.h2 subtitle: Getting Started with Scriptorium

.p This is my first blog post using Scriptorium.

.h2 Why Scriptorium?

.p Scriptorium makes blogging simple and powerful.

.list
  **Easy to use** - Simple command-line interface
  **Flexible** - Multiple views and themes
  **Fast** - Static site generation
  **Customizable** - LiveText templating system
.end

.p That's it for my first post!
```

## Listing Content

### View All Posts

To see all posts in your current view:

```
list posts
```

This shows:
- Post title
- Post number

### View All Drafts

To see all drafts:

```
list drafts
```

This shows:
- Draft filename
- Draft title

## Editing Posts

### Opening a Post for Editing

To edit an existing post, you'll need to open the post file directly in your editor. Posts are stored in `posts/0123/source.lt3`.

### Post Numbering

Post numbers are sequential integers with 4-digit padding:
- **Format**: 4-digit padded numbers (0001, 0002, 0003, etc.)
- **Automatic**: Numbers are assigned when posts are created
- **Sequential**: Numbers increment automatically

### Finding Post Numbers

You can find post numbers by:
1. Using `list posts` to see all posts
2. Looking in the `posts/` directory
3. Checking the post metadata file

## Deleting Posts

### Marking Posts for Deletion

To delete a post, Scriptorium moves the post directory to a deleted state:

- **Normal post**: `posts/0001/`
- **Deleted post**: `posts/_0001/` (with underscore prefix)

### Restoring Deleted Posts

To restore a deleted post, move the directory back from `posts/_0001/` to `posts/0001/`.

### Post Status

Posts can be in different states:
- **Published**: Post is live and visible on your site
- **Deleted**: Post is marked for deletion (moved to `_0001/` directory)

## Linking Posts

### Internal Links

You can link between posts using their post numbers:

```
.p Check out my [previous post](posts/0001.html) for more information.
```

### Cross-View Links

To link to a post in a different view:

```
.p See my [technical blog post](../tech/posts/0005.html) for more details.
```

## Unlinking Posts

### Removing Posts from Views

The `unlink_post` command removes a post from the current view but doesn't delete the post itself. It has no other effect on the post.

## Featured Posts

### Marking Posts as Featured

Featured posts appear in the Featured Posts widget (see Section 4). To feature a post:

1. Edit `widgets/featuredposts/list.txt`
2. Add the post number on a new line:

```
1
5
10
```

### Featured Post Order

Posts appear in the Featured Posts widget in the order listed in `widgets/featuredposts/list.txt`.

### Removing Featured Status

To remove a post from featured status:

1. Edit `widgets/featuredposts/list.txt`
2. Remove the post number from the list
3. Regenerate the view

## Post Organization

### Post Numbering

Scriptorium automatically assigns sequential post numbers:
- **Automatic**: Post numbers are assigned when posts are created
- **Sequential**: Numbers increment automatically (1, 2, 3, etc.)
- **Padded**: Stored as 4-digit padded numbers (0001, 0002, etc.)

### Post Sorting

Posts are typically displayed in chronological order (newest first), but you can customize this through:
- **Featured posts**: Manual ordering in the Featured Posts widget
- **Theme customization**: Modify how posts are sorted in your theme

### Post Categories

While Scriptorium doesn't have built-in categories, you can organize posts by:
- **Views**: Different views for different types of content
- **Tags**: Using tags in post content (see Section 3)
- **Featured posts**: Highlighting important posts

## Post Workflow

### Typical Post Creation Workflow

1. **Create**: `new post "Post Title"`
2. **Write**: Edit the post content in LiveText format
3. **Generate**: Use `generate` to build the final site
4. **Deploy**: Use `deploy` to publish to your server

### Draft Workflow

1. **Create draft**: `new draft "Draft Title"`
2. **Work on content**: Edit and refine the draft
3. **Convert**: When ready, convert draft to post

### Post Maintenance

Regular post maintenance tasks:
- **Review posts**: Use `list posts` to see all posts
- **Review drafts**: Use `list drafts` to see all drafts
- **Check links**: Verify internal links are working
- **Update featured**: Keep featured posts current
- **Clean up**: Remove old deleted posts

Most of this is intuitive. If it's not, the software probably was written incorrectly. 

---

# 6. Managing Pages

Pages in Scriptorium are static HTML files that provide additional content beyond your blog posts. They're perfect for creating "About" pages, contact information, documentation, or any other static content you want to make available on your site.

## Used in navbar

Pages can be linked directly in your site's navigation bar. This is typically configured in the header section of your view.

To add a page to your navbar:

1. **Create the page file** in your view's `pages/` directory:
   ```bash
   scriptorium edit pages/about.html
   ```

2. **Configure the navbar** in your view's header configuration:
   ```bash
   scriptorium edit config/header.txt
   ```

3. **Add navigation links** to your header configuration file. The exact format depends on your theme, but typically looks like:
   ```
   # Navigation links
   .nav-link "About" "pages/about.html"
   .nav-link "Contact" "pages/contact.html"
   ```

The navbar will automatically include these links, making your pages easily accessible from any part of your site.

## Used in Pages widget

Pages can also be displayed using the Pages widget, which creates a sidebar or footer list of your pages. This is useful for organizing related content or providing quick access to important pages.

To set up the Pages widget:

1. **Create the widget configuration**:
   ```bash
   scriptorium edit widgets/pages/list.txt
   ```

2. **Add page references** to the list file. Each line should contain the page filename (without the `.html` extension):
   ```
   about
   contact
   documentation
   ```

3. **Generate the widget**:
   ```bash
   scriptorium generate widget pages
   ```

The Pages widget will automatically:
- Extract titles from the HTML files (using `<title>` tags or `<h1>` tags)
- Create clickable links to each page
- Skip any pages that don't exist (with a warning)

## Internal links

Pages can link to each other and to blog posts using internal links. This creates a connected web of content within your site.

### Linking between pages

In your page HTML, use JavaScript-based links that work with Scriptorium's navigation system:

```html
<a href="javascript:void(0)" onclick="load_main('pages/other-page.html')">Link to Another Page</a>
```

### Linking from pages to posts

You can also link from pages to specific blog posts:

```html
<a href="javascript:void(0)" onclick="load_main('posts/post-slug.html')">Link to Blog Post</a>
```

### Linking from posts to pages

In your blog posts, you can link to pages using the same pattern:

```html
<a href="javascript:void(0)" onclick="load_main('pages/about.html')">About Us</a>
```

## Subdirectories under pages/

For better organization, you can create subdirectories under the `pages/` directory. This is useful for grouping related pages or creating more complex site structures.

### Creating subdirectories

```bash
# Create a subdirectory
mkdir pages/documentation

# Create pages within the subdirectory
scriptorium edit pages/documentation/getting-started.html
scriptorium edit pages/documentation/advanced-usage.html
```

### Linking to subdirectory pages

When linking to pages in subdirectories, include the full path:

```html
<a href="javascript:void(0)" onclick="load_main('pages/documentation/getting-started.html')">Getting Started</a>
```

### Using subdirectories in the Pages widget

In your `widgets/pages/list.txt` file, you can reference subdirectory pages using relative paths:

```
about
contact
documentation/getting-started
documentation/advanced-usage
```

### Best practices for page organization

- **Use descriptive filenames**: `about.html`, `contact.html`, `privacy-policy.html`
- **Group related content**: Use subdirectories for documentation, guides, or multi-part content
- **Keep navigation simple**: Don't create too many levels of subdirectories
- **Use consistent naming**: Stick to lowercase with hyphens for multi-word filenames
- **Include proper titles**: Always use `<title>` tags in your HTML for better widget integration

### Page templates and styling

Pages inherit the same styling as your main site, so they'll automatically match your theme. You can include additional CSS or JavaScript in individual pages if needed, but it's generally better to keep styling consistent across your site.

### Managing page content

Since pages are static HTML files, you can edit them using any text editor or HTML editor. Scriptorium provides convenient commands for common page operations:

```bash
# Create a new page
scriptorium edit pages/new-page.html

# List all pages in a view
ls views/your-view/pages/

# Generate all content (including pages)
scriptorium generate
```

Pages are a powerful way to extend your Scriptorium site beyond just blog posts, allowing you to create a complete website with multiple types of content. 

---

# 7. Customization

Scriptorium is designed to be highly customizable while maintaining simplicity. You can modify themes, create custom templates, and extend functionality through widgets and features.

## Themes and Styling (cloning)

Themes in Scriptorium control the overall look and feel of your site. Currently, Scriptorium comes with a "standard" theme, but you can clone and customize it to create your own unique design.

### Understanding themes

A theme consists of several components:
- **Layout templates**: HTML structure for different page types
- **CSS styling**: Visual appearance and responsive design
- **Configuration files**: Default settings and options
- **Assets**: Images, fonts, and other static files

### Cloning the standard theme

To create your own theme:

1. **Navigate to the themes directory**:
   ```bash
   cd themes
   ```

2. **Clone the standard theme**:
   ```bash
   cp -r standard my-custom-theme
   ```

3. **Update your view to use the new theme**:
   ```bash
   scriptorium edit config.txt
   ```
   
   Change the theme line to:
   ```
   theme: my-custom-theme
   ```

### Customizing CSS

The main styling is controlled by CSS files in your theme:

- **`layout.css`**: Overall layout and responsive design
- **`text.css`**: Typography and text styling
- **`bootstrap.css`**: Bootstrap framework (if used)

To modify the appearance:

1. **Edit the CSS files** in your theme directory:
   ```bash
   scriptorium edit themes/my-custom-theme/layout/gen/layout.css
   scriptorium edit themes/my-custom-theme/layout/gen/text.css
   ```

2. **Common customizations**:
   - Change colors and fonts
   - Modify spacing and layout
   - Add custom animations
   - Adjust responsive breakpoints

3. **Regenerate your site** to see changes:
   ```bash
   scriptorium generate
   ```

### Theme structure

Understanding the theme directory structure helps with customization:

```
my-custom-theme/
├── assets/           # Images, fonts, etc.
├── config.txt        # Theme configuration
├── header/           # Header templates
├── initial/          # Initial content templates
├── layout/           # Layout templates and CSS
│   ├── config/       # Layout configuration files
│   ├── gen/          # Generated CSS files
│   └── layout.txt    # Layout structure
└── templates/        # Main templates
    ├── index.lt3     # Front page template
    ├── post.lt3      # Individual post template
    └── widget.lt3    # Widget template
```

### Responsive design

Scriptorium themes are designed to work on various screen sizes. When customizing:

- **Mobile-first approach**: Start with mobile styles and enhance for larger screens
- **Flexible layouts**: Use CSS Grid and Flexbox for responsive layouts
- **Test on multiple devices**: Ensure your customizations work across different screen sizes

## Templates

Templates control how your content is structured and displayed. Scriptorium uses LiveText templates (`.lt3` files) that combine HTML structure with dynamic content.

### Main templates

The core templates in your theme:

- **`templates/index.lt3`**: Front page layout
- **`templates/post.lt3`**: Individual blog post layout
- **`templates/widget.lt3`**: Widget container layout

### Customizing post templates

To modify how blog posts are displayed:

1. **Edit the post template**:
   ```bash
   scriptorium edit themes/my-custom-theme/templates/post.lt3
   ```

2. **Available variables** in post templates:
   - `%{post.title}`: Post title
   - `%{post.body}`: Post content
   - `%{post.pubdate}`: Publication date
   - `%{post.tags}`: Post tags
   - `%{post.blurb}`: Post excerpt

3. **Example template structure**:
   ```
   <article class="post">
     <header>
       <h1>%{post.title}</h1>
       <time>%{post.pubdate}</time>
     </header>
     <div class="content">
       %{post.body}
     </div>
     <footer>
       <div class="tags">%{post.tags}</div>
     </footer>
   </article>
   ```

### Customizing the front page

The front page template controls how your blog index is displayed:

1. **Edit the index template**:
   ```bash
   scriptorium edit themes/my-custom-theme/templates/index.lt3
   ```

2. **Common customizations**:
   - Change the post listing format
   - Add featured post sections
   - Modify pagination
   - Include custom widgets

### Template inheritance and overrides

You can override specific templates for individual views:

1. **Create a view-specific template**:
   ```bash
   scriptorium edit views/my-view/templates/post.lt3
   ```

2. **The view-specific template** will be used instead of the theme template for that view

### LiveText in templates

Templates use LiveText syntax for dynamic content:

- **Variables**: `%{variable_name}`
- **Conditionals**: `.if condition` ... `.end`
- **Loops**: `.each item` ... `.end`
- **Includes**: `.include "file.lt3"`

## Widgets and Features

Widgets are modular components that add functionality to your site. Scriptorium comes with several built-in widgets, and you can create custom ones.

### Built-in widgets

#### Links widget

Displays a list of external links in a sidebar:

1. **Configure the widget**:
   ```bash
   scriptorium edit widgets/links/list.txt
   ```

2. **Add links** in the format `url, title`:
   ```
   https://example.com, Example Site
   https://github.com, GitHub Profile
   ```

3. **Generate the widget**:
   ```bash
   scriptorium generate widget links
   ```

#### Pages widget

Lists internal pages (see Section 6 for details):

1. **Configure the widget**:
   ```bash
   scriptorium edit widgets/pages/list.txt
   ```

2. **Add page references**:
   ```
   about
   contact
   documentation
   ```

#### Featured Posts widget

Highlights specific posts in a sidebar:

1. **Configure the widget**:
   ```bash
   scriptorium edit widgets/featuredposts/list.txt
   ```

2. **Add post references**:
   ```
   001 My Important Post
   002 Another Featured Post
   ```

### Adding widgets to your layout

To include widgets in your site:

1. **Edit your layout configuration**:
   ```bash
   scriptorium edit config/layout.txt
   ```

2. **Add widget containers** to your layout:
   ```
   header
   left   20%
   main
   right  20%
   footer
   ```

3. **Configure the sidebar** to include widgets:
   ```bash
   scriptorium edit config/left.txt
   ```

4. **Add widget references**:
   ```
   .widget links
   .widget pages
   .widget featuredposts
   ```

### Creating custom widgets

For advanced customization, you can create your own widgets:

1. **Create a widget directory**:
   ```bash
   mkdir -p widgets/my-custom-widget
   ```

2. **Create the widget configuration**:
   ```bash
   scriptorium edit widgets/my-custom-widget/config.txt
   ```

3. **Create the widget template**:
   ```bash
   scriptorium edit widgets/my-custom-widget/template.lt3
   ```

4. **Register the widget** in your view's configuration

### Widget styling

Widgets inherit styling from your theme, but you can add custom CSS:

1. **Create widget-specific CSS**:
   ```bash
   scriptorium edit themes/my-custom-theme/assets/widgets.css
   ```

2. **Include the CSS** in your layout templates

### Best practices for customization

- **Start small**: Make incremental changes and test frequently
- **Keep backups**: Save copies of working configurations
- **Use version control**: Track your customizations with git
- **Test thoroughly**: Ensure changes work across different content types
- **Document changes**: Keep notes on what you've customized

### Troubleshooting customizations

Common issues and solutions:

- **Changes not appearing**: Run `scriptorium generate` to rebuild
- **Broken layout**: Check for syntax errors in templates
- **Styling issues**: Verify CSS syntax and file paths
- **Widget not working**: Check widget configuration and file permissions

Customization in Scriptorium strikes a balance between flexibility and simplicity, allowing you to create unique sites while maintaining the core functionality and reliability of the platform. 
---

# 8. Advanced Features

Scriptorium includes several advanced features that extend its functionality beyond basic blogging. These features help you integrate with external platforms and enhance your site's social presence.

## Reddit Integration

Scriptorium includes built-in Reddit integration that allows you to automatically share your blog posts to Reddit. This feature helps increase your content's visibility and drive traffic to your site.

### Setting up Reddit integration

Before you can use Reddit integration, you need to create a Reddit application and configure your credentials:

1. **Create a Reddit application**:
   - Go to https://www.reddit.com/prefs/apps
   - Click "Create App" or "Create Another App"
   - Choose "script" as the application type
   - Fill in the required fields (name, description, redirect URI)
   - Note your client ID and client secret

2. **Configure Reddit credentials**:
   ```bash
   scriptorium edit config/reddit.json
   ```

3. **Add your Reddit credentials** to the configuration file:
   ```json
   {
     "client_id": "your_client_id_here",
     "client_secret": "your_client_secret_here",
     "username": "your_reddit_username",
     "password": "your_reddit_password",
     "user_agent": "scriptorium-bot/1.0"
   }
   ```

4. **Set appropriate permissions** for the configuration file:
   ```bash
   chmod 600 config/reddit.json
   ```

### Using Reddit integration

Once configured, you can automatically post to Reddit when you publish blog posts:

1. **Add Reddit metadata** to your blog posts:
   ```
   .title My Blog Post Title
   .reddit_subreddit programming
   .reddit_title My Blog Post Title
   .reddit_flair "Discussion"
   ```

2. **Available Reddit metadata**:
   - `.reddit_subreddit`: Target subreddit (e.g., "programming", "webdev")
   - `.reddit_title`: Custom title for Reddit (optional, uses post title if not specified)
   - `.reddit_flair`: Post flair (optional)
   - `.reddit_nsfw`: Mark as NSFW (true/false)
   - `.reddit_spoiler`: Mark as spoiler (true/false)

3. **Publish your post**:
   ```bash
   scriptorium publish 001
   ```

4. **The post will automatically be shared** to Reddit with the specified metadata

### Reddit integration best practices

- **Choose appropriate subreddits**: Target subreddits relevant to your content
- **Follow subreddit rules**: Ensure your content complies with each subreddit's guidelines
- **Use descriptive titles**: Make your Reddit titles compelling and accurate
- **Engage with comments**: Respond to comments on your Reddit posts
- **Don't spam**: Avoid posting too frequently to the same subreddits
- **Respect rate limits**: Reddit has API rate limits, so don't post too many times in quick succession

### Troubleshooting Reddit integration

Common issues and solutions:

- **Authentication errors**: Verify your credentials in `config/reddit.json`
- **Rate limiting**: Wait before posting again if you hit rate limits
- **Subreddit not found**: Check that the subreddit name is correct and exists
- **Permission denied**: Ensure your Reddit account has permission to post to the target subreddit

## Social Media Features

Scriptorium includes several features to enhance your social media presence and make your content more shareable.

### Social media metadata

Add social media metadata to your posts to improve how they appear when shared:

```
.title My Blog Post Title
.og_title My Blog Post Title
.og_description A compelling description of my blog post
.og_image /assets/my-featured-image.jpg
.twitter_card summary_large_image
.twitter_title My Blog Post Title
.twitter_description A compelling description for Twitter
.twitter_image /assets/my-featured-image.jpg
```

### Open Graph tags

Open Graph tags control how your content appears when shared on Facebook, LinkedIn, and other platforms:

- **`.og_title`**: Title for social media shares
- **`.og_description`**: Description for social media shares
- **`.og_image`**: Featured image for social media shares
- **`.og_type`**: Content type (article, website, etc.)
- **`.og_url`**: Canonical URL for the content

### Twitter Card tags

Twitter Card tags optimize your content for Twitter sharing:

- **`.twitter_card`**: Card type (summary, summary_large_image, app, player)
- **`.twitter_title`**: Title for Twitter shares
- **`.twitter_description`**: Description for Twitter shares
- **`.twitter_image`**: Image for Twitter shares
- **`.twitter_site`**: Your Twitter username
- **`.twitter_creator`**: Content creator's Twitter username

### Social sharing buttons

Add social sharing buttons to your posts:

1. **Configure social sharing** in your theme:
   ```bash
   scriptorium edit themes/my-theme/templates/post.lt3
   ```

2. **Add sharing buttons** to your post template:
   ```html
   <div class="social-share">
     <a href="https://twitter.com/intent/tweet?url=%{post.url}&text=%{post.title}" target="_blank">Share on Twitter</a>
     <a href="https://www.facebook.com/sharer/sharer.php?u=%{post.url}" target="_blank">Share on Facebook</a>
     <a href="https://www.linkedin.com/sharing/share-offsite/?url=%{post.url}" target="_blank">Share on LinkedIn</a>
   </div>
   ```

### RSS feeds

Scriptorium automatically generates RSS feeds for your content:

- **Main RSS feed**: `your-site.com/feed.xml`
- **Category-specific feeds**: `your-site.com/category/feed.xml`
- **Tag-specific feeds**: `your-site.com/tag/feed.xml`

### Email subscriptions

Set up email subscriptions for your blog:

1. **Configure email settings**:
   ```bash
   scriptorium edit config/email.txt
   ```

2. **Add subscription form** to your site:
   ```html
   <form action="/subscribe" method="post">
     <input type="email" name="email" placeholder="Enter your email">
     <button type="submit">Subscribe</button>
   </form>
   ```

### Analytics integration

Track your site's performance with analytics:

1. **Google Analytics**:
   ```bash
   scriptorium edit config/analytics.txt
   ```
   
   Add your Google Analytics tracking code:
   ```
   GA_TRACKING_ID: UA-XXXXXXXXX-X
   ```

2. **Other analytics services**:
   - Add tracking codes to your theme's header template
   - Configure privacy settings and cookie consent
   - Set up conversion tracking

### Social media automation

Automate your social media presence:

1. **Scheduled posting**: Set up automated posting to social platforms
2. **Cross-platform sharing**: Share content across multiple platforms simultaneously
3. **Content recycling**: Automatically reshare older content
4. **Engagement tracking**: Monitor likes, shares, and comments

### Best practices for social media

- **Consistent branding**: Use consistent colors, fonts, and imagery across platforms
- **Engage with your audience**: Respond to comments and messages
- **Post regularly**: Maintain a consistent posting schedule
- **Use hashtags strategically**: Research and use relevant hashtags
- **Monitor performance**: Track which content performs best
- **Optimize for each platform**: Tailor content for different social media platforms

### Privacy and security considerations

When using social media features:

- **Protect personal information**: Be careful with personal data in social media metadata
- **Use HTTPS**: Ensure your site uses HTTPS for secure sharing
- **Respect user privacy**: Implement appropriate privacy policies
- **Secure API keys**: Keep social media API keys and credentials secure
- **Monitor for abuse**: Watch for spam or inappropriate use of your social features

### Troubleshooting social media features

Common issues and solutions:

- **Images not appearing**: Check image paths and ensure images are publicly accessible
- **Metadata not updating**: Clear social media cache or use debugging tools
- **Sharing buttons not working**: Verify JavaScript is enabled and URLs are correct
- **Analytics not tracking**: Check tracking code installation and ad blockers

Advanced features in Scriptorium help you extend your reach beyond your blog and engage with audiences across multiple platforms. These features are designed to work seamlessly with your existing content while providing powerful tools for social media management and audience growth. 
---

# 9. Deployment & Hosting

Once you've created your Scriptorium site, you'll want to deploy it to make it accessible on the web. This section covers various deployment options, from local development to production hosting.

## Local Development

Before deploying to a server, you'll typically want to test your site locally to ensure everything works correctly.

### Local development server

Scriptorium generates static files that can be served by any web server. For local development:

1. **Generate your site**:
   ```bash
   scriptorium generate
   ```

2. **Start a local web server**:
   ```bash
   # Using Python (if available)
   cd output
   python -m http.server 8000
   
   # Using Ruby (if available)
   cd output
   ruby -run -e httpd . -p 8000
   
   # Using Node.js (if available)
   cd output
   npx serve -p 8000
   ```

3. **Access your site** at `http://localhost:8000`

### Live reload development

For a better development experience with automatic reloading:

1. **Install a live reload server**:
   ```bash
   # Using Node.js
   npm install -g live-server
   
   # Or using Python
   pip install livereload
   ```

2. **Start the development server**:
   ```bash
   cd output
   live-server --port=8000
   ```

3. **Your browser will automatically refresh** when you make changes to your site

### Testing different views

During development, you may want to test different views:

1. **Switch between views**:
   ```bash
   scriptorium view view-name
   ```

2. **Generate the specific view**:
   ```bash
   scriptorium generate
   ```

3. **Test the view** in your local development server

### Debugging local issues

Common local development issues and solutions:

- **Files not updating**: Ensure you're running `scriptorium generate` after changes
- **CSS not loading**: Check file paths and ensure CSS files are in the correct location
- **Images not displaying**: Verify image paths and file permissions
- **JavaScript errors**: Check browser console for errors and verify script paths

## Server Deployment

When you're ready to deploy your site to production, you have several hosting options available.

### Static hosting services

Static hosting services are ideal for Scriptorium sites since they generate static HTML files:

#### GitHub Pages

1. **Create a GitHub repository** for your site
2. **Push your Scriptorium repository** to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/username/repository-name.git
   git push -u origin main
   ```

3. **Enable GitHub Pages** in your repository settings
4. **Configure GitHub Actions** for automatic deployment (optional)

#### Netlify

1. **Sign up for Netlify** and connect your Git repository
2. **Configure build settings**:
   - Build command: `scriptorium generate`
   - Publish directory: `output`
3. **Deploy automatically** on every push to your repository

#### Vercel

1. **Sign up for Vercel** and import your Git repository
2. **Configure build settings**:
   - Build command: `scriptorium generate`
   - Output directory: `output`
3. **Deploy with automatic updates**

### Traditional web hosting

For traditional web hosting providers:

1. **Generate your site**:
   ```bash
   scriptorium generate
   ```

2. **Upload files** to your web server:
   ```bash
   # Using rsync (recommended)
   rsync -avz output/ user@your-server.com:/path/to/web/root/
   
   # Using scp
   scp -r output/* user@your-server.com:/path/to/web/root/
   
   # Using FTP/SFTP client
   # Upload all files from the output directory
   ```

3. **Set proper permissions**:
   ```bash
   chmod 644 output/*.html
   chmod 644 output/*.css
   chmod 644 output/*.js
   chmod 755 output/
   ```

### VPS deployment

For more control, deploy to a Virtual Private Server:

1. **Set up your VPS** with a web server (Apache, Nginx, etc.)
2. **Install required dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install nginx ruby ruby-dev
   
   # CentOS/RHEL
   sudo yum install nginx ruby ruby-devel
   ```

3. **Configure your web server** to serve static files
4. **Set up automatic deployment** with Git hooks or CI/CD

### Deployment automation

Automate your deployment process:

1. **Create a deployment script**:
   ```bash
   #!/bin/bash
   # deploy.sh
   
   # Generate the site
   scriptorium generate
   
   # Upload to server
   rsync -avz --delete output/ user@your-server.com:/path/to/web/root/
   
   # Clear cache (if using a CDN)
   # curl -X POST https://api.cloudflare.com/client/v4/zones/zone-id/purge_cache
   ```

2. **Make it executable**:
   ```bash
   chmod +x deploy.sh
   ```

3. **Run deployment**:
   ```bash
   ./deploy.sh
   ```

## Domain Configuration

Configure your domain name to point to your hosted site.

### DNS configuration

1. **Add DNS records** in your domain registrar's control panel:
   - **A record**: Point your domain to your server's IP address
   - **CNAME record**: Point `www` subdomain to your main domain
   - **MX records**: Configure email (if needed)

2. **Example DNS configuration**:
   ```
   Type    Name    Value
   A       @       192.168.1.100
   CNAME   www     yourdomain.com
   ```

### Subdomain setup

Set up subdomains for different sections of your site:

1. **Add subdomain DNS records**:
   ```
   Type    Name    Value
   A       blog    192.168.1.100
   A       docs    192.168.1.100
   ```

2. **Configure web server** to handle subdomains
3. **Set up separate Scriptorium repositories** for each subdomain (if needed)

### Domain verification

Verify your domain is properly configured:

1. **Check DNS propagation**:
   ```bash
   nslookup yourdomain.com
   dig yourdomain.com
   ```

2. **Test website accessibility**:
   ```bash
   curl -I http://yourdomain.com
   ```

3. **Check for redirects** and ensure they're working correctly

## SSL Setup

Secure your site with HTTPS using SSL certificates.

### Let's Encrypt (free SSL)

1. **Install Certbot**:
   ```bash
   # Ubuntu/Debian
   sudo apt install certbot python3-certbot-nginx
   
   # CentOS/RHEL
   sudo yum install certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate**:
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

3. **Auto-renewal setup**:
   ```bash
   sudo crontab -e
   # Add: 0 12 * * * /usr/bin/certbot renew --quiet
   ```

### Manual SSL certificate

For paid SSL certificates:

1. **Generate CSR (Certificate Signing Request)**:
   ```bash
   openssl req -new -newkey rsa:2048 -nodes -keyout yourdomain.key -out yourdomain.csr
   ```

2. **Submit CSR** to your certificate provider
3. **Install the certificate** on your web server
4. **Configure web server** to use SSL

### Web server SSL configuration

#### Nginx SSL configuration

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    location / {
        root /path/to/your/site;
        index index.html;
        try_files $uri $uri/ =404;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

#### Apache SSL configuration

```apache
<VirtualHost *:443>
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/certificate.crt
    SSLCertificateKeyFile /path/to/private.key
    
    DocumentRoot /path/to/your/site
    
    <Directory /path/to/your/site>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# Redirect HTTP to HTTPS
<VirtualHost *:80>
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    Redirect permanent / https://yourdomain.com/
</VirtualHost>
```

### SSL best practices

- **Use strong encryption**: Configure modern SSL protocols and ciphers
- **Enable HSTS**: Add HTTP Strict Transport Security headers
- **Regular renewal**: Set up automatic certificate renewal
- **Monitor certificate expiration**: Use monitoring tools to track certificate status
- **Backup certificates**: Keep secure backups of your SSL certificates and private keys

### Content Delivery Networks (CDN)

Improve site performance with a CDN:

1. **Choose a CDN provider** (Cloudflare, AWS CloudFront, etc.)
2. **Configure DNS** to point to CDN
3. **Set up caching rules** for static assets
4. **Configure SSL** through the CDN provider
5. **Monitor performance** and adjust settings as needed

### Deployment checklist

Before going live:

- [ ] Site generates without errors
- [ ] All links work correctly
- [ ] Images and assets load properly
- [ ] SSL certificate is installed and working
- [ ] Domain DNS is configured correctly
- [ ] Web server is configured properly
- [ ] Backup and recovery procedures are in place
- [ ] Monitoring and analytics are set up
- [ ] Error pages (404, 500) are configured
- [ ] Site is tested across different browsers and devices

Deploying your Scriptorium site can be as simple as uploading static files or as complex as setting up a full CI/CD pipeline. Choose the approach that best fits your needs, technical expertise, and budget. 
---

# 10. Troubleshooting

Even with the best setup, you may encounter issues while using Scriptorium. This section covers common problems and their solutions, helping you quickly resolve issues and get back to creating content.

## Common Issues

### Site generation problems

#### Site won't generate

**Symptoms**: Running `scriptorium generate` fails or produces errors.

**Possible causes and solutions**:

1. **Missing dependencies**:
   ```bash
   # Check if Ruby and required gems are installed
   ruby --version
   gem list
   
   # Reinstall Scriptorium if needed
   gem uninstall scriptorium
   gem install scriptorium
   ```

2. **Corrupted repository**:
   ```bash
   # Check repository integrity
   scriptorium status
   
   # If corrupted, restore from backup or recreate
   cp -r .scriptorium .scriptorium.backup
   scriptorium init
   ```

3. **Permission issues**:
   ```bash
   # Check file permissions
   ls -la
   
   # Fix permissions if needed
   chmod 755 .
   chmod 644 *.txt *.md *.lt3
   ```

#### Posts not appearing

**Symptoms**: Posts exist but don't show up on the site.

**Solutions**:

1. **Check post status**:
   ```bash
   scriptorium list posts
   ```

2. **Verify post is linked to current view**:
   ```bash
   scriptorium post 001
   # Check the "views" field
   ```

3. **Link post to view if needed**:
   ```bash
   scriptorium link 001
   ```

4. **Regenerate the site**:
   ```bash
   scriptorium generate
   ```

#### Images not displaying

**Symptoms**: Images appear broken or don't load.

**Solutions**:

1. **Check image paths**:
   ```bash
   # Verify image exists
   ls -la assets/images/
   
   # Check path in post
   scriptorium edit posts/001.lt3
   ```

2. **Correct image references**:
   ```
   # Use relative paths from the post
   ![Alt text](assets/images/my-image.jpg)
   
   # Or absolute paths from site root
   ![Alt text](/assets/images/my-image.jpg)
   ```

3. **Ensure images are in the correct directory**:
   ```bash
   # Move images to assets directory
   mv my-image.jpg assets/images/
   ```

### Widget issues

#### Widget not appearing

**Symptoms**: Widget is configured but doesn't show on the site.

**Solutions**:

1. **Check widget configuration**:
   ```bash
   scriptorium edit widgets/links/list.txt
   # Verify the file exists and has content
   ```

2. **Generate the widget**:
   ```bash
   scriptorium generate widget links
   ```

3. **Check layout configuration**:
   ```bash
   scriptorium edit config/layout.txt
   # Ensure sidebar containers are defined
   
   scriptorium edit config/left.txt
   # Ensure widget is referenced
   ```

4. **Regenerate the entire site**:
   ```bash
   scriptorium generate
   ```

#### Widget content not updating

**Symptoms**: Changes to widget configuration don't appear on the site.

**Solutions**:

1. **Regenerate the specific widget**:
   ```bash
   scriptorium generate widget widget-name
   ```

2. **Clear any caching**:
   ```bash
   # Remove generated files
   rm -rf output/
   scriptorium generate
   ```

### Theme and styling issues

#### Theme not applying

**Symptoms**: Site doesn't use the expected theme.

**Solutions**:

1. **Check theme configuration**:
   ```bash
   scriptorium edit config.txt
   # Verify theme: theme-name is set correctly
   ```

2. **Verify theme exists**:
   ```bash
   ls -la themes/
   # Ensure the theme directory exists
   ```

3. **Apply theme explicitly**:
   ```bash
   scriptorium theme theme-name
   ```

#### CSS not loading

**Symptoms**: Site appears unstyled or with broken styling.

**Solutions**:

1. **Check CSS file paths**:
   ```bash
   ls -la themes/standard/layout/gen/
   # Verify CSS files exist
   ```

2. **Regenerate theme**:
   ```bash
   scriptorium generate
   # This should regenerate CSS files
   ```

3. **Check browser cache**:
   - Hard refresh (Ctrl+F5 or Cmd+Shift+R)
   - Clear browser cache
   - Try incognito/private browsing mode

## Dependency Management

### Ruby version issues

**Symptoms**: Scriptorium fails to run or has compatibility issues.

**Solutions**:

1. **Check Ruby version**:
   ```bash
   ruby --version
   # Scriptorium requires Ruby 2.7 or higher
   ```

2. **Update Ruby if needed**:
   ```bash
   # Using rbenv
   rbenv install 3.2.0
   rbenv global 3.2.0
   
   # Using rvm
   rvm install 3.2.0
   rvm use 3.2.0 --default
   ```

3. **Reinstall gems**:
   ```bash
   gem update
   gem install scriptorium
   ```

### Gem conflicts

**Symptoms**: Scriptorium conflicts with other Ruby gems.

**Solutions**:

1. **Use bundler**:
   ```bash
   # Create Gemfile
   echo 'gem "scriptorium"' > Gemfile
   
   # Install with bundler
   bundle install
   bundle exec scriptorium
   ```

2. **Use gem isolation**:
   ```bash
   # Install in user directory
   gem install --user-install scriptorium
   ```

3. **Check gem environment**:
   ```bash
   gem env
   # Verify gem paths and versions
   ```

### System dependencies

**Symptoms**: Scriptorium fails due to missing system libraries.

**Solutions**:

1. **Install development tools**:
   ```bash
   # Ubuntu/Debian
   sudo apt install build-essential
   
   # macOS
   xcode-select --install
   
   # CentOS/RHEL
   sudo yum groupinstall "Development Tools"
   ```

2. **Install specific libraries**:
   ```bash
   # Ubuntu/Debian
   sudo apt install libssl-dev libreadline-dev zlib1g-dev
   
   # CentOS/RHEL
   sudo yum install openssl-devel readline-devel zlib-devel
   ```

## Error Messages

### Common error messages and solutions

#### "Cannot read file: file not found"

**Cause**: Scriptorium can't find a required file.

**Solution**:
```bash
# Check if file exists
ls -la path/to/file

# Create missing file if needed
touch path/to/file

# Check file permissions
chmod 644 path/to/file
```

#### "Cannot build widget: name invalid"

**Cause**: Widget name contains invalid characters.

**Solution**:
```bash
# Use only lowercase letters, numbers, and hyphens
# Good: my-widget, links, pages
# Bad: My_Widget, links!, pages@
```

#### "Layout has unknown tag"

**Cause**: Layout file contains unrecognized container names.

**Solution**:
```bash
# Check layout file
scriptorium edit config/layout.txt

# Valid containers: header, main, left, right, footer
# Remove or correct invalid container names
```

#### "Theme doesn't exist"

**Cause**: Referenced theme is not found.

**Solution**:
```bash
# List available themes
ls -la themes/

# Check theme configuration
scriptorium edit config.txt

# Use existing theme or create new one
scriptorium theme standard
```

#### "Post not found"

**Cause**: Referenced post ID doesn't exist.

**Solution**:
```bash
# List all posts
scriptorium list posts

# Check post ID format
# Posts should be numbered: 001, 002, etc.

# Create post if needed
scriptorium new post "Post Title"
```

### Debugging techniques

#### Enable verbose output

```bash
# Run commands with verbose output
scriptorium generate --verbose

# Check for detailed error messages
scriptorium status --verbose
```

#### Check log files

```bash
# Look for error logs
find . -name "*.log" -exec cat {} \;

# Check system logs
tail -f /var/log/syslog  # Linux
tail -f /var/log/system.log  # macOS
```

#### Test individual components

```bash
# Test post generation
scriptorium generate post 001

# Test widget generation
scriptorium generate widget links

# Test theme application
scriptorium theme standard
```

## Getting Help

### Self-help resources

1. **Check the documentation**:
   - Review relevant sections of this user guide
   - Check the README file in your Scriptorium installation
   - Look for examples in the test directory

2. **Use built-in help**:
   ```bash
   scriptorium --help
   scriptorium help command-name
   ```

3. **Check the source code**:
   ```bash
   # Find Scriptorium installation
   gem which scriptorium
   
   # Explore the source
   ls -la $(gem which scriptorium | sed 's/lib\/scriptorium.rb//')
   ```

### Community resources

1. **GitHub repository**:
   - Check issues for similar problems
   - Review recent commits for fixes
   - Submit new issues for bugs

2. **Documentation**:
   - Check the project wiki
   - Review example configurations
   - Look for community-contributed guides

3. **Forums and discussions**:
   - Search for Scriptorium discussions
   - Ask questions in relevant communities
   - Share solutions with others

### Reporting bugs

When reporting bugs, include:

1. **System information**:
   ```bash
   ruby --version
   gem list scriptorium
   uname -a
   ```

2. **Steps to reproduce**:
   - Exact commands run
   - Expected vs. actual behavior
   - Any error messages

3. **Configuration details**:
   - Relevant configuration files
   - Post content (if relevant)
   - Theme and widget setup

4. **Error logs**:
   - Full error messages
   - Stack traces
   - Debug output

### Getting support

1. **Before asking for help**:
   - Try the solutions in this section
   - Search for similar issues
   - Check if the problem is user error

2. **When asking for help**:
   - Be specific about the problem
   - Include relevant error messages
   - Provide system and configuration details
   - Explain what you've already tried

3. **Follow up**:
   - Let people know if their suggestions worked
   - Share solutions that worked for you
   - Help others with similar problems

### Prevention tips

1. **Regular backups**:
   ```bash
   # Backup your Scriptorium repository
   tar -czf scriptorium-backup-$(date +%Y%m%d).tar.gz .
   ```

2. **Version control**:
   ```bash
   # Use git for version control
   git init
   git add .
   git commit -m "Initial commit"
   ```

3. **Test changes**:
   ```bash
   # Test changes before applying
   scriptorium generate --dry-run
   
   # Keep a test environment
   cp -r . test-environment
   ```

4. **Document your setup**:
   - Keep notes on your configuration
   - Document customizations
   - Record solutions to problems

By following these troubleshooting steps and best practices, you can quickly resolve most issues and maintain a stable Scriptorium installation. 

---

# 11. Reference

This section provides comprehensive reference information for Scriptorium, including command syntax, configuration options, and technical details.

## Command Reference

### Core commands

#### `scriptorium init [path]`
Initialize a new Scriptorium repository.

**Options:**
- `path`: Directory to initialize (default: current directory)

**Examples:**
```bash
scriptorium init                    # Initialize in current directory
scriptorium init my-blog           # Initialize in my-blog directory
```

#### `scriptorium new post "title"`
Create a new blog post.

**Options:**
- `title`: Post title (required)

**Examples:**
```bash
scriptorium new post "My First Post"
scriptorium new post "Getting Started with Scriptorium"
```

#### `scriptorium edit [file]`
Edit a file using the configured editor.

**Options:**
- `file`: File path to edit

**Examples:**
```bash
scriptorium edit posts/001.lt3
scriptorium edit config.txt
scriptorium edit widgets/links/list.txt
```

#### `scriptorium generate [target]`
Generate the site or specific components.

**Options:**
- `target`: Specific component to generate (optional)
  - `post <id>`: Generate specific post
  - `widget <name>`: Generate specific widget
  - `view <name>`: Generate specific view

**Examples:**
```bash
scriptorium generate                # Generate entire site
scriptorium generate post 001      # Generate specific post
scriptorium generate widget links  # Generate links widget
```

#### `scriptorium publish <id>`
Publish a draft post.

**Options:**
- `id`: Post ID to publish

**Examples:**
```bash
scriptorium publish 001
scriptorium publish 002
```

#### `scriptorium list [type]`
List posts, views, or other content.

**Options:**
- `type`: Type of content to list
  - `posts`: List all posts
  - `views`: List all views
  - `drafts`: List draft posts

**Examples:**
```bash
scriptorium list posts
scriptorium list views
scriptorium list drafts
```

### View management commands

#### `scriptorium view <name>`
Switch to a different view.

**Options:**
- `name`: View name to switch to

**Examples:**
```bash
scriptorium view sample
scriptorium view blog
```

#### `scriptorium create view <name> <title> [subtitle]`
Create a new view.

**Options:**
- `name`: View name
- `title`: View title
- `subtitle`: View subtitle (optional)

**Examples:**
```bash
scriptorium create view blog "My Blog" "Personal thoughts and ideas"
scriptorium create view docs "Documentation"
```

### Post management commands

#### `scriptorium link <id> [view]`
Link a post to a view.

**Options:**
- `id`: Post ID
- `view`: View name (default: current view)

**Examples:**
```bash
scriptorium link 001
scriptorium link 002 blog
```

#### `scriptorium unlink <id> [view]`
Unlink a post from a view.

**Options:**
- `id`: Post ID
- `view`: View name (default: current view)

**Examples:**
```bash
scriptorium unlink 001
scriptorium unlink 002 blog
```

#### `scriptorium delete <id>`
Delete a post.

**Options:**
- `id`: Post ID to delete

**Examples:**
```bash
scriptorium delete 001
```

### Widget commands

#### `scriptorium generate widget <name>`
Generate a specific widget.

**Options:**
- `name`: Widget name (links, pages, featuredposts)

**Examples:**
```bash
scriptorium generate widget links
scriptorium generate widget pages
```

### Theme commands

#### `scriptorium theme <name>`
Apply a theme to the current view.

**Options:**
- `name`: Theme name

**Examples:**
```bash
scriptorium theme standard
scriptorium theme custom
```

### Utility commands

#### `scriptorium status`
Show repository status.

**Examples:**
```bash
scriptorium status
```

#### `scriptorium help [command]`
Show help information.

**Options:**
- `command`: Specific command to get help for

**Examples:**
```bash
scriptorium help
scriptorium help generate
```

## Configuration Files

### Repository configuration

#### `config/repo.txt`
Main repository configuration file.

**Example:**
```
title: My Scriptorium Site
description: A personal blog and website
author: Your Name
email: your.email@example.com
url: https://example.com
```

### View configuration

#### `config.txt`
View-specific configuration.

**Example:**
```
title: My Blog
subtitle: Personal thoughts and ideas
theme: standard
layout: default
```

#### `config/layout.txt`
Layout configuration defining page structure.

**Example:**
```
header
left   20%
main
right  20%
footer
```

#### `config/header.txt`
Header configuration including navigation.

**Example:**
```
# Site title
.title My Blog

# Navigation links
.nav-link "Home" "/"
.nav-link "About" "pages/about.html"
.nav-link "Contact" "pages/contact.html"
```

### Widget configuration

#### `widgets/links/list.txt`
Links widget configuration.

**Format:**
```
url, title
url, title
```

**Example:**
```
https://example.com, Example Site
https://github.com, GitHub Profile
```

#### `widgets/pages/list.txt`
Pages widget configuration.

**Format:**
```
page-name
page-name
```

**Example:**
```
about
contact
documentation
```

#### `widgets/featuredposts/list.txt`
Featured posts widget configuration.

**Format:**
```
id title
id
```

**Example:**
```
001 My Important Post
002 Another Featured Post
003
```

### Theme configuration

#### `themes/standard/config.txt`
Theme configuration file.

**Example:**
```
name: Standard Theme
version: 1.0
description: Default Scriptorium theme
author: Scriptorium Team
```

## LiveText Reference

### Basic syntax

#### Inline formatting
```
**bold text**
*italic text*
`code text`
[link text](url)
![alt text](image.jpg)
```

#### Dot commands
```
.command
.command parameter
.command "parameter with spaces"
```

#### Dot commands with body
```
.command
content here
.end
```

### Post metadata

#### Required metadata
```
.title Post Title
```

#### Optional metadata
```
.subtitle Post Subtitle
.tags tag1, tag2, tag3
.blurb Post excerpt for summaries
.views view1, view2
.pubdate 2024-01-15
```

#### Social media metadata
```
.og_title Title for social media
.og_description Description for social media
.og_image /path/to/image.jpg
.twitter_card summary_large_image
.twitter_title Twitter title
.twitter_description Twitter description
```

#### Reddit integration metadata
```
.reddit_subreddit programming
.reddit_title Custom Reddit title
.reddit_flair "Discussion"
.reddit_nsfw false
.reddit_spoiler false
```

### Template variables

#### Post variables
```
%{post.title}        # Post title
%{post.body}         # Post content
%{post.pubdate}      # Publication date
%{post.tags}         # Post tags
%{post.blurb}        # Post excerpt
%{post.url}          # Post URL
%{post.slug}         # Post slug
```

#### Site variables
```
%{site.title}        # Site title
%{site.description}  # Site description
%{site.url}          # Site URL
%{site.author}       # Site author
```

#### View variables
```
%{view.name}         # View name
%{view.title}        # View title
%{view.subtitle}     # View subtitle
```

### Control structures

#### Conditionals
```
.if condition
content
.end

.if post.tags.include?("featured")
This is a featured post!
.end
```

#### Loops
```
.each item in collection
content
.end

.each post in posts
%{post.title}
.end
```

#### Includes
```
.include "file.lt3"
.include "templates/header.lt3"
```

## API Reference

### Core classes

#### Scriptorium::Repo
Main repository class for managing Scriptorium sites.

**Methods:**
```ruby
# Initialize repository
repo = Scriptorium::Repo.open(path)

# Create new repository
repo = Scriptorium::Repo.create(path, title, description)

# Get current view
view = repo.current_view

# List all views
views = repo.views

# Create post
post = repo.create_post(title: "Title", body: "Content")

# Get post by ID
post = repo.post(id)

# List all posts
posts = repo.all_posts
```

#### Scriptorium::View
Represents a view within a repository.

**Methods:**
```ruby
# Get view name
name = view.name

# Get view title
title = view.title

# Get view directory
dir = view.dir

# Generate view
view.generate

# Apply theme
view.apply_theme(theme_name)
```

#### Scriptorium::Post
Represents a blog post.

**Methods:**
```ruby
# Get post title
title = post.title

# Get post body
body = post.body

# Get post tags
tags = post.tags

# Get post views
views = post.views

# Update post
post.update(fields)

# Delete post
post.delete
```

### Widget classes

#### Scriptorium::Widget::Links
Links widget for displaying external links.

**Methods:**
```ruby
# Get list of links
links = widget.get_list

# Generate widget
widget.generate

# Get widget card content
card = widget.card
```

#### Scriptorium::Widget::Pages
Pages widget for displaying internal pages.

**Methods:**
```ruby
# Generate widget
widget.generate

# Get widget card content
card = widget.card
```

#### Scriptorium::Widget::FeaturedPosts
Featured posts widget for highlighting specific posts.

**Methods:**
```ruby
# Parse featured line
post_id, title = widget.parse_featured_line(line)

# Get post title
title = widget.get_post_title(post_id)

# Generate widget
widget.generate
```

### Helper methods

#### File operations
```ruby
# Read file
content = read_file(path)

# Write file
write_file(path, content)

# Check if file exists
exists = file_exist?(path)

# Make directory
make_dir(path)
```

#### HTML generation
```ruby
# Generate HTML card
html = html_card(title, tag, content)

# Generate HTML container
html = html_container(content)

# Generate HTML body
html = html_body(css) { content }
```

## View Tree Structure

### Repository structure
```
repository/
├── config/
│   ├── repo.txt              # Repository configuration
│   ├── deploy.txt            # Deployment configuration
│   └── widgets.txt           # Available widgets
├── views/
│   ├── sample/               # Sample view
│   │   ├── config.txt        # View configuration
│   │   ├── config/           # View-specific config
│   │   ├── posts/            # Post files
│   │   ├── pages/            # Page files
│   │   ├── widgets/          # Widget configurations
│   │   ├── themes/           # View-specific themes
│   │   ├── layout/           # Layout files
│   │   ├── output/           # Generated output
│   │   └── staging/          # Staging area
│   └── other-view/           # Additional views
├── themes/
│   └── standard/             # Standard theme
│       ├── config.txt        # Theme configuration
│       ├── assets/           # Theme assets
│       ├── templates/        # Theme templates
│       └── layout/           # Theme layout
├── posts/                    # Global posts
├── drafts/                   # Draft posts
└── .scriptorium             # Repository metadata
```

### View structure
```
view/
├── config.txt               # View configuration
├── config/                  # Configuration files
│   ├── layout.txt           # Layout configuration
│   ├── header.txt           # Header configuration
│   ├── left.txt             # Left sidebar configuration
│   ├── right.txt            # Right sidebar configuration
│   ├── main.txt             # Main content configuration
│   └── footer.txt           # Footer configuration
├── posts/                   # Post files
│   ├── 001.lt3             # Post 001
│   ├── 002.lt3             # Post 002
│   └── ...                 # Additional posts
├── pages/                   # Page files
│   ├── about.html           # About page
│   ├── contact.html         # Contact page
│   └── ...                 # Additional pages
├── widgets/                 # Widget configurations
│   ├── links/               # Links widget
│   │   └── list.txt         # Links list
│   ├── pages/               # Pages widget
│   │   └── list.txt         # Pages list
│   └── featuredposts/       # Featured posts widget
│       └── list.txt         # Featured posts list
├── themes/                  # View-specific themes
├── layout/                  # Layout files
│   ├── header.html          # Header template
│   ├── footer.html          # Footer template
│   └── ...                 # Additional layout files
├── output/                  # Generated output
│   ├── index.html           # Front page
│   ├── posts/               # Generated post pages
│   ├── pages/               # Generated page files
│   ├── assets/              # Assets (CSS, JS, images)
│   └── widgets/             # Generated widget files
└── staging/                 # Staging area
```

### Theme structure
```
theme/
├── config.txt               # Theme configuration
├── assets/                  # Theme assets
│   ├── images/              # Theme images
│   ├── fonts/               # Theme fonts
│   └── ...                 # Additional assets
├── templates/               # Theme templates
│   ├── index.lt3            # Front page template
│   ├── post.lt3             # Post template
│   └── widget.lt3           # Widget template
├── layout/                  # Theme layout
│   ├── config/              # Layout configuration
│   ├── gen/                 # Generated files
│   └── layout.txt           # Layout structure
├── header/                  # Header templates
├── initial/                 # Initial content
└── ...                     # Additional theme files
```

### File naming conventions

#### Posts
- Format: `NNN-title.lt3` (e.g., `001-my-first-post.lt3`)
- ID must be three-digit number
- Title should be lowercase with hyphens

#### Pages
- Format: `name.html` (e.g., `about.html`, `contact.html`)
- Use descriptive, lowercase names
- Avoid spaces and special characters

#### Widgets
- Directory names: lowercase with hyphens
- Configuration files: `list.txt` or `config.txt`
- Generated files: `widget-name-card.html`

#### Themes
- Directory names: lowercase with hyphens
- Configuration: `config.txt`
- Templates: `.lt3` extension

This reference section provides the technical details needed for advanced Scriptorium usage and development. For more specific information about certain areas, consult the relevant sections of this user guide or the Scriptorium source code. 

