require 'json'
require 'redd'
require_relative 'exceptions'
require_relative 'helpers'

module Scriptorium
  class Reddit
    include Scriptorium::Exceptions
    include Scriptorium::Helpers

    def initialize(repo)
      @repo = repo
      @credentials_file = @repo.root/:config/"reddit_credentials.json"
    end

    # Autopost a post to Reddit
    def autopost(post_data, subreddit = nil)
      need(:file, @credentials_file, "Reddit credentials file not found")
      
      config = self.config
      return false unless config
      
      begin
        # Initialize Reddit session using redd gem
        session = create_reddit_session(config)
        
        # Determine target subreddit
        target_subreddit = subreddit || post_data[:subreddit] || config['default_subreddit']
        raise "No subreddit specified" unless target_subreddit
        
        # Get the subreddit and submit the post
        subreddit_instance = session.subreddit(target_subreddit)
        submission = subreddit_instance.submit(
          post_data[:title],
          url: post_data[:url],
          resubmit: false
        )
        
        log_message("Successfully autoposted to Reddit: #{post_data[:title]} -> r/#{target_subreddit}")
        return true
        
      rescue => e
        log_message("Failed to autopost to Reddit: #{e.message}")
        return false
      end
    end

    # Check if Reddit autoposting is configured
    def configured?
      File.exist?(@credentials_file)
    end

    # Get Reddit configuration
    def config
      return nil unless configured?
      
      begin
        JSON.parse(read_file(@credentials_file))
      rescue => e
        log_message("Failed to parse Reddit credentials: #{e.message}")
        nil
      end
    end

    private

    def create_reddit_session(config)
      Redd.it(
        user_agent: config['user_agent'] || "scriptorium:autopost:v1.0",
        client_id: config['client_id'],
        secret: config['client_secret'],
        username: config['username'],
        password: config['password']
      )
    end

    def log_message(message)
      # Only log if not in test mode
      return if caller.any? { |line| line.include?('test/') }
      puts message
    end
  end
end 