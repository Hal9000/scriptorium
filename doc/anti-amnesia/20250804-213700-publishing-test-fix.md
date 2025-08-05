# Publishing Test Fix - 2025-08-04 21:37:00

## Problem
Publishing tests in `test/unit/api.rb` were failing because `post.published` timestamp was being overwritten after `publish_post` set it.

## Root Cause
1. `publish_post` correctly set `post.published` timestamp and wrote to metadata file
2. `publish_post` called `generate_post` to generate HTML
3. `generate_post` called `write_generated_post`, which called `write_post_metadata`
4. `write_post_metadata` overwrote metadata file with only `vars` data, losing `post.published` timestamp

## Solution
Modified `write_post_metadata` method in `lib/scriptorium/repo.rb` to preserve existing metadata:

```ruby
private def write_post_metadata(data, view)
  num, title = data.values_at(:"post.id", :"post.title")
  metadata_file = @root/:posts/d4(num)/"meta.txt"
  
  # Read existing metadata to preserve fields like post.published
  existing_metadata = {}
  if File.exist?(metadata_file)
    existing_metadata = getvars(metadata_file)
  end
  
  # Prepare new metadata from data
  new_metadata = data.select {|k,v| k.to_s.start_with?("post.") }
  new_metadata.delete(:"post.body")
  new_metadata[:"post.slug"] = slugify(num, title) + ".html"
  
  # Merge existing metadata over new metadata to preserve important fields
  existing_metadata.each do |key, value|
    new_metadata[key] = value
  end
  
  lines = new_metadata.map { |k, v| sprintf("%-12s  %s", k, v) }
  write_file(metadata_file, lines.join("\n"))
end
```

## Additional Changes
1. Removed `generate: false` parameters from all `create_post` calls in `test/unit/api.rb`
2. Restored `publish_post` return value to return Post object as expected by tests
3. Cleaned up debug output after confirming fix worked

## Results
- All 5 publishing tests now pass: `test_068_publish_post`, `test_069_publish_post_already_published`, `test_071_post_published_status`, `test_072_get_published_posts`, `test_073_get_published_posts_with_view`
- Publishing functionality works correctly, preserving `post.published` timestamp through generation process
- Remaining test failures are unrelated to publishing (view and tag management issues) 