# Syntax Highlighting and Navigation Improvements

**Date**: 2025-08-13 08:24:28  
**Topic**: Comprehensive improvements to syntax highlighting, navigation, widgets, and user experience  
**Status**: Implemented and tested

## 🎨 **Syntax Highlighting Implementation**

### **Core Changes**
- **Replaced Prism.js** with **Rouge** (Ruby-based server-side syntax highlighter)
- **Added `rouge` gem** dependency for syntax highlighting
- **Added `htmlbeautifier` gem** for HTML formatting (later removed due to corruption issues)

### **SyntaxHighlighter Class** (`lib/scriptorium/syntax_highlighter.rb`)
- **Rouge integration**: Uses Rouge lexers for multiple languages (Ruby, Elixir, JavaScript, etc.)
- **CSS generation**: Creates syntax highlighting styles that override Bootstrap constraints
- **Class mapping**: Maps Rouge output classes to Scriptorium's semantic CSS classes
- **Height constraints fix**: Added specific CSS rules to prevent vertical scrolling in code blocks

### **CSS Overrides for Bootstrap**
```css
/* Override Bootstrap height constraints for syntax highlighting */
pre code[class*="language-"] {
  height: auto !important;
  max-height: none !important;
  min-height: auto !important;
  overflow: visible !important;
}

pre:has(code[class*="language-"]) {
  height: auto !important;
  max-height: none !important;
  min-height: auto !important;
  overflow: visible !important;
}
```

## 🔄 **Dynamic Navigation System**

### **load_main Function Improvements** (`lib/scriptorium/standard_files.rb`)
- **Post handling**: Enhanced to handle `?post=` parameters correctly
- **Static page support**: Added support for `pages/`, `assets/`, and other static content
- **Path resolution**: Fixed relative path issues for static pages
- **Error handling**: Graceful fallbacks for missing content

### **URL and History Management**
- **Auto-loading**: `window.onload` automatically loads posts from URL parameters
- **History sync**: Browser history stays synchronized with content
- **Refresh support**: Page refreshes maintain the correct content state
- **Navigation buttons**: "Go back" button simplified to direct link to index

### **JavaScript Enhancements**
```javascript
// Check if this is a static page request (pages/, assets/, etc.)
if (slug.startsWith('pages/') || slug.startsWith('assets/') || slug.includes('/')) {
  console.log('Loading static page:', slug);
  fetch('./' + slug)
    .then(response => {
      if (response.ok) {
        return response.text();
      } else {
        return 'Page not found';
      }
    })
    .then(content => {
      contentDiv.innerHTML = content;
      // Don't change URL for static pages to avoid path resolution issues
      history.pushState({slug: slug}, "", window.location.pathname);
    });
  return;
}
```

## 📁 **Pages Directory Support**

### **generate_front_page Enhancement** (`lib/scriptorium/view.rb`)
- **Pages copying**: Automatically copies `pages/` directory to output during generation
- **Asset preservation**: Maintains file permissions and content integrity
- **Graceful handling**: Works with or without pages directory present

### **Implementation Details**
```ruby
# Copy pages directory to output if it exists
pages_source = @dir/:pages
pages_output = @dir/:output/:pages
if Dir.exist?(pages_source)
  FileUtils.mkdir_p(pages_output)
  Dir.glob(pages_source/"*").each do |file|
    next unless File.file?(file)
    FileUtils.cp(file, pages_output/File.basename(file))
  end
end
```

## 🧩 **Widget System Enhancements**

### **Pages Widget** (`lib/scriptorium/widgets.rb`)
- **List-based**: Reads `list.txt` file containing page filenames
- **Content separation**: Page content stored in `pages/` directory, not widget directory
- **Navigation**: Generates proper links to static pages
- **Back links**: Each page includes "← Back to Home" link

### **Widget Structure**
```
view.dir/:widgets/"pages/list.txt"     # List of page filenames
view.dir/:pages/"about.html"           # Actual page content
view.dir/:pages/"contact.html"         # Actual page content
```

### **Generated HTML**
```html
<div class="card mb-3">
  <div class="card-body">
    <h5 class="card-title">
      <button type="button" class="btn btn-primary" data-bs-toggle="collapse" data-bs-target="#pages">+</button>
      <a href="javascript:void(0)" onclick="javascript:load_main('pages-main.html')">Pages</a>
    </h5>
    <div class="collapse" id="pages">
      <li class="list-group-item"><a href="javascript:void(0)" onclick="load_main('pages/about.html')">About Us</a></li>
      <li class="list-group-item"><a href="javascript:void(0)" onclick="load_main('pages/contact.html')">Contact</a></li>
    </div>
  </div>
</div>
```

## 📋 **Clipboard Functionality**

### **Clipboard Gem Integration**
- **Added `clipboard` gem** dependency for cross-platform clipboard access
- **Fallback support**: OS-specific commands if gem unavailable
- **Helper methods**: `copy_to_clipboard()` and `get_from_clipboard()`

