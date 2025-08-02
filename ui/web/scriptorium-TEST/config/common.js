  // Handle the back button (or JavaScript history.go(-1))
  window.onpopstate = function(event) {
    console.log('onpopstate event:', event); // Log the event object
    if (event.state && event.state.slug) {
      console.log('Navigating to slug:', event.state.slug); // Log the slug
      load_main(event.state.slug);  // Load the post for the previous history state
    }
  };

  // Initialize with the front page when navigating via the back button or similar
  window.onload = function() {
    // Check if the initial state exists, if not, set it
    if (!history.state) {
       // Don't try to load post_index.html if there are no posts
       // The "No posts yet!" message is already in the main container
       history.replaceState({ slug: "index.html" }, "", "index.html");
    }
};

// Load the main content and other page containers (header, footer, left, right)
function load_main(slug) {
    // Get all container elements (header, footer, left, right, and main)
    const contentDiv = document.getElementById("main");
    const headerDiv = document.querySelector("header");
    const footerDiv = document.querySelector("footer");
    const leftDiv = document.querySelector(".left");
    const rightDiv = document.querySelector(".right");
    console.log('Loading main with slug:', slug); // Log the slug

    // Check if we're in preview mode (served from Sinatra)
    // If the URL contains '/preview_view', we need to use the Sinatra route
    let fetchUrl = slug;
    console.log('Current location:', window.location.href);
    console.log('Checking for preview mode...');
    
    if (window.location.href.includes('localhost:4567') || window.location.href.includes('127.0.0.1:4567')) {
        // Extract view name from the current URL or use a default
        const viewName = 'mystuff'; // This should be dynamic based on the current view
        fetchUrl = `/preview/${viewName}/posts/${slug.split('/').pop()}`;
        console.log('Using preview URL:', fetchUrl);
    } else {
        console.log('Using original URL:', fetchUrl);
    }

  fetch(fetchUrl)
    .then(response => {
        if (response.ok) {
            console.log('Response is ok');
            return response.text();
        } else {
            console.error('Failed to load:', response.status); // Log the failed response
            contentDiv.innerHTML = `<p>Error loading content: ${response.status}</p>`;
        }
    })
    .then(content => {
        if (content) {
            console.log('Loaded content into div'); // Log successful content insertion

            // Clean up the content - remove any HTML/head/body tags if present
            // since we're inserting into an existing HTML document
            let cleanContent = content;
            
            // Remove DOCTYPE if present
            cleanContent = cleanContent.replace(/<!DOCTYPE[^>]*>/i, '');
            
            // Remove <html> tags and their content
            cleanContent = cleanContent.replace(/<html[^>]*>[\s\S]*?<\/html>/i, function(match) {
                // Extract content between <html> tags, excluding <head> and <body> tags
                return match.replace(/<head[^>]*>[\s\S]*?<\/head>/i, '')
                           .replace(/<body[^>]*>|<\/body>/gi, '');
            });
            
            // Remove any remaining <head> or <body> tags
            cleanContent = cleanContent.replace(/<head[^>]*>[\s\S]*?<\/head>/i, '')
                                     .replace(/<body[^>]*>|<\/body>/gi, '');
            
            console.log('Cleaned content length:', cleanContent.length);

            // Now, reload the content into the respective containers:
            // Main section
            contentDiv.innerHTML = cleanContent;

            // Re-insert header, footer, left, and right (if necessary)
            // If you want the static layout to be kept, you can preserve these parts
            // with additional logic or predefined structure (here it's assumed 
            // that header/footer/left/right are already statically included).
            
            // You can also replace the other parts (left, right, header, footer) if needed.
            history.pushState({slug: slug}, "", slug);  // Update browser history
        }
    })
    .catch(error => {
        console.log("Error loading content:", error); // Log any errors during fetch
        contentDiv.innerHTML = `<p>Error loading content: ${error.message}</p>`;
    });
  }
