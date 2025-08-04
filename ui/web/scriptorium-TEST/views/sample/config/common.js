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

  fetch(slug)
    .then(response => {
        if (response.ok) {
            console.log('Response is ok');
            return response.text();
        } else {
            console.error('Failed to load:', response.status); // Log the failed response
        }
    })
    .then(content => {
        console.log('Loaded content into div'); // Log successful content insertion

        // Now, reload the content into the respective containers:
        // Main section
        contentDiv.innerHTML = content;

        // Re-insert header, footer, left, and right (if necessary)
        // If you want the static layout to be kept, you can preserve these parts
        // with additional logic or predefined structure (here it's assumed 
        // that header/footer/left/right are already statically included).
        
        // You can also replace the other parts (left, right, header, footer) if needed.
        history.pushState({slug: slug}, "", slug);  // Update browser history
    })
    .catch(error => {
        console.log("Error loading content:", error); // Log any errors during fetch
    });
  }
