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