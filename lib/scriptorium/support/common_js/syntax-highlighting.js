// Highlight newly loaded content
function highlightNewContent(container) {
    if (typeof hljs !== 'undefined') {
        // Find all code blocks in the new content and highlight them
        const codeBlocks = container.querySelectorAll('pre code[class*="language-"]');
        console.log('Found code blocks:', codeBlocks.length);
        if (codeBlocks.length > 0) {
            // Highlight each code block
            codeBlocks.forEach((codeBlock, index) => {
                console.log(`Highlighting code block ${index}:`, codeBlock);
                try {
                    hljs.highlightElement(codeBlock);
                    console.log(`Successfully highlighted code block ${index}`);
                } catch (error) {
                    console.error(`Error highlighting code block ${index}:`, error);
                }
            });
        }
    } else {
        console.log('hljs is not defined');
    }
}

// Initialize highlight.js syntax highlighting
if (typeof hljs !== 'undefined') {
    hljs.highlightAll();
}
