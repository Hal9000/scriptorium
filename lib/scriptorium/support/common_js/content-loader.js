// Load the main content and other page containers (header, footer, left, right)
function load_main(slug) {
    // Determine preview root (/preview/<view>/) for absolute fetches
    const pathParts = window.location.pathname.split('/');
    const previewIdx = pathParts.indexOf('preview');
    const viewName = (previewIdx >= 0 && pathParts.length > previewIdx + 1) ? pathParts[previewIdx + 1] : '';
    const previewRoot = `/preview/${viewName}/`;
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
        
        // Load the post content from preview root
        const postFile = postSlug.endsWith('.html') ? postSlug : postSlug + '.html';
        const postUrl = previewRoot + 'posts/' + postFile;
        console.log('Fetching post file:', postUrl);
        fetch(postUrl)
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
                // Intercept Back link to return to index within SPA
                try {
                    contentDiv.querySelectorAll('a[href]').forEach(a => {
                        const href = a.getAttribute('href') || '';
                        if (href === 'index.html' || href.endsWith('/index.html') || href === '../index.html') {
                            a.addEventListener('click', function(ev) {
                                ev.preventDefault();
                                load_main('index.html');
                            });
                        }
                    });
                } catch (e) { console.warn('Back link interception skipped:', e); }
                // Fix relative asset URLs (e.g., ../assets or ../../assets) to preview route
                try {
                    const parts = window.location.pathname.split('/');
                    const idx = parts.indexOf('preview');
                    const viewName = idx >= 0 && parts.length > idx + 1 ? parts[idx + 1] : '';
                    const baseAssets = `/preview/${viewName}/assets/`;
                    // Update img[src]
                    contentDiv.querySelectorAll('img[src]').forEach(img => {
                        const s = img.getAttribute('src');
                        const m = s && s.match(/^(?:\.\.\/)+assets\/(.*)$/);
                        if (m) { img.setAttribute('src', baseAssets + m[1]); }
                    });
                    // Update link[href] (e.g., styles or anchors that point into assets)
                    contentDiv.querySelectorAll('a[href], link[href]').forEach(a => {
                        const s = a.getAttribute('href');
                        const m = s && s.match(/^(?:\.\.\/)+assets\/(.*)$/);
                        if (m) { a.setAttribute('href', baseAssets + m[1]); }
                    });
                    // Update script[src]
                    contentDiv.querySelectorAll('script[src]').forEach(sc => {
                        const s = sc.getAttribute('src');
                        const m = s && s.match(/^(?:\.\.\/)+assets\/(.*)$/);
                        if (m) { sc.setAttribute('src', baseAssets + m[1]); }
                    });
                } catch (e) {
                    console.warn('Asset URL rewrite skipped:', e);
                }
                
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
        // Fetch from preview root to avoid base href side-effects
        fetch(previewRoot + slug)
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

    // If asked for index.html, load the post index fragment instead of nesting the whole page
    const target = (slug === 'index.html') ? (previewRoot + 'post_index.html') : (previewRoot + slug);
    fetch(target)
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

            // Inject into main container only
            contentDiv.innerHTML = content;

            // Re-insert header, footer, left, and right (if necessary)
            // If you want the static layout to be kept, you can preserve these parts
            // with additional logic or predefined structure (here it's assumed 
            // that header/footer/left/right are already statically included).
            
            // You can also replace the other parts (left, right, header, footer) if needed.
            // Keep URL stable at index.html for index view, otherwise reflect the slug
            const newUrl = (slug === 'index.html') ? 'index.html' : slug;
            history.pushState({slug: slug}, "", newUrl);
        })
        .catch(error => {
            console.log("Error loading content:", error); // Log any errors during fetch
        });
}
