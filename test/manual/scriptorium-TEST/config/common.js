// This is the common JavaScript file for all views.
// It is included in all views.
<script type="text/javascript">
  function load_main(slug) {
    const contentDiv = document.getElementById("main");
    fetch(slug)  // This fetches a local file, such as post_123.html
      .then(response => response.text())
      .then(content => { contentDiv.innerHTML = content; })
      .catch(error => console.log("Error loading content:", error));
  }
</script>

