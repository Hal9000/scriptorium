#!/usr/bin/env ruby

# Set up environment
ENV['PATH'] = "#{ENV['HOME']}/.rbenv/shims:#{ENV['PATH']}"

puts "\n" + "="*60
puts "Running all automated tests..."
puts "="*60

# Run unit tests
puts "\n--- Running unit tests ---"
system("ruby test/all")

# Run manual tests in automated mode
puts "\n--- Running manual tests in automated mode ---"

manual_tests = [
  "test/manual/test1.rb",
  "test/manual/test2.rb", 
  "test/manual/test3.rb blog1",
  "test/manual/test4.rb",
  "test/manual/test5.rb",
  "test/manual/test_banner_combinations.rb",
  "test/manual/test_banner_features.rb",
  "test/manual/test_complex_header.rb",
  "test/manual/test_empty_header.rb",
  "test/manual/test_banner_in_header.rb",
  "test/manual/test_radial_custom.rb",
  "test/manual/test_radial_large_radius.rb",
  "test/manual/test_svg_debug.rb"
]

manual_tests.each do |test|
  puts "\nRunning: #{test}"
  result = system("ruby #{test} --automated")
  if result
    puts "✓ PASSED"
  else
    puts "✗ FAILED"
  end
end

puts "\n" + "="*60
puts "All automated tests completed!"
puts "="*60 