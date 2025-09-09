// Copy permalink to clipboard functionality
function copyPermalinkToClipboard() {
    // Get the current post slug from the URL or construct it
    const currentUrl = window.location.href;
    let permalinkUrl;
    
    if (currentUrl.includes('?post=')) {
      // We're on the main blog page, construct the permalink URL
      const postSlug = currentUrl.split('?post=')[1];
      const baseUrl = window.location.origin + window.location.pathname.replace(/\\/[^\\/]*$/, '');
      permalinkUrl = baseUrl + '/permalink/' + postSlug;
    } else {
      // We're already on a permalink page, use current URL
      permalinkUrl = currentUrl;
    }
    
    navigator.clipboard.writeText(permalinkUrl).then(function() {
      // Change button text temporarily to show success
      const button = event.target;
      const originalText = button.textContent;
      button.textContent = 'Copied!';
      button.style.background = '#28a745';
      setTimeout(function() {
        button.textContent = originalText;
        button.style.background = '#007bff';
      }, 2000);
    }).catch(function(err) {
      console.error('Failed to copy: ', err);
      alert('Failed to copy link to clipboard');
    });
}
