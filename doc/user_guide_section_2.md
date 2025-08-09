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