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

**Questions for refinement:**

1. **Multi-view examples**: Should I provide more specific examples of how views might be used in practice? (e.g., different audiences, different content types)

**REPLY:** One essential point is that views may overlap in content. If there is a music-related view and a hometown-related view, then a large concert in my hometown might go in both. A large part of the reason for views is so that blogs can share posts, assets, and a common backend.

2. **Repository structure**: Is the directory structure I've shown accurate to the current implementation? Should I include more detail about specific files and their purposes?

**REPLY:** Fine for now. More detail when we dig into views.

3. **Deployment options**: Are there specific deployment methods or services that should be highlighted or avoided?

**REPLY:** Currently I only have deployment to any host where you have ssh access and keys set up.

4. **LiveText integration**: Should I mention how LiveText specifically integrates with Scriptorium's view system and content management?

**REPLY:** No deep details for now, I guess.

5. **Technical depth**: Is this level of technical detail appropriate for the user guide, or should I adjust the depth for the target audience? 

**REPLY:** I think this is fine for now.