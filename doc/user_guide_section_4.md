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