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