require 'livetext'
require 'find'
require 'htmlbeautifier'
require 'pp'
require 'digest'

require_relative "skeleton"
require_relative "scriptorium/version"
require_relative "scriptorium/contract"
require_relative "scriptorium/repo"
require_relative "scriptorium/post"
require_relative "scriptorium/theme"
require_relative "scriptorium/view"
require_relative "scriptorium/exceptions"
require_relative "scriptorium/helpers"
require_relative "scriptorium/standard_files"
require_relative "scriptorium/banner_svg"
require_relative "scriptorium/reddit"
require_relative "scriptorium/widgets/widget"
require_relative "scriptorium/widgets/links"
require_relative "scriptorium/widgets/pages"
require_relative "scriptorium/widgets/featured_posts"
require_relative "scriptorium/api"
require_relative "scriptorium/syntax_highlighter"

# Main Scriptorium class that provides backward compatibility
class Scriptorium
  def initialize(testmode: false)
    @api = Scriptorium::API.new(testmode: testmode)
  end
  
  # Delegate all the main operations to the API
  def method_missing(method, *args, **kwargs, &block)
    if @api.respond_to?(method)
      @api.send(method, *args, **kwargs, &block)
    else
      super
    end
  end
  
  def respond_to_missing?(method, include_private = false)
    @api.respond_to?(method) || super
  end
  
  # Keep the API accessible for advanced users
  attr_reader :api
end
