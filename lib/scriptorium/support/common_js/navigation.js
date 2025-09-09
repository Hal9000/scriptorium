// Handle the back button (or JavaScript history.go(-1))
window.onpopstate = function(event) {
  console.log('onpopstate event:', event); // Log the event object
  // Simply reload the page to avoid nesting issues
  window.location.reload();
};

// Initialize with the front page when navigating via the back button or similar
window.onload = function() {
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
};
