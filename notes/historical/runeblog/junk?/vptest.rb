#!/usr/bin/env ruby

$LOAD_PATH << "./lib"
require 'runeblog'
require 'post'


blog = RuneBlog.new    # assumes existing

Dir.chdir ".blogs/posts"

vp = RuneBlog::ViewPost.make(blog: blog, view: :around_austin, nslug: "0003-the-graffiti-wall")
 
puts
puts "vp.view                                     = #{vp.view.inspect}"
puts "vp.view.path                                = #{vp.view.path.inspect}"
puts
puts "vp.view.standard                            = #{vp.view.standard.inspect}"
puts "vp.view.standard(:navbar)                   = #{vp.view.standard(:navbar).inspect}"
puts
puts "vp.repo                                     = #{vp.repo.inspect}"
puts "vp.repo(:drafts)                            = #{vp.repo(:drafts).inspect}"
puts
puts "vp.view.postdir                             = #{vp.view.postdir.inspect}"
puts "vp.view.postdir('teaser.txt')               = #{vp.view.postdir('teaser.txt').inspect}"
puts
puts "vp.view.remote                              = #{vp.view.remote.inspect}"
puts "vp.view.remote(dir: :etc)                   = #{vp.view.remote(dir: :etc).inspect}"
puts "vp.view.remote(file: :fakefile)             = #{vp.view.remote(file: :fakefile).inspect}"
puts "vp.view.remote(dir: :etc, file: 'blog.css') = #{vp.view.remote(dir: :etc, file: 'blog.css').inspect}"



