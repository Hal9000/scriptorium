require_relative "skeleton"

require_relative "scriptorium/engine"
require_relative "scriptorium/exceptions"

require 'singleton'

###  

class Scriptorium

  include Singleton

  include Exceptions
  include Engine

  # Class instance vars...
  @testing = $testing      # good/bad idea? 
  @blog    = nil

  class << self
    attr_accessor :testing
    alias blog instance 
  end

  # Instance attrs/methods

  attr_reader :name, :dir

  def initialize
    @testing = self.class.testing
    @home    = ENV['HOME']
    if @testing
      @name = "TEST-ONLY BLOG REPO"
      @dir  = "#@home/test-scriptorium"
    else
      @name = "Scriptorium repository"
      @dir  = "#@home/Scriptorium"
    end
  end

end
