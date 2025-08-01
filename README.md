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
  - Python 3 (for Reddit integration and syntax highlighting)
  - PRAW (Python Reddit API wrapper for autoposting)
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
PRAW (Reddit API)         ❌ Missing
LiveText                  ✅ Available
ImageMagick               ✅ Available

Feature Availability:
------------------------------
Core Blogging        ✅ Ready
Reddit Button        ✅ Ready
Reddit Autopost      ❌ Missing Dependencies
   Missing: praw
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


# Section 6: Managing Pages [TBD]
## Used in navbar
## Used in Pages widget
## Internal links
## Subdirectories under pages/

# Section 7: Customization
## Themes and Styling (cloning)
## Templates
## Widgets and Features

# Section 8: Advanced Features
## Reddit Integration
## Social Media Features

# Section 9: Deployment & Hosting
## Local Development
## Server Deployment
## Domain Configuration
## SSL Setup

# Section 10: Troubleshooting
## Common Issues
## Dependency Management
## Error Messages
## Getting Help

# Section 11: Reference
## Command Reference
## Configuration Files
## LiveText Reference
## API Reference
## View Tree Structure
