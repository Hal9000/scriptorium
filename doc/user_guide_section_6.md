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