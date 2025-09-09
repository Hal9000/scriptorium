// Load the main content and other page containers (header, footer, left, right)
function load_main(slug) {
    // Get all container elements (header, footer, left, right, and main)
    const contentDiv = document.getElementById("main");
    const headerDiv = document.querySelector("header");
    const footerDiv = document.querySelector("footer");
    const leftDiv = document.querySelector(".left");
    const rightDiv = document.querySelector(".right");
    console.log('Loading main with slug:', slug); // Log the slug
    
    // Clear any existing content to prevent nesting
    contentDiv.innerHTML = '';
    contentDiv.dataset.currentSlug = slug;

    // Check if this is a post parameter request
    if (slug.includes('?post=')) {
        const postSlug = slug.split('?post=')[1];
        console.log('Loading post:', postSlug);
        
        // Load the post content - add .html extension if it's missing
        const postFile = postSlug.endsWith('.html') ? postSlug : postSlug + '.html';
        console.log('Fetching post file:', 'posts/' + postFile);
        fetch('posts/' + postFile)
            .then(response => {
                console.log('Response status:', response.status);
                if (response.ok) {
                    return response.text();
                } else {
                    console.error('Failed to load post:', response.status);
                    return 'Post not found';
                }
            })
            .then(content => {
                console.log('Loaded content length:', content.length);
                console.log('Content preview:', content.substring(0, 200));
                contentDiv.innerHTML = content;
                
                // Debug: Check what pre elements exist
                const allPreElements = contentDiv.querySelectorAll('pre');
                console.log('All pre elements found:', allPreElements.length);
                allPreElements.forEach((pre, index) => {
                    console.log(`Pre element ${index}:`, pre.outerHTML.substring(0, 100));
                });

                // Highlight the newly loaded content
                highlightNewContent(contentDiv);
                
                history.pushState({slug: 'index.html?post=' + postSlug}, "", 'index.html?post=' + postSlug);
            })
            .catch(error => {
                console.log("Error loading post:", error);
                contentDiv.innerHTML = 'Error loading post';
            });
        return;
    }

    // Check if this is a static page request (pages/, assets/, etc.)
    if (slug.startsWith('pages/') || slug.startsWith('assets/') || slug.includes('/')) {
        console.log('Loading static page:', slug);
        // Simple approach: always go back to index.html directory and fetch from there
        fetch(slug)
            .then(response => {
                if (response.ok) {
                    return response.text();
                } else {
                    console.error('Failed to load static page:', response.status);
                    return 'Page not found';
                }
            })
            .then(content => {
                contentDiv.innerHTML = content;
                // Don't change the URL for static pages to avoid path resolution issues
                history.pushState({slug: slug}, "", window.location.pathname);
            })
            .catch(error => {
                console.log("Error loading static page:", error);
                contentDiv.innerHTML = 'Error loading page';
            });
        return;
    }

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
