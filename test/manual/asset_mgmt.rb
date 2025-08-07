#!/usr/bin/env ruby

# Manual test for asset management functionality
# This is a MANUAL test - you need to run it step by step

require_relative "../../lib/scriptorium"
require_relative "../test_helpers"
require "fileutils"
require_relative "./environment"

manual_setup

@repo.create_view("assetview", "Asset Test View", "A test view for asset management")

# Copy test images from dev_assets
FileUtils.cp("dev_assets/global.png", "test/scriptorium-TEST/assets/global-test.png")
FileUtils.cp("dev_assets/view.png", "test/scriptorium-TEST/views/assetview/assets/view-test.png")
FileUtils.mkdir_p("test/scriptorium-TEST/posts/0001/assets")
FileUtils.cp("dev_assets/post.png", "test/scriptorium-TEST/posts/0001/assets/post-test.png")
FileUtils.mkdir_p("test/scriptorium-TEST/assets/library")
FileUtils.cp("dev_assets/library.png", "test/scriptorium-TEST/assets/library/library-test.png")

# Create a post with asset references
draft_body = <<~BODY
  .blurb Testing asset management with real images.
  
  This post tests the asset management system with real PNG files.
  
  Global asset: $$asset[global-test.png]
  
  View asset: $$asset[view-test.png]
  
  Post asset: $$asset[post-test.png]
  
  Library asset: $$asset[library-test.png]
  
  Missing asset: $$asset[nonexistent.png]
  
  And with image tags:
  
  $$image_asset[global-test.png]
  $$image_asset[view-test.png]
  $$image_asset[post-test.png]
  $$image_asset[library-test.png]
  $$image_asset[nonexistent.png]
  
  The assets should be copied to the output directory and display correctly.
BODY

name = @repo.create_draft(title: "Asset Management Test", views: ["assetview"], body: draft_body)
num = @repo.finish_draft(name)
@repo.generate_post(num)

@repo.generate_front_page("assetview")

instruct <<~EOS
  The post should display with:
  - Global image (global-test.png) from assets/
  - View image (view-test.png) from views/assetview/assets/
  - Post image (post-test.png) from posts/0001/assets/
  - Library image (library-test.png) from assets/library/
  - Missing image placeholder for nonexistent.png
  
  Check that images are copied to views/assetview/output/assets/
  and that URLs are generated correctly.
EOS
examine("assetview")
