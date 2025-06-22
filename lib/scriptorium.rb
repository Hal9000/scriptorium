require_relative "skeleton"

require 'livetext'

require_relative "scriptorium/version"
require_relative "scriptorium/repo"
require_relative "scriptorium/view"
require_relative "scriptorium/exceptions"
require_relative "scriptorium/helpers"


###  

# module Scriptorium

#   class Repo
#     include Exceptions
# #    extend  Engine
#     include Helpers
# 
#     class << self
#       attr_accessor :testing
#       attr_reader   :root
#     end
# 
#     ### Instance...
# 
#     def view_exist?(name)
#       Dir.exist?("#@root/views/#{name}")
#     end
# 
#     def create_view(name, title, subtitle = "")
#       # FIXME finish
#       raise ViewDirAlreadyExists if view_exist?(name)
#       dir = "#@root/views/#{name}"
#       Dir.mkdir(dir)
#       Dir.chdir(dir) do 
#         File.open("config.txt", "w") do |f|
#           f.puts "title #{title}"
#           f.puts "subtitle #{subtitle}" unless subtitle.empty?
#         end
#       end
#     end
# 
#     def open_view(name)
#       vhash = getvars("#@root/views/#{name}/config.txt")
#       title, subtitle = vhash.values_at("title", "subtitle")
#       Scriptorium::View.new(name, title, subtitle)
#     end
# 
#     def initialize(root)    # repo
#       @root = root
#       # Read relevant info...
#       View.class_eval do
#         @root = root
#         attr_reader :root
#       end
#     end
#   end
# end
