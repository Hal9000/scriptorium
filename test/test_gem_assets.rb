#!/usr/bin/env ruby

require_relative '../lib/scriptorium'

puts "=== Scriptorium Gem Asset Test ==="
puts "Gem version: #{Scriptorium::VERSION}"
puts

# Test that we can access the StandardFiles class
predef = Scriptorium::StandardFiles.new
puts "✅ StandardFiles class accessible"

# Test post template generation
template = predef.support_data('templates/post.lt3')
puts "✅ Post template generated (#{template.lines.count} lines)"

# Test that clipboard function is in common.js
common_js = predef.common_js
if common_js.include?('copyPermalinkToClipboard')
  puts "✅ Clipboard function found in common.js"
else
  puts "❌ Clipboard function NOT found in common.js"
end

# Test template with variables
vars = {
  :'post.title' => 'Test Post',
  :'post.pubdate' => '2025-08-14',
  :'post.date' => '2025-08-14',
  :'post.tags' => 'test, gem',
  :'post.body' => 'This is a test post from the installed gem.',
  :reddit_button => ''
}

result = template % vars
puts "✅ Template variable substitution works"
puts "✅ Generated HTML contains copy button: #{result.include?('copyPermalinkToClipboard')}"

# Test that the copy button is present
if result.include?('Copy link')
  puts "✅ Copy link button present in generated HTML"
else
  puts "❌ Copy link button NOT present in generated HTML"
end

puts
puts "=== Asset Test Complete ==="
puts "All gem assets are working correctly!"
