# Scriptorium Overview

## What is Scriptorium?
- **Custom blogging system** - major rewrite of Runeblog
- **Static site generator** for personal use, designed as if others would adopt it
- **Multi-view architecture** - multiple separate blogs managed from single backend
- **Shared content model** - posts and metadata can be shared across views
- **Independent deployment** - each view can deploy to different servers/domains

## Core Architecture
- **API-first design** - Ruby methods (not web endpoints)
- **File-based storage** - no database, uses directory hierarchy
- **Library approach** - API defines all behavior, multiple UIs planned
- **Flat file data** - all data stored locally, deployed as needed

## Key Concepts
- **Repository (repo)** - the main container
- **View** - essentially a separate blog with its own look/feel
- **Post** - blog article with date, title, blurb, body, images
- **Theme** - immutable set of files copied to view for modification
- **BannerSVG** - flexible banner system (recent addition, not core)

## Development Philosophy
- **User-centric** - designed for your specific needs first
- **Convention over configuration** - sensible defaults
- **Complexity abstraction** - hide unnecessary details
- **Livetext integration** - custom tool for processing and generation
- **CSS preferences** - inline CSS, minimal JavaScript
- **Extensibility** - 90% common tasks should be trivial

## Current State
- **Core API complete** - repo/view/post creation, layout modification
- **Testing robust** - 770+ unit test assertions
- **No UI yet** - programmatic access only
- **Bootstrap integration** - for widgets and navbar (navbar pending)
- **Next priorities** - convenience module API, TUI, curses UI, new widgets

## Technical Stack
- **Ruby** - 25 years experience, favorite language
- **No Rails** - not a web developer, no dynamic components
- **Livetext** - custom processing tool with dot commands, includes, variables
- **Bootstrap** - limited use for widgets and navbar

---

**USER:** 
1. Scriptorium is a custom blogging system, a major rewrite of Runeblog. It is primarily for my own use, but I am creating it as if it would be adopted by others. It is a static site generator. Its primary distinguishing feature is that multiple "views" (actually separate blogs) can be managed from a single backend and repository. Each view may have its own look and feel and be deployed to different servers and different domains. Posts and possibly some global metadata can be shared among all of these as needed.

2. I am creating an API (Ruby methods, not web endpoints). At present, that is the only way to create content-- programmatically. When the API is mature, multiple user interfaces will be created: at least a TUI, then a curses-style, then a web app running on localhost. (All data is locally stored and manipulated; it is deployed to a remote server as needed.) There is no database; data are stored in flat files in a directory hierarchy. Some high-level API operations are: create a repository (a repo); create a view; create a post; configure a view; create a post; deploy; and so on. A view is in essence a blog, as I said. All views share a common set of posts to draw from, and a post may be in only one view or in many. A post is a simple blog post or article that may have all the usual decoration: date; title; blurb or teaser; text body; images; and more. A "theme" is a set of files (immutable) that are copied to a view for modification and configuration. The config of a view may include view-specific metadata, choices of look-and-feel, layout of the front page, etc.

3. I am expert in Ruby, having used it for nearly 25 years, and it is my favorite language. I do not know Rails, I am not a web developer, and this project has no real dynamic components. The API will define all possible behavior, so it could be considered a library; a user could in fact write his own UI. As I said, I have plans for at least three different UIs myself. BannerSVG was an interesting recent addition, but it is not as critical to the project as its line count might suggest. It is a flexible way of specifing a blog banner with a title and optional subtitle.

4. Some of my priorities are: - This must be useful, easy, flexible, and intuitive FOR ME. (It is possible no one else will ever use it.) - I believe in "convention over configuration" as DHH said. - Other mantras are: Abstract away complexity; hide unnecessary detail; take reasonable defaults; balance the tradeoff between ease of use and feature richness; wrap things as needed to simplify them; etc. - I am using a tool of my own called Livetext; more details on that later. It is a tool for processing its input format and generating arbitrary output (usually HTML in this case) as well as side effects. It has "dot" commands; includes; raw copy of files, variables and functions (both predefined and user-defined); user-defined dot commands; and a rudimentary plugin system. - I avoid Javascript when I can, and like to "hide" CSS mostly (at a high level). In output, I prefer CSS inline rather than in files (usually). - I believe that extensibilty is good in general. I believe that the 90% most common tasks should become trivial; hard things should be easy, but some very advanced things may be impossible; as in, if you want to do this sort of esoteric or arcane task, this probably isn't your tool."

5. Scriptorium is far less mature than Runeblog was, but is being rewritten to be FAR more sturdy and robust. The basics of the API are in place; we can create a repo, create a view, add posts to a view, modify a layout, add a "Links" widget, generate a front page. There is currently no UI, no deployment, etc. There are unit tests of about 770 assertions, as well as manual and semi-manual tests I am using Bootstrap a little (for widgets and the navbar); that is a fairly complex piece. I haven't added the navbar piece yet; that will come soon. Some next things I want to accomplish: a "convenience module" API; a TUI; a curses UI; at least two new widgets; better features in the Livetext "Scriptorium plugin"; etc. Probably will encapsulate the API soon so as to start UI development.

**ASST:** 
[See above content] 