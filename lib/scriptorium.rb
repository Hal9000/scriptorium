require_relative "skeleton"

require_relative "scriptorium/version"
require_relative "scriptorium/engine"
require_relative "scriptorium/exceptions"


###  

class Scriptorium

  include Exceptions
  extend  Engine

  class << self
    attr_accessor :testing
    attr_reader   :root
  end

  def initialize(root)
    @root = root
    # Read relevant info...
  end
end
