// Handle the back/forward buttons with SPA-aware loading
window.onpopstate = function(event) {
  try {
    console.log('onpopstate event:', event);
    const state = event.state || {};
    const slug = state.slug || 'index.html';
    // Use SPA loader to restore prior view instead of reloading
    if (typeof load_main === 'function') {
      load_main(slug);
      return;
    }
  } catch (e) {
    console.warn('onpopstate handler failed, reloading:', e);
  }
  // Fallback
  window.location.reload();
};

// Initialize with the front page when navigating via the back button or similar
window.onload = function() {
  // If under preview, set a base href so relative assets in injected posts resolve correctly
  try {
    const parts = window.location.pathname.split('/');
    const idx = parts.indexOf('preview');
    if (idx >= 0 && parts.length > idx + 1) {
      const viewName = parts[idx + 1];
      const base = document.createElement('base');
      // Base at /preview/<view>/ so relative paths behave consistently with production
      base.setAttribute('href', `/preview/${viewName}/`);
      document.head.insertBefore(base, document.head.firstChild);
    }
  } catch (e) { console.warn('Base href insertion skipped:', e); }

  // Check if the URL has a post parameter and load it automatically
  const urlParams = new URLSearchParams(window.location.search);
  const postParam = urlParams.get('post');
  
  if (postParam) {
    // URL has a post parameter, load the post content
    console.log('Auto-loading post from URL parameter:', postParam);
    load_main('index.html?post=' + postParam);
    return;
  }
  
  // Check if the initial state exists, if not, set it
  if (!history.state) {
     // Don't try to load post_index.html if there are no posts
     // The "No posts yet!" message is already in the main container
     history.replaceState({ slug: "index.html" }, "", "index.html");
  }
  // (timing removed)
};