### **Copy Link Button**
- **Button text**: "Copy link" (cleaner than "Copy Permalink")
- **Dual placement**: Added to both normal posts and permalink pages
- **Smart URL logic**: Always copies the clean permalink URL regardless of current view
- **Visual feedback**: Button changes to green "Copied!" for 2 seconds

### **Implementation**
```javascript
function copyPermalinkToClipboard() {
  // Get the current post slug from the URL or construct it
  const currentUrl = window.location.href;
  let permalinkUrl;
  
  if (currentUrl.includes('?post=')) {
    // We're on the main blog page, construct the permalink URL
    const postSlug = currentUrl.split('?post=')[1];
    const baseUrl = window.location.origin + window.location.pathname.replace(/\/[^\/]*$/, '');
    permalinkUrl = baseUrl + '/permalink/' + postSlug;
  } else {
    // We're already on a permalink page, use current URL
    permalinkUrl = currentUrl;
  }
  
  navigator.clipboard.writeText(permalinkUrl).then(function() {
    // Visual feedback
    const button = event.target;
    button.textContent = 'Copied!';
    button.style.background = '#28a745';
    setTimeout(function() {
      button.textContent = 'Copy link';
      button.style.background = '#007bff';
    }, 2000);
  });
}
```

## 🧪 **Testing Coverage**

### **Unit Tests Added**
- **View tests**: Pages directory copying functionality
- **Widget tests**: Pages widget with back links
- **Clipboard tests**: Clipboard helper methods
- **Integration tests**: Full workflow verification

### **Test Files Modified**
- `test/unit/view.rb`: Added 4 new tests for pages directory handling
- `test/unit/widgets.rb`: Added 3 new tests for Pages widget functionality
- `test/unit/clipboard_test.rb`: New test file for clipboard functionality
- `test/unit/repo.rb`: Enhanced permalink test to verify copy link button

### **Test Patterns**
- **Three-digit prefixes**: Following project convention (test_032, test_033, etc.)
- **Comprehensive coverage**: Edge cases, error conditions, success scenarios
- **Integration testing**: Full workflow from source to output

## 🎯 **User Experience Improvements**

### **Navigation Flow**
1. **Main blog**: View posts with "Copy link" button
2. **Widget expansion**: Click "+" to expand Pages widget
3. **Page navigation**: Click page links to load static content
4. **Back navigation**: Use "← Back to Home" links
5. **Link sharing**: Copy clean permalink URLs from any view

### **Visual Enhancements**
- **Syntax highlighting**: Colored code blocks with proper spacing
- **Responsive design**: Code blocks adapt to content height
- **Interactive elements**: Collapsible widgets, copy buttons with feedback
- **Consistent styling**: Bootstrap integration with custom overrides

### **Performance Benefits**
- **Server-side highlighting**: No client-side JavaScript processing
- **Eliminated scrolling**: Code blocks display at full height
- **Reduced layout shifts**: Proper height calculations prevent reflows
- **Efficient asset handling**: Pages copied once during generation

## 🔧 **Technical Architecture**

### **File Organization**
```
lib/scriptorium/
├── syntax_highlighter.rb    # Rouge integration and CSS generation
├── helpers.rb               # Clipboard helper methods
├── view.rb                  # Pages directory copying
├── repo.rb                  # Enhanced permalink generation
└── standard_files.rb        # Updated post templates and JavaScript
```

### **Dependencies Added**
- `rouge` gem: Syntax highlighting
- `clipboard` gem: Cross-platform clipboard access

### **Backward Compatibility**
- **Existing functionality**: All previous features continue to work
- **Enhanced features**: New capabilities added without breaking changes
- **Fallback support**: Graceful degradation when optional features unavailable

## 📚 **Documentation and Examples**

### **Manual Tests**
- **`test6.rb`**: Demonstrates Pages widget with Links widget
- **Syntax highlighting**: Shows Rouge output with proper CSS
- **Navigation flow**: Complete user journey from index to pages

### **Code Examples**
- **Widget setup**: How to create and configure Pages widget
- **Page creation**: HTML structure for static pages
- **Navigation patterns**: JavaScript for dynamic content loading

## 🚀 **Future Considerations**

### **Potential Enhancements**
- **Additional widgets**: More widget types following established patterns
- **Enhanced navigation**: Breadcrumbs, sitemap generation
- **Performance optimization**: Lazy loading, caching strategies
- **Accessibility**: ARIA labels, keyboard navigation

### **Maintenance Notes**
- **CSS overrides**: Monitor Bootstrap compatibility on updates
- **Clipboard API**: Consider fallback strategies for older browsers
- **Widget system**: Extend patterns for new content types
- **Testing**: Maintain comprehensive test coverage for new features

This implementation provides a robust, user-friendly blogging system with modern syntax highlighting, intuitive navigation, and professional sharing capabilities.
